path = 'lib/data/party_questions.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_q2 = """  PartyQuestion(
    id: 2,
    question: 'How many countries have you visited?',
    hint: 'Check My Places -> Places view',
    category: 'photos',
  ),"""
new_q2 = """  PartyQuestion(
    id: 2,
    question: 'How many countries have you visited?',
    hint: 'Check My Places -> Places view',
    category: 'photos',
    queryType: 'distinctFieldValueCount',
    targetTimeline: 'My Places',
    targetField: 'country',
  ),"""
if old_q2 not in content:
    print("ERROR: question 2 not found")
else:
    content = content.replace(old_q2, new_q2)
    print("Updated question 2 (how many countries)")

old_q5 = """  PartyQuestion(
    id: 5,
    question: 'What is the location of your oldest photo?',
    hint: 'Check My Places -> Per Year view (oldest year)',
    category: 'photos',
  ),"""
new_q5 = """  PartyQuestion(
    id: 5,
    question: 'What is the location of your oldest photo?',
    hint: 'Check My Places -> Per Year view (oldest year)',
    category: 'photos',
    queryType: 'oldestEntryFieldValue',
    targetTimeline: 'My Places',
    targetField: 'city',
  ),"""
if old_q5 not in content:
    print("ERROR: question 5 not found")
else:
    content = content.replace(old_q5, new_q5)
    print("Updated question 5 (oldest photo location)")

old_q7 = """  PartyQuestion(
    id: 7,
    question: 'What month did you take the most photos in?',
    hint: 'Check My Places -> Per Month view',
    category: 'photos',
  ),"""
new_q7 = """  PartyQuestion(
    id: 7,
    question: 'What month did you take the most photos in?',
    hint: 'Check My Places -> Per Month view',
    category: 'photos',
    queryType: 'mostFrequentMonth',
    targetTimeline: 'My Places',
    targetField: 'date',
  ),"""
if old_q7 not in content:
    print("ERROR: question 7 not found")
else:
    content = content.replace(old_q7, new_q7)
    print("Updated question 7 (most photos month)")

old_q8 = """  PartyQuestion(
    id: 8,
    question: 'Is there a place you visited only once?',
    hint: 'Check My Places -> Places view (look for count of 1)',
    category: 'photos',
  ),"""
new_q8 = """  PartyQuestion(
    id: 8,
    question: 'Is there a place you visited only once?',
    hint: 'Check My Places -> Places view (look for count of 1)',
    category: 'photos',
    queryType: 'singleOccurrenceFieldValue',
    targetTimeline: 'My Places',
    targetField: 'city',
  ),"""
if old_q8 not in content:
    print("ERROR: question 8 not found")
else:
    content = content.replace(old_q8, new_q8)
    print("Updated question 8 (visited only once)")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
