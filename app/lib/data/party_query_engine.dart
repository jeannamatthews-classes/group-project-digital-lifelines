import 'dart:math' as math;

import '../database/db_helper.dart';
import 'party_questions.dart';

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Loads every entry in a timeline as a simple map of field-name -> value.
/// Shared by all the query functions below so we only write the
/// timeline/field lookup logic once.
Future<List<Map<String, String>>> _loadRowsByFieldName(
  String timelineName,
) async {
  final dbHelper = DBHelper.instance;

  final timelines = await dbHelper.getTimelines();
  final timeline = timelines
      .where((t) => t.name.toLowerCase() == timelineName.toLowerCase())
      .firstOrNull;
  if (timeline == null || timeline.id == null) return [];

  final fields = await dbHelper.getFields(timeline.id!);
  final fieldNameById = {for (final f in fields) f.id!: f.name.toLowerCase()};

  final entries = await dbHelper.getEntries(timeline.id!);
  final rows = <Map<String, String>>[];
  for (final entry in entries) {
    if (entry.id == null) continue;
    final values = await dbHelper.getValues(entry.id!);
    final row = <String, String>{};
    for (final v in values) {
      final name = fieldNameById[v.fieldId];
      if (name != null) row[name] = v.value;
    }
    rows.add(row);
  }
  return rows;
}

/// Finds the most frequent value stored for a given field across all
/// entries in a timeline (e.g. the city that appears most often).
Future<String?> computeMostFrequentFieldValue({
  required String timelineName,
  required String fieldName,
}) async {
  final rows = await _loadRowsByFieldName(timelineName);
  final counts = <String, int>{};
  for (final row in rows) {
    final value = row[fieldName.toLowerCase()]?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'unknown') {
      continue;
    }
    counts[value] = (counts[value] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first.key;
}

/// Counts how many distinct values exist for a given field
/// (e.g. how many different countries appear across all photos).
Future<int?> computeDistinctFieldValueCount({
  required String timelineName,
  required String fieldName,
}) async {
  final rows = await _loadRowsByFieldName(timelineName);
  final values = <String>{};
  for (final row in rows) {
    final value = row[fieldName.toLowerCase()]?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'unknown') {
      continue;
    }
    values.add(value);
  }
  return values.isEmpty ? null : values.length;
}

/// Finds the most frequent month across a date field
/// (dates are stored as "YYYY-MM-DD"). Returns a readable month name.
Future<String?> computeMostFrequentMonth({
  required String timelineName,
  required String dateFieldName,
}) async {
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  final rows = await _loadRowsByFieldName(timelineName);
  final counts = <int, int>{};
  for (final row in rows) {
    final date = row[dateFieldName.toLowerCase()];
    if (date == null || date.length < 7) continue;
    final month = int.tryParse(date.substring(5, 7));
    if (month == null || month < 1 || month > 12) continue;
    counts[month] = (counts[month] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return monthNames[sorted.first.key - 1];
}

/// Finds the entry with the earliest date and returns the value of
/// another field from that same entry (e.g. the city of your oldest photo).
Future<String?> computeOldestEntryFieldValue({
  required String timelineName,
  required String dateFieldName,
  required String targetField,
}) async {
  final rows = await _loadRowsByFieldName(timelineName);
  Map<String, String>? oldestRow;
  for (final row in rows) {
    final date = row[dateFieldName.toLowerCase()];
    if (date == null || date.isEmpty) continue;
    if (oldestRow == null) {
      oldestRow = row;
      continue;
    }
    final oldestDate = oldestRow[dateFieldName.toLowerCase()] ?? '';
    if (date.compareTo(oldestDate) < 0) {
      oldestRow = row;
    }
  }
  final value = oldestRow?[targetField.toLowerCase()];
  return (value == null || value.isEmpty || value.toLowerCase() == 'unknown')
      ? null
      : value;
}

/// Finds a value for a field that appears in exactly one entry
/// (e.g. a city you've only photographed once).
Future<String?> computeSingleOccurrenceFieldValue({
  required String timelineName,
  required String fieldName,
}) async {
  final rows = await _loadRowsByFieldName(timelineName);
  final counts = <String, int>{};
  for (final row in rows) {
    final value = row[fieldName.toLowerCase()]?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'unknown') {
      continue;
    }
    counts[value] = (counts[value] ?? 0) + 1;
  }
  final singleOnes = counts.entries.where((e) => e.value == 1).toList();
  return singleOnes.isEmpty ? null : singleOnes.first.key;
}

/// Like computeMostFrequentFieldValue, but only considers entries from a
/// specific month, and excludes a specific value from the target field
/// (e.g. "most common city in December photos, excluding New York").
Future<String?> computeMostFrequentFieldValueFiltered({
  required String timelineName,
  required String targetField,
  String dateFieldName = 'date',
  int? filterMonth,
  String? excludeValue,
}) async {
  final rows = await _loadRowsByFieldName(timelineName);
  final counts = <String, int>{};
  for (final row in rows) {
    if (filterMonth != null) {
      final date = row[dateFieldName.toLowerCase()];
      if (date == null || date.length < 7) continue;
      final month = int.tryParse(date.substring(5, 7));
      if (month != filterMonth) continue;
    }
    final value = row[targetField.toLowerCase()]?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'unknown') {
      continue;
    }
    if (excludeValue != null &&
        value.toLowerCase() == excludeValue.toLowerCase()) {
      continue;
    }
    counts[value] = (counts[value] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first.key;
}

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

/// Runs whichever query the given question is tagged with, and returns
/// the computed answer as text ready to show/send. Returns null if the
/// question has no queryType, or if nothing could be computed.
Future<String?> runQueryForQuestion(PartyQuestion question) async {
  final queryType = question.queryType;
  final timeline = question.targetTimeline;
  final field = question.targetField;
  if (queryType == null || timeline == null || field == null) return null;

  switch (queryType) {
    case 'mostFrequentFieldValue':
      return computeMostFrequentFieldValue(
        timelineName: timeline,
        fieldName: field,
      );
    case 'distinctFieldValueCount':
      final count = await computeDistinctFieldValueCount(
        timelineName: timeline,
        fieldName: field,
      );
      return count?.toString();
    case 'mostFrequentMonth':
      return computeMostFrequentMonth(
        timelineName: timeline,
        dateFieldName: field,
      );
    case 'oldestEntryFieldValue':
      return computeOldestEntryFieldValue(
        timelineName: timeline,
        dateFieldName: 'date',
        targetField: field,
      );
    case 'singleOccurrenceFieldValue':
      return computeSingleOccurrenceFieldValue(
        timelineName: timeline,
        fieldName: field,
      );
    case 'mostFrequentFieldValueFiltered':
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
}
