path = 'lib/screens/home/party_game_duo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_field = "  final int pairCode;"
new_field = "  final int pairCode;\n  final Set<String> selectedCategories;"
if new_field in content:
    print("Field already added")
elif old_field not in content:
    print("ERROR: pairCode field line not found")
else:
    content = content.replace(old_field, new_field, 1)
    print("Added selectedCategories field")

old_ctor = "  const PartyGameDuoScreen({super.key, required this.pairCode});"
new_ctor = """  const PartyGameDuoScreen({
    super.key,
    required this.pairCode,
    this.selectedCategories = const {'photos'},
  });"""
if old_ctor not in content:
    print("ERROR: constructor line not found")
else:
    content = content.replace(old_ctor, new_ctor)
    print("Updated constructor to accept selectedCategories")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
