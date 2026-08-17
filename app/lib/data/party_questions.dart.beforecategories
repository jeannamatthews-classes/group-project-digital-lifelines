class PartyQuestion {
  final int id;
  final String question;
  final String hint;

  const PartyQuestion({
    required this.id,
    required this.question,
    required this.hint,
  });
}

const List<PartyQuestion> partyQuestions = [
  PartyQuestion(
    id: 1,
    question: 'Outside New York, where were you last December?',
    hint: 'Check My Places -> Per Month view',
  ),
  PartyQuestion(
    id: 2,
    question: 'How many countries have you visited?',
    hint: 'Check My Places -> Places view',
  ),
  PartyQuestion(
    id: 3,
    question: 'What city do you have the most photos in?',
    hint: 'Check My Places -> Places view',
  ),
  PartyQuestion(
    id: 4,
    question: 'What is the farthest place you have been from Potsdam?',
    hint: 'Check My Places -> Per Photo view',
  ),
  PartyQuestion(
    id: 5,
    question: 'What is the location of your oldest photo?',
    hint: 'Check My Places -> Per Year view (oldest year)',
  ),
  PartyQuestion(
    id: 6,
    question: 'Have you taken photos outside the US?',
    hint: 'Check My Places -> Places view',
  ),
  PartyQuestion(
    id: 7,
    question: 'What month did you take the most photos in?',
    hint: 'Check My Places -> Per Month view',
  ),
  PartyQuestion(
    id: 8,
    question: 'Is there a place you visited only once?',
    hint: 'Check My Places -> Places view (look for count of 1)',
  ),
];

PartyQuestion? findPartyQuestionById(int id) {
  for (final q in partyQuestions) {
    if (q.id == id) return q;
  }
  return null;
}
