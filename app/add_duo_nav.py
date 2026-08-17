path = 'lib/screens/home/party_game_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old_import = "import 'party_game_connect_screen.dart';"
new_import = "import 'party_game_connect_screen.dart';\nimport 'party_game_duo_screen.dart';"
if new_import not in content:
    content = content.replace(old_import, new_import)
    print("Added import")

old_button = """          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGameConnectScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bluetooth_rounded),
                label: const Text('Connect with Friend'),
              ),
            ),
          ),"""

new_button = """          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGameConnectScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bluetooth_rounded),
                label: const Text('Connect with Friend'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGameDuoScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ask & Answer (Both at Once)'),
              ),
            ),
          ),"""

if old_button not in content:
    print("ERROR: could not find button block - aborting")
else:
    content = content.replace(old_button, new_button)
    with open(path, 'w') as f:
        f.write(content)
    print("Added Ask & Answer button")
