path = 'lib/screens/home/data_discovery_consent_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

if "import 'party_game_welcome_screen.dart';" not in content:
    content = content.replace(
        "import '../../theme/app_theme.dart';",
        "import '../../theme/app_theme.dart';\nimport 'party_game_welcome_screen.dart';"
    )
    print("Added import")
else:
    print("Import already present")

old_card = """            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose which data sources you consent to share',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),"""

new_card = """            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Here is the list of timelines',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.appBarText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose which data sources you consent to share',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),"""

if old_card not in content:
    print("ERROR: header card block not found - aborting card update")
else:
    content = content.replace(old_card, new_card)
    print("Updated header card with title")

old_categories = """  final Map<String, bool> _categories = {
    'Books': false,
    'Songs': false,
    'Travels': false,
    'Location': false,
  };"""
new_categories = """  final Map<String, bool> _categories = {
    'Books': false,
    'Photos': false,
    'Movies': false,
    'Location': false,
  };"""
if old_categories not in content:
    print("ERROR: categories map not found")
else:
    content = content.replace(old_categories, new_categories)
    print("Renamed categories to Books, Photos, Movies, Location")

old_submit = """  void _submit() {
    final chosen = _categories.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Consented to share: ${chosen.join(", ")}')),
    );
  }"""
new_submit = """  void _submit() {
    final chosen = _categories.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PartyGameWelcomeScreen(),
      ),
    );
  }"""
if old_submit not in content:
    print("ERROR: _submit method not found")
else:
    content = content.replace(old_submit, new_submit)
    print("Updated Submit to navigate to Party Game welcome screen")

old_party_button = """            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGameWelcomeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.celebration_rounded),
                label: const Text('Party Game'),
              ),
            ),"""
if old_party_button in content:
    content = content.replace(old_party_button, "")
    print("Removed redundant separate Party Game button")
else:
    print("Separate Party Game button block not found (may already be removed)")

if content == original:
    print("NOTHING CHANGED - aborting write")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
