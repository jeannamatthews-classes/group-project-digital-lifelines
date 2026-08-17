path = 'lib/data/party_query_engine.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_import = "import '../database/db_helper.dart';"
new_import = "import '../database/db_helper.dart';\nimport 'party_questions.dart';"
if new_import not in content:
    content = content.replace(old_import, new_import)
    print("Added party_questions.dart import")
else:
    print("Import already present")

dispatch_function = '''
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
    default:
      return null;
  }
}
'''

if 'runQueryForQuestion' in content:
    print("Dispatch function already present")
else:
    content = content + dispatch_function
    print("Added runQueryForQuestion dispatch function")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
