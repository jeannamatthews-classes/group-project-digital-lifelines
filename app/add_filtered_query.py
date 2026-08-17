# ---- 1. Extend PartyQuestion model with filterMonth + excludeValue ----
path1 = 'lib/data/party_questions.dart'
with open(path1, 'r') as f:
    c1 = f.read()
orig1 = c1

old_class = """  final String? queryType;
  final String? targetTimeline;
  final String? targetField;

  const PartyQuestion({
    required this.id,
    required this.question,
    required this.hint,
    required this.category,
    this.queryType,
    this.targetTimeline,
    this.targetField,
  });"""
new_class = """  final String? queryType;
  final String? targetTimeline;
  final String? targetField;

  // Optional extra filters for query types that need them, e.g.
  // "December photos, excluding New York".
  final int? filterMonth;
  final String? excludeValue;

  const PartyQuestion({
    required this.id,
    required this.question,
    required this.hint,
    required this.category,
    this.queryType,
    this.targetTimeline,
    this.targetField,
    this.filterMonth,
    this.excludeValue,
  });"""
if old_class not in c1:
    print("ERROR: PartyQuestion class not found")
else:
    c1 = c1.replace(old_class, new_class)
    print("Added filterMonth/excludeValue to PartyQuestion model")

old_q1 = """  PartyQuestion(
    id: 1,
    question: 'Outside New York, where were you last December?',
    hint: 'Check My Places -> Per Month view',
    category: 'photos',
  ),"""
new_q1 = """  PartyQuestion(
    id: 1,
    question: 'Outside New York, where were you last December?',
    hint: 'Check My Places -> Per Month view',
    category: 'photos',
    queryType: 'mostFrequentFieldValueFiltered',
    targetTimeline: 'My Places',
    targetField: 'city',
    filterMonth: 12,
    excludeValue: 'New York',
  ),"""
if old_q1 not in c1:
    print("ERROR: question 1 not found")
else:
    c1 = c1.replace(old_q1, new_q1)
    print("Updated question 1 with December/exclude-NY filter")

if c1 != orig1:
    with open(path1, 'w') as f:
        f.write(c1)

# ---- 2. Add the filtered query function + dispatch case ----
path2 = 'lib/data/party_query_engine.dart'
with open(path2, 'r') as f:
    c2 = f.read()
orig2 = c2

new_function = '''
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
'''

if 'computeMostFrequentFieldValueFiltered' in c2:
    print("Filtered query function already present")
else:
    marker = "/// Runs whichever query the given question is tagged with"
    if marker not in c2:
        print("ERROR: dispatch function marker not found")
    else:
        c2 = c2.replace(marker, new_function.strip() + "\n\n" + marker)
        print("Added computeMostFrequentFieldValueFiltered function")

old_dispatch_case = """    case 'singleOccurrenceFieldValue':
      return computeSingleOccurrenceFieldValue(
        timelineName: timeline,
        fieldName: field,
      );
    default:
      return null;
  }
}"""
new_dispatch_case = """    case 'singleOccurrenceFieldValue':
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
    default:
      return null;
  }
}"""
if old_dispatch_case not in c2:
    print("ERROR: dispatch switch block not found")
else:
    c2 = c2.replace(old_dispatch_case, new_dispatch_case)
    print("Added dispatch case for filtered query")

if c2 != orig2:
    with open(path2, 'w') as f:
        f.write(c2)

print("Done.")
