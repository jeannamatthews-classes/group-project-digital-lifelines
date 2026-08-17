path = 'lib/screens/home/party_game_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

# 1. Add import for shared data
if "import '../../data/party_questions.dart';" not in content:
    content = content.replace(
        "import 'party_game_host_screen.dart';",
        "import 'party_game_host_screen.dart';\nimport '../../data/party_questions.dart';"
    )

# 2. Remove the private static question list block entirely
old_list_start = "static const List<_PartyQuestion> _questions = ["
if old_list_start not in content:
    print("ERROR: could not find the private question list start - aborting")
else:
    start_idx = content.index(old_list_start)
    end_marker = "\n];\n"
    end_idx = content.index(end_marker, start_idx) + len(end_marker)
    content = content[:start_idx] + content[end_idx:]
    print("Removed private _questions list")

# 3. Replace references to _questions with partyQuestions
content = content.replace("_questions.length", "partyQuestions.length")
content = content.replace("_questions[index]", "partyQuestions[index]")

# 4. Remove the private _PartyQuestion class definition
old_class = """class _PartyQuestion {
  final int id;
  final String question;
  final String hint;

  const _PartyQuestion({
    required this.id,
    required this.question,
    required this.hint,
  });
}

"""
if old_class in content:
    content = content.replace(old_class, "")
    print("Removed private _PartyQuestion class")
else:
    print("WARNING: could not find private _PartyQuestion class block to remove - check manually")

# 5. Replace type references _PartyQuestion -> PartyQuestion
content = content.replace("_PartyQuestion question;", "PartyQuestion question;")

if content == original:
    print("ERROR: no changes were made")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("Done! party_game_screen.dart now uses shared PartyQuestion data.")
