path = 'lib/data/party_questions.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_q4 = """  PartyQuestion(
    id: 4,
    question: 'What is the farthest place you have been from Potsdam?',
    hint: 'Check My Places -> Per Photo view',
    category: 'photos',
  ),"""
new_q4 = """  PartyQuestion(
    id: 4,
    question: 'What is the farthest place you have been from Potsdam?',
    hint: 'Check My Places -> Per Photo view',
    category: 'photos',
    queryType: 'farthestFromPotsdam',
    targetTimeline: 'My Places',
    targetField: 'city',
  ),"""
if old_q4 not in content:
    print("ERROR: question 4 not found")
else:
    content = content.replace(old_q4, new_q4)
    print("Updated question 4 with farthestFromPotsdam query")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
