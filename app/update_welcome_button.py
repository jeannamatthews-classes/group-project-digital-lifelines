path = 'lib/screens/home/party_game_welcome_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_import = "import 'party_game_category_screen.dart';"
new_import = "import 'party_game_pair_code_screen.dart';"
if old_import in content:
    content = content.replace(old_import, new_import)
    print("Swapped import to pair code screen")
else:
    print("ERROR: import line not found")

old_button = """            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGameCategoryScreen(),
                    ),
                  );
                },
                child: const Text('Choose a category'),
              ),
            ),"""

new_button = """            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGamePairCodeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ask & Answer (Both at Once)'),
              ),
            ),"""

if old_button not in content:
    print("ERROR: button block not found")
else:
    content = content.replace(old_button, new_button)
    print("Updated button to Ask & Answer (Both at Once)")

if content == original:
    print("NOTHING CHANGED - aborting write")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
