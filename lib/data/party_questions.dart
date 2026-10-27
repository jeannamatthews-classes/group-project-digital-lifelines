class PartyQuestion {
  final int id;
  final String question;
  final String hint;
  final String category;

  // If set, the app computes the answer automatically from the
  // recipient's own real data instead of asking them to type one in.
  final String? queryType;
  final String? targetTimeline;
  final String? targetField;
  final List<String> timelineAliases;
  final List<String> targetFieldAliases;

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
    this.timelineAliases = const [],
    this.targetFieldAliases = const [],
    this.filterMonth,
    this.excludeValue,
  });
}

const List<PartyQuestion> partyQuestions = [
  // --- Photos category (existing questions, based on your photo timeline) ---
  PartyQuestion(
    id: 1,
    question: 'Outside New York, where were you last December?',
    hint: 'Check My Places -> Per Month view',
    category: 'location',
    queryType: 'mostFrequentFieldValueFiltered',
    targetTimeline: 'My Places',
    targetField: 'city',
    filterMonth: 12,
    excludeValue: 'New York',
  ),
  PartyQuestion(
    id: 2,
    question: 'How many countries have you visited?',
    hint: 'Check My Places -> Places view',
    category: 'location',
    queryType: 'distinctFieldValueCount',
    targetTimeline: 'My Places',
    targetField: 'country',
  ),
  PartyQuestion(
    id: 3,
    question: 'What city do you have the most photos in?',
    hint: 'Check My Places -> Places view',
    category: 'location',
    queryType: 'mostFrequentFieldValue',
    targetTimeline: 'My Places',
    targetField: 'city',
  ),
  PartyQuestion(
    id: 4,
    question: 'What is the farthest place you have been from Potsdam?',
    hint: 'Check My Places -> Per Photo view',
    category: 'location',
    queryType: 'farthestFromPotsdam',
    targetTimeline: 'My Places',
    targetField: 'city',
  ),
  PartyQuestion(
    id: 5,
    question: 'What is the location of your oldest photo?',
    hint: 'Check My Places -> Per Year view (oldest year)',
    category: 'photos',
    queryType: 'oldestEntryFieldValue',
    targetTimeline: 'My Places',
    targetField: 'city',
  ),
  PartyQuestion(
    id: 6,
    question: 'What country do you have the most photos in?',
    hint: 'Check My Places -> Places view',
    category: 'location',
    queryType: 'mostFrequentFieldValue',
    targetTimeline: 'My Places',
    targetField: 'country',
  ),
  PartyQuestion(
    id: 7,
    question: 'What month did you take the most photos in?',
    hint: 'Check My Places -> Per Month view',
    category: 'photos',
    queryType: 'mostFrequentMonth',
    targetTimeline: 'My Places',
    targetField: 'date',
  ),
  PartyQuestion(
    id: 8,
    question: 'Is there a place you visited only once?',
    hint: 'Check My Places -> Places view (look for count of 1)',
    category: 'location',
    queryType: 'singleOccurrenceFieldValue',
    targetTimeline: 'My Places',
    targetField: 'city',
  ),

  // --- Books category ---
  PartyQuestion(
    id: 101,
    question: 'What book did you add most recently?',
    hint: 'Filled from your most recent Books timeline entry',
    category: 'books',
    queryType: 'mostRecentEntryFieldValue',
    targetTimeline: 'Books',
    timelineAliases: ['Goodreads Reviews'],
    targetField: 'title',
    targetFieldAliases: ['book'],
  ),
  PartyQuestion(
    id: 102,
    question: 'How many book entries did you add this year?',
    hint: 'Counts entries added this year in your Books timeline',
    category: 'books',
    queryType: 'entryCountForCurrentYear',
    targetTimeline: 'Books',
    timelineAliases: ['Goodreads Reviews'],
  ),
  PartyQuestion(
    id: 103,
    question: 'Which book appears most often in your Books timeline?',
    hint: 'Filled from the most common book in your Books timeline',
    category: 'books',
    queryType: 'mostFrequentFieldValue',
    targetTimeline: 'Books',
    timelineAliases: ['Goodreads Reviews'],
    targetField: 'title',
    targetFieldAliases: ['book'],
  ),

  // --- Movies category ---
  PartyQuestion(
    id: 201,
    question: 'What movie did you add most recently?',
    hint: 'Filled from your most recent Movies timeline entry',
    category: 'movies',
    queryType: 'mostRecentEntryFieldValue',
    targetTimeline: 'Movies',
    targetField: 'title',
    targetFieldAliases: ['movie', 'film'],
  ),
  PartyQuestion(
    id: 202,
    question: 'What is your most-watched genre?',
    hint: 'Filled from the most common genre in your Movies timeline',
    category: 'movies',
    queryType: 'mostFrequentFieldValue',
    targetTimeline: 'Movies',
    targetField: 'genre',
  ),
  PartyQuestion(
    id: 203,
    question: 'How many movie entries did you add this month?',
    hint: 'Counts entries added this month in your Movies timeline',
    category: 'movies',
    queryType: 'entryCountForCurrentMonth',
    targetTimeline: 'Movies',
  ),

  // --- Music category ---
  PartyQuestion(
    id: 301,
    question: 'Which song appears most often in your Music timeline?',
    hint: 'Filled from the most frequent song in your Music timeline',
    category: 'music',
    queryType: 'mostFrequentFieldValue',
    targetTimeline: 'Music',
    timelineAliases: ['Songs', 'Spotify Streaming History'],
    targetField: 'song',
    targetFieldAliases: ['track', 'track name', 'song title'],
  ),
  PartyQuestion(
    id: 302,
    question: 'Which artist appears most often in your Music timeline?',
    hint: 'Filled from the most frequent artist in your Music timeline',
    category: 'music',
    queryType: 'mostFrequentFieldValue',
    targetTimeline: 'Music',
    timelineAliases: ['Songs', 'Spotify Streaming History'],
    targetField: 'artist',
  ),
  PartyQuestion(
    id: 303,
    question: 'What song did you add most recently?',
    hint: 'Filled from your most recent Music timeline entry',
    category: 'music',
    queryType: 'mostRecentEntryFieldValue',
    targetTimeline: 'Music',
    timelineAliases: ['Songs', 'Spotify Streaming History'],
    targetField: 'song',
    targetFieldAliases: ['track', 'track name', 'song title'],
  ),

  // --- Restaurants category ---
  PartyQuestion(
    id: 401,
    question: 'Which restaurant have you visited most often?',
    hint: 'Filled from the most frequent restaurant in your timeline',
    category: 'restaurants',
    queryType: 'mostFrequentFieldValue',
    targetTimeline: 'Restaurants',
    timelineAliases: ['Restaurant Visits'],
    targetField: 'restaurant',
    targetFieldAliases: ['name', 'place', 'restaurant name', 'venue'],
  ),
  PartyQuestion(
    id: 402,
    question: 'How many different restaurants have you visited?',
    hint: 'Counts the distinct restaurants in your timeline',
    category: 'restaurants',
    queryType: 'distinctFieldValueCount',
    targetTimeline: 'Restaurants',
    timelineAliases: ['Restaurant Visits'],
    targetField: 'restaurant',
    targetFieldAliases: ['name', 'place', 'restaurant name', 'venue'],
  ),
  PartyQuestion(
    id: 403,
    question: 'Which restaurant did you visit most recently?',
    hint: 'Filled from your most recent Restaurants timeline entry',
    category: 'restaurants',
    queryType: 'mostRecentEntryFieldValue',
    targetTimeline: 'Restaurants',
    timelineAliases: ['Restaurant Visits'],
    targetField: 'restaurant',
    targetFieldAliases: ['name', 'place', 'restaurant name', 'venue'],
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
  return partyQuestions.where((q) => categories.contains(q.category)).toList();
}
