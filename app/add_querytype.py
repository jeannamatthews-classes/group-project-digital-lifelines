path = 'lib/data/party_questions.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_class = """class PartyQuestion {
  final int id;
  final String question;
  final String hint;
  final String category; // 'photos', 'books', or 'movies'

  const PartyQuestion({
    required this.id,
    required this.question,
    required this.hint,
    required this.category,
  });
}"""
new_class = """class PartyQuestion {
  final int id;
  final String question;
  final String hint;
  final String category; // 'photos', 'books', or 'movies'

  // If set, the app computes the answer automatically from the
  // recipient's own real data instead of asking them to type one in.
  final String? queryType;
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
  });
}"""
if old_class not in content:
    print("ERROR: class block not found")
else:
    content = content.replace(old_class, new_class)
    print("Added queryType/targetTimeline/targetField fields")

old_city_q = """  PartyQuestion(
    id: 3,
    question: 'What city do you have the most photos in?',
    hint: 'Check My Places -> Places view',
    category: 'photos',
  ),"""
new_city_q = """  PartyQuestion(
    id: 3,
    question: 'What city do you have the most photos in?',
    hint: 'Check My Places -> Places view',
    category: 'photos',
    queryType: 'mostFrequentFieldValue',
    targetTimeline: 'My Places',
    targetField: 'city',
  ),"""
if old_city_q not in content:
    print("ERROR: city question not found")
else:
    content = content.replace(old_city_q, new_city_q)
    print("Added queryType to city question")

old_country_q = """  PartyQuestion(
    id: 6,
    question: 'Have you taken photos outside the US?',
    hint: 'Check My Places -> Places view',
    category: 'photos',
  ),"""
new_country_q = """  PartyQuestion(
    id: 6,
    question: 'What country do you have the most photos in?',
    hint: 'Check My Places -> Places view',
    category: 'photos',
    queryType: 'mostFrequentFieldValue',
    targetTimeline: 'My Places',
    targetField: 'country',
  ),"""
if old_country_q not in content:
    print("ERROR: country question (id 6) not found")
else:
    content = content.replace(old_country_q, new_country_q)
    print("Updated question 6 to country query")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
