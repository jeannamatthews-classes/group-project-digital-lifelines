path = 'lib/data/party_questions.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

new_file = """class PartyQuestion {
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
}

const List<PartyQuestion> partyQuestions = [
  // --- Photos category (existing questions, based on your photo timeline) ---
  PartyQuestion(
    id: 1,
    question: 'Outside New York, where were you last December?',
    hint: 'Check My Places -> Per Month view',
    category: 'photos',
  ),
  PartyQuestion(
    id: 2,
    question: 'How many countries have you visited?',
    hint: 'Check My Places -> Places view',
    category: 'photos',
  ),
  PartyQuestion(
    id: 3,
    question: 'What city do you have the most photos in?',
    hint: 'Check My Places -> Places view',
    category: 'photos',
  ),
  PartyQuestion(
    id: 4,
    question: 'What is the farthest place you have been from Potsdam?',
    hint: 'Check My Places -> Per Photo view',
    category: 'photos',
  ),
  PartyQuestion(
    id: 5,
    question: 'What is the location of your oldest photo?',
    hint: 'Check My Places -> Per Year view (oldest year)',
    category: 'photos',
  ),
  PartyQuestion(
    id: 6,
    question: 'Have you taken photos outside the US?',
    hint: 'Check My Places -> Places view',
    category: 'photos',
  ),
  PartyQuestion(
    id: 7,
    question: 'What month did you take the most photos in?',
    hint: 'Check My Places -> Per Month view',
    category: 'photos',
  ),
  PartyQuestion(
    id: 8,
    question: 'Is there a place you visited only once?',
    hint: 'Check My Places -> Places view (look for count of 1)',
    category: 'photos',
  ),

  // --- Books category (placeholder questions for now) ---
  PartyQuestion(
    id: 101,
    question: 'What is the last book you finished reading?',
    hint: 'Check your Books timeline for the most recent entry',
    category: 'books',
  ),
  PartyQuestion(
    id: 102,
    question: 'How many books have you read this year?',
    hint: 'Check your Books timeline entry count',
    category: 'books',
  ),
  PartyQuestion(
    id: 103,
    question: 'What genre do you read the most?',
    hint: 'Check your Books timeline for common genres',
    category: 'books',
  ),

  // --- Movies category (placeholder questions for now) ---
  PartyQuestion(
    id: 201,
    question: 'What is the last movie you watched?',
    hint: 'Check your Movies timeline for the most recent entry',
    category: 'movies',
  ),
  PartyQuestion(
    id: 202,
    question: 'What is your most-watched genre?',
    hint: 'Check your Movies timeline for common genres',
    category: 'movies',
  ),
  PartyQuestion(
    id: 203,
    question: 'How many movies have you watched this month?',
    hint: 'Check your Movies timeline entry count',
    category: 'movies',
  ),
];

PartyQuestion? findPartyQuestionById(int id) {
  for (final q in partyQuestions) {
    if (q.id == id) return q;
  }
  return null;
}

/// Returns the merged/union set of questions matching any of the given
/// categories. Picking multiple categories shows the combined pool.
List<PartyQuestion> findQuestionsByCategories(Set<String> categories) {
  if (categories.isEmpty) return [];
  return partyQuestions
      .where((q) => categories.contains(q.category))
      .toList();
}
"""

if content == new_file:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(new_file)
    print("File saved with category field and filtering helper added.")
