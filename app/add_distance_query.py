path = 'lib/data/party_query_engine.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_import = "import '../database/db_helper.dart';\nimport 'party_questions.dart';"
new_import = "import 'dart:math' as math;\n\nimport '../database/db_helper.dart';\nimport 'party_questions.dart';"
if new_import not in content:
    content = content.replace(old_import, new_import)
    print("Added dart:math import")
else:
    print("Import already present")

new_function = '''
/// Approximate coordinates for Potsdam, NY - the fixed reference point
/// for "farthest place" questions.
const double _potsdamNyLat = 44.6698;
const double _potsdamNyLng = -74.9813;

double _haversineDistanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

/// Finds the entry with coordinates farthest from Potsdam, NY, and
/// returns the value of another field from that entry (e.g. its city).
/// Entries without stored coordinates (not yet backfilled) are skipped.
Future<String?> computeFarthestFromPotsdam({
  required String timelineName,
  required String targetField,
}) async {
  final rows = await _loadRowsByFieldName(timelineName);
  Map<String, String>? farthestRow;
  double farthestDistance = -1;

  for (final row in rows) {
    final latStr = row['latitude'];
    final lngStr = row['longitude'];
    if (latStr == null || lngStr == null) continue;
    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);
    if (lat == null || lng == null) continue;

    final distance = _haversineDistanceKm(_potsdamNyLat, _potsdamNyLng, lat, lng);
    if (distance > farthestDistance) {
      farthestDistance = distance;
      farthestRow = row;
    }
  }

  final value = farthestRow?[targetField.toLowerCase()];
  return (value == null || value.isEmpty || value.toLowerCase() == 'unknown')
      ? null
      : value;
}
'''

if 'computeFarthestFromPotsdam' in content:
    print("Distance function already present")
else:
    marker = "/// Runs whichever query the given question is tagged with"
    if marker not in content:
        print("ERROR: dispatch function marker not found")
    else:
        content = content.replace(marker, new_function.strip() + "\n\n" + marker)
        print("Added computeFarthestFromPotsdam function")

old_dispatch_case = """    case 'mostFrequentFieldValueFiltered':
      return computeMostFrequentFieldValueFiltered(
        timelineName: timeline,
        targetField: field,
        filterMonth: question.filterMonth,
        excludeValue: question.excludeValue,
      );
    default:
      return null;
  }
}"""
new_dispatch_case = """    case 'mostFrequentFieldValueFiltered':
      return computeMostFrequentFieldValueFiltered(
        timelineName: timeline,
        targetField: field,
        filterMonth: question.filterMonth,
        excludeValue: question.excludeValue,
      );
    case 'farthestFromPotsdam':
      return computeFarthestFromPotsdam(
        timelineName: timeline,
        targetField: field,
      );
    default:
      return null;
  }
}"""
if old_dispatch_case not in content:
    print("ERROR: dispatch switch block not found")
else:
    content = content.replace(old_dispatch_case, new_dispatch_case)
    print("Added dispatch case for farthestFromPotsdam")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
