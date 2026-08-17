path = 'lib/screens/home/party_game_welcome_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_class = """class PartyGameWelcomeScreen extends StatelessWidget {
  const PartyGameWelcomeScreen({super.key});"""
new_class = """class PartyGameWelcomeScreen extends StatelessWidget {
  final Set<String> selectedCategories;

  const PartyGameWelcomeScreen({
    super.key,
    this.selectedCategories = const {'photos'},
  });"""
if old_class not in content:
    print("ERROR: class block not found")
else:
    content = content.replace(old_class, new_class)
    print("Added selectedCategories field")

old_button = """                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGamePairCodeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ask & Answer (Both at Once)'),"""
new_button = """                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartyGamePairCodeScreen(
                        selectedCategories: selectedCategories,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ask & Answer (Both at Once)'),"""
if old_button not in content:
    print("ERROR: button block not found")
else:
    content = content.replace(old_button, new_button)
    print("Updated button to pass selectedCategories")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
