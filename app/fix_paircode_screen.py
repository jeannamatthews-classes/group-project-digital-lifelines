path = 'lib/screens/home/party_game_pair_code_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_class = """class PartyGamePairCodeScreen extends StatefulWidget {
  const PartyGamePairCodeScreen({super.key});

  @override
  State<PartyGamePairCodeScreen> createState() =>
      _PartyGamePairCodeScreenState();
}"""
new_class = """class PartyGamePairCodeScreen extends StatefulWidget {
  final Set<String> selectedCategories;

  const PartyGamePairCodeScreen({
    super.key,
    this.selectedCategories = const {'photos'},
  });

  @override
  State<PartyGamePairCodeScreen> createState() =>
      _PartyGamePairCodeScreenState();
}"""
if old_class not in content:
    print("ERROR: class block not found")
else:
    content = content.replace(old_class, new_class)
    print("Added selectedCategories field")

old_continue = """    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartyGameDuoScreen(pairCode: code),
      ),
    );
  }"""
new_continue = """    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartyGameDuoScreen(
          pairCode: code,
          selectedCategories: widget.selectedCategories,
        ),
      ),
    );
  }"""
if old_continue not in content:
    print("ERROR: _continue method navigation block not found")
else:
    content = content.replace(old_continue, new_continue)
    print("Updated _continue to pass selectedCategories through")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
