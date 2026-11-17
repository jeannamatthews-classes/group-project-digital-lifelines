typedef _CsvRow = Map<String, String>;

bool isHiddenImportField(String timelineName, String fieldName) {
  final normalizedTimeline = timelineName.trim().toLowerCase();
  final normalizedField = fieldName.trim().toLowerCase();
  if (normalizedField == 'import_id' || normalizedField == 'uber_id') {
    return true;
  }

  if (normalizedTimeline == 'places') {
    return const {
      'pickup',
      'ride_type',
      'distance_miles',
      'duration_minutes',
      'fare',
      'currency',
      'status',
    }.contains(normalizedField);
  }
  if (normalizedTimeline == 'favorite restaurants') {
    return const {
      'order_total',
      'currency',
      'order_status',
    }.contains(normalizedField);
  }
  return false;
}

Map<String, dynamic> parseUberCsv(String csvText) {
  final records = _parseCsvRecords(csvText, provider: 'Uber');
  final headers = records.first.keys.toSet();

  if (headers.containsAll({'order_uuid', 'restaurant_name', 'item_name'})) {
    return _parseUberEats(records);
  }
  if (headers.contains('request_timestamp_local') &&
      headers.contains('destination_string')) {
    return _parseUberRides(records);
  }
  throw const FormatException(
    'Unrecognized Uber CSV. Choose an Eats order details or Rider lifetime trips file.',
  );
}

Map<String, dynamic> parseDoorDashCsv(String csvText) {
  final records = _parseCsvRecords(csvText, provider: 'DoorDash');
  final headers = records.first.keys.toSet();
  if (!headers.containsAll({'item', 'store_name', 'created_at'})) {
    throw const FormatException(
      'Unrecognized DoorDash CSV. Choose a consumer_order_details file.',
    );
  }

  final orders = <String, _DoorDashOrder>{};
  for (final row in records) {
    final store = row['store_name']?.trim() ?? '';
    final createdAt = row['created_at']?.trim() ?? '';
    final item = row['item']?.trim() ?? '';
    final quantity = int.tryParse(row['quantity']?.trim() ?? '') ?? 1;
    if (store.isEmpty || createdAt.isEmpty || item.isEmpty || quantity <= 0) {
      continue;
    }

    final deliveryTime = row['delivery_time']?.trim() ?? '';
    final key = '$createdAt|$deliveryTime|$store';
    final order = orders.putIfAbsent(
      key,
      () => _DoorDashOrder(
        id: 'doordash:$key',
        store: store,
        createdAt: createdAt,
        rating: _firstNonEmpty([row['restaurant_rating'], row['rating']]),
      ),
    );
    order.items.update(
      item,
      (current) => current + quantity,
      ifAbsent: () => quantity,
    );
  }

  if (orders.isEmpty) {
    throw const FormatException('No DoorDash order items were found.');
  }

  return _importPayload(
    type: 'doordash_orders_import',
    timelineName: 'Favorite Restaurants',
    fields: const [
      {'name': 'Name', 'type': 'text'},
      {'name': 'Address', 'type': 'text'},
      {'name': 'Rating', 'type': 'number'},
      {'name': 'Best Meal', 'type': 'text'},
      {'name': 'Import_ID', 'type': 'text'},
    ],
    entries: orders.values.map((order) {
      return {
        'created_at': _parseTimestamp(order.createdAt),
        'is_favorite': false,
        'values': {
          'Name': order.store,
          'Address': '',
          'Rating': order.rating,
          'Best Meal': order.items.entries
              .map(
                (item) =>
                    item.value > 1 ? '${item.key} x${item.value}' : item.key,
              )
              .join('\n'),
          'Import_ID': order.id,
        },
      };
    }).toList(),
  );
}

List<_CsvRow> _parseCsvRecords(String csvText, {required String provider}) {
  final rows = _parseCsvRows(csvText);
  if (rows.length < 2) {
    throw FormatException('$provider CSV must include a header and data rows.');
  }

  final headers = rows.first
      .map((header) => header.trim().toLowerCase())
      .toList();
  return rows.skip(1).map((row) {
    final record = <String, String>{};
    for (var index = 0; index < headers.length; index++) {
      record[headers[index]] = index < row.length ? row[index].trim() : '';
    }
    return record;
  }).toList();
}

Map<String, dynamic> _parseUberEats(List<_CsvRow> rows) {
  final orders = <String, _UberOrder>{};
  for (final row in rows) {
    if (row['order_status']?.toLowerCase() != 'completed') continue;

    final restaurant = row['restaurant_name']?.trim() ?? '';
    final requestTime = row['request_time_local']?.trim() ?? '';
    final orderId = row['order_uuid']?.trim() ?? '';
    if (restaurant.isEmpty || requestTime.isEmpty) continue;

    final key = orderId.isNotEmpty ? orderId : '$requestTime|$restaurant';
    final order = orders.putIfAbsent(
      key,
      () => _UberOrder(
        id: 'uber:eats:$key',
        restaurant: _restaurantName(restaurant),
        address: _restaurantAddress(restaurant),
        requestTime: requestTime,
        rating: _firstNonEmpty([row['restaurant_rating'], row['rating']]),
      ),
    );
    final itemName = row['item_name']?.trim() ?? '';
    if (itemName.isNotEmpty) order.items.add(itemName);
  }

  if (orders.isEmpty) {
    throw const FormatException('No completed Uber Eats orders were found.');
  }

  return _importPayload(
    type: 'uber_eats_import',
    timelineName: 'Favorite Restaurants',
    fields: const [
      {'name': 'Name', 'type': 'text'},
      {'name': 'Address', 'type': 'text'},
      {'name': 'Rating', 'type': 'number'},
      {'name': 'Best Meal', 'type': 'text'},
      {'name': 'Import_ID', 'type': 'text'},
    ],
    entries: orders.values.map((order) {
      return {
        'created_at': _parseTimestamp(order.requestTime),
        'is_favorite': false,
        'values': {
          'Name': order.restaurant,
          'Address': order.address,
          'Rating': order.rating,
          'Best Meal': order.items.join('\n'),
          'Import_ID': order.id,
        },
      };
    }).toList(),
  );
}

Map<String, dynamic> _parseUberRides(List<_CsvRow> rows) {
  final entries = <Map<String, dynamic>>[];
  for (final row in rows) {
    final status = row['status']?.trim() ?? '';
    final completed = row['is_completed']?.trim().toLowerCase() == 'true';
    if (status.toLowerCase() != 'completed' && !completed) continue;

    final requestTime =
        row['request_timestamp_local']?.trim().isNotEmpty == true
        ? row['request_timestamp_local']!.trim()
        : row['request_timestamp_utc']?.trim() ?? '';
    if (requestTime.isEmpty) continue;

    final rideId = [
      'uber:ride',
      requestTime,
      row['begintrip_lat']?.trim() ?? '',
      row['begintrip_lng']?.trim() ?? '',
      row['destination_string']?.trim() ?? '',
    ].join('|');
    final latitude = _firstNonEmpty([
      row['dropoff_lat'],
      row['destination_lat'],
      row['begintrip_lat'],
      row['request_lat'],
    ]);
    final longitude = _firstNonEmpty([
      row['dropoff_lng'],
      row['destination_lng'],
      row['begintrip_lng'],
      row['request_lng'],
    ]);
    final rawDestination = row['destination_string']?.trim() ?? '';
    final sourceCountry = _firstNonEmpty([
      row['country_name'],
      row['country'],
      row['country_code'],
    ]);
    final sourceState = _firstNonEmpty([
      row['state_name'],
      row['state'],
      row['region'],
      row['province'],
    ]);
    final destinationLocation = _parseDestinationLocation(
      rawDestination,
      countryHint: sourceCountry,
    );
    final country = destinationLocation.country.isNotEmpty
        ? destinationLocation.country
        : _fullCountryName(sourceCountry) ?? sourceCountry;
    final state = destinationLocation.state.isNotEmpty
        ? destinationLocation.state
        : _fullStateName(sourceState) ?? sourceState;

    entries.add({
      'created_at': _parseTimestamp(requestTime),
      'is_favorite': false,
      'values': {
        'Date': _dateOnly(requestTime),
        'Country': country,
        'State': state,
        'City': row['city_name']?.trim() ?? '',
        'Latitude': latitude,
        'Longitude': longitude,
        'Destination': destinationLocation.destination,
        'Import_ID': rideId,
      },
    });
  }

  if (entries.isEmpty) {
    throw const FormatException('No completed Uber rides were found.');
  }

  return _importPayload(
    type: 'uber_rides_import',
    timelineName: 'Places',
    fields: const [
      {'name': 'Date', 'type': 'text'},
      {'name': 'Country', 'type': 'text'},
      {'name': 'State', 'type': 'text'},
      {'name': 'City', 'type': 'text'},
      {'name': 'Latitude', 'type': 'text'},
      {'name': 'Longitude', 'type': 'text'},
      {'name': 'Destination', 'type': 'text'},
      {'name': 'Import_ID', 'type': 'text'},
    ],
    entries: entries,
  );
}

Map<String, dynamic> _importPayload({
  required String type,
  required String timelineName,
  required List<Map<String, dynamic>> fields,
  required List<Map<String, dynamic>> entries,
}) {
  return {
    'schema_version': 1,
    'app': 'Digital Lifelines',
    'type': type,
    'timelines': [
      {'name': timelineName, 'fields': fields, 'entries': entries},
    ],
  };
}

String _restaurantName(String value) {
  final match = RegExp(r'^(.*?)\s+\((.*)\)$').firstMatch(value);
  return (match?.group(1) ?? value).trim();
}

String _restaurantAddress(String value) {
  final match = RegExp(r'^(.*?)\s+\((.*)\)$').firstMatch(value);
  return match?.group(2)?.trim() ?? '';
}

String _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

_DestinationLocation _parseDestinationLocation(
  String destination, {
  String countryHint = '',
}) {
  final parts = destination.split(',').map((part) => part.trim()).toList();
  while (parts.isNotEmpty && parts.last.isEmpty) {
    parts.removeLast();
  }

  var country = '';
  var state = '';
  if (parts.isNotEmpty) {
    final previous = parts.length > 1 ? parts[parts.length - 2] : '';
    final parsedCountry = _countryFromDestinationSuffix(
      parts.last,
      previous: previous,
      countryHint: countryHint,
    );
    if (parsedCountry != null) {
      country = parsedCountry;
      parts.removeLast();
    }
  }
  if (parts.isNotEmpty) {
    final parsedState = _fullStateName(parts.last);
    if (parsedState != null) {
      state = parsedState;
      parts.removeLast();
    }
  }

  return _DestinationLocation(
    destination: parts.join(', '),
    state: state,
    country: country,
  );
}

String? _countryFromDestinationSuffix(
  String value, {
  required String previous,
  required String countryHint,
}) {
  final code = value.trim().toUpperCase();
  final country = _countryNames[code];
  if (country == null) return null;

  if (_usStateNames.containsKey(code)) {
    final previousIsRegion = _fullStateName(previous) != null;
    final hintMatches = _fullCountryName(countryHint) == country;
    if (!previousIsRegion && !hintMatches) return null;
  }
  return country;
}

String? _fullStateName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return null;
  final upper = normalized.toUpperCase();
  final codeMatch = _usStateNames[upper] ?? _canadianProvinceNames[upper];
  if (codeMatch != null) return codeMatch;

  for (final name in [
    ..._usStateNames.values,
    ..._canadianProvinceNames.values,
  ]) {
    if (name.toLowerCase() == normalized.toLowerCase()) return name;
  }
  return null;
}

String? _fullCountryName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return null;
  return _countryNames[normalized.toUpperCase()] ??
      _countryNames[normalized.toLowerCase()];
}

const _usStateNames = <String, String>{
  'AL': 'Alabama',
  'AK': 'Alaska',
  'AZ': 'Arizona',
  'AR': 'Arkansas',
  'CA': 'California',
  'CO': 'Colorado',
  'CT': 'Connecticut',
  'DE': 'Delaware',
  'FL': 'Florida',
  'GA': 'Georgia',
  'HI': 'Hawaii',
  'ID': 'Idaho',
  'IL': 'Illinois',
  'IN': 'Indiana',
  'IA': 'Iowa',
  'KS': 'Kansas',
  'KY': 'Kentucky',
  'LA': 'Louisiana',
  'ME': 'Maine',
  'MD': 'Maryland',
  'MA': 'Massachusetts',
  'MI': 'Michigan',
  'MN': 'Minnesota',
  'MS': 'Mississippi',
  'MO': 'Missouri',
  'MT': 'Montana',
  'NE': 'Nebraska',
  'NV': 'Nevada',
  'NH': 'New Hampshire',
  'NJ': 'New Jersey',
  'NM': 'New Mexico',
  'NY': 'New York',
  'NC': 'North Carolina',
  'ND': 'North Dakota',
  'OH': 'Ohio',
  'OK': 'Oklahoma',
  'OR': 'Oregon',
  'PA': 'Pennsylvania',
  'RI': 'Rhode Island',
  'SC': 'South Carolina',
  'SD': 'South Dakota',
  'TN': 'Tennessee',
  'TX': 'Texas',
  'UT': 'Utah',
  'VT': 'Vermont',
  'VA': 'Virginia',
  'WA': 'Washington',
  'WV': 'West Virginia',
  'WI': 'Wisconsin',
  'WY': 'Wyoming',
  'DC': 'District of Columbia',
};

const _canadianProvinceNames = <String, String>{
  'AB': 'Alberta',
  'BC': 'British Columbia',
  'MB': 'Manitoba',
  'NB': 'New Brunswick',
  'NL': 'Newfoundland and Labrador',
  'NS': 'Nova Scotia',
  'NT': 'Northwest Territories',
  'NU': 'Nunavut',
  'ON': 'Ontario',
  'PE': 'Prince Edward Island',
  'QC': 'Quebec',
  'SK': 'Saskatchewan',
  'YT': 'Yukon',
};

const _countryNames = <String, String>{
  'US': 'United States',
  'USA': 'United States',
  'UNITED STATES': 'United States',
  'UNITED STATES OF AMERICA': 'United States',
  'CA': 'Canada',
  'CAN': 'Canada',
  'CANADA': 'Canada',
  'GB': 'United Kingdom',
  'GBR': 'United Kingdom',
  'UK': 'United Kingdom',
  'UNITED KINGDOM': 'United Kingdom',
  'AU': 'Australia',
  'AUS': 'Australia',
  'AUSTRALIA': 'Australia',
  'NZ': 'New Zealand',
  'NZL': 'New Zealand',
  'NEW ZEALAND': 'New Zealand',
  'MX': 'Mexico',
  'MEX': 'Mexico',
  'MEXICO': 'Mexico',
  'IN': 'India',
  'IND': 'India',
  'INDIA': 'India',
  'DE': 'Germany',
  'DEU': 'Germany',
  'GERMANY': 'Germany',
  'FR': 'France',
  'FRA': 'France',
  'FRANCE': 'France',
  'JP': 'Japan',
  'JPN': 'Japan',
  'JAPAN': 'Japan',
  'CN': 'China',
  'CHN': 'China',
  'CHINA': 'China',
  'BR': 'Brazil',
  'BRA': 'Brazil',
  'BRAZIL': 'Brazil',
  'IE': 'Ireland',
  'IRL': 'Ireland',
  'IRELAND': 'Ireland',
  'ES': 'Spain',
  'ESP': 'Spain',
  'SPAIN': 'Spain',
  'IT': 'Italy',
  'ITA': 'Italy',
  'ITALY': 'Italy',
  'NL': 'Netherlands',
  'NLD': 'Netherlands',
  'NETHERLANDS': 'Netherlands',
  'SE': 'Sweden',
  'SWE': 'Sweden',
  'SWEDEN': 'Sweden',
  'CH': 'Switzerland',
  'CHE': 'Switzerland',
  'SWITZERLAND': 'Switzerland',
};

String _dateOnly(String timestamp) {
  final date = timestamp.split(RegExp(r'[T ]')).first;
  return date;
}

int _parseTimestamp(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw const FormatException('Invalid timestamp in delivery history CSV.');
  }
  return parsed.millisecondsSinceEpoch;
}

List<List<String>> _parseCsvRows(String input) {
  final text = input.startsWith('\uFEFF') ? input.substring(1) : input;
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  for (var index = 0; index < text.length; index++) {
    final char = text[index];
    if (inQuotes) {
      if (char == '"') {
        if (index + 1 < text.length && text[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }

    if (char == '"' && field.isEmpty) {
      inQuotes = true;
    } else if (char == ',') {
      row.add(field.toString());
      field.clear();
    } else if (char == '\n' || char == '\r') {
      if (char == '\r' && index + 1 < text.length && text[index + 1] == '\n') {
        index++;
      }
      row.add(field.toString());
      field.clear();
      if (row.any((value) => value.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(char);
    }
  }

  if (inQuotes) {
    throw const FormatException(
      'Uber CSV contains an unterminated quoted field.',
    );
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    if (row.any((value) => value.isNotEmpty)) rows.add(row);
  }
  return rows;
}

class _UberOrder {
  final String id;
  final String restaurant;
  final String address;
  final String requestTime;
  final String rating;
  final Set<String> items = {};

  _UberOrder({
    required this.id,
    required this.restaurant,
    required this.address,
    required this.requestTime,
    required this.rating,
  });
}

class _DoorDashOrder {
  final String id;
  final String store;
  final String createdAt;
  final String rating;
  final Map<String, int> items = {};

  _DoorDashOrder({
    required this.id,
    required this.store,
    required this.createdAt,
    required this.rating,
  });
}

class _DestinationLocation {
  final String destination;
  final String state;
  final String country;

  const _DestinationLocation({
    required this.destination,
    required this.state,
    required this.country,
  });
}
