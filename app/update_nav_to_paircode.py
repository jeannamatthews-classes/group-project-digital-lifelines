path = 'lib/screens/home/party_game_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_import = "import 'party_game_duo_screen.dart';"
new_import = "import 'party_game_pair_code_screen.dart';"
if old_import in content and new_import not in content:
    content = content.replace(old_import, new_import)
    print("Swapped import to pair code screen")

old_nav = """                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGameDuoScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ask & Answer (Both at Once)'),"""
new_nav = """                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGamePairCodeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ask & Answer (Both at Once)'),"""
if old_nav not in content:
    print("ERROR: navigation block not found")
else:
    content = content.replace(old_nav, new_nav)
    print("Updated navigation to go through pair code screen first")

if content == original:
    print("NOTHING CHANGED - aborting write")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
