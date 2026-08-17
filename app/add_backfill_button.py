path = 'lib/screens/home/data_discovery_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_import = "import '../../theme/app_theme.dart';"
new_import = "import '../../theme/app_theme.dart';\nimport '../../database/db_helper.dart';"
if new_import not in content:
    content = content.replace(old_import, new_import)
    print("Added db_helper import")
else:
    print("Import already present")

old_class = """class DataDiscoveryScreen extends StatelessWidget {
  const DataDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {"""
new_class = """class DataDiscoveryScreen extends StatefulWidget {
  const DataDiscoveryScreen({super.key});

  @override
  State<DataDiscoveryScreen> createState() => _DataDiscoveryScreenState();
}

class _DataDiscoveryScreenState extends State<DataDiscoveryScreen> {
  bool _isBackfilling = false;

  Future<void> _runBackfill() async {
    setState(() {
      _isBackfilling = true;
    });
    final count = await DBHelper.instance.backfillPhotoCoordinates();
    if (!mounted) return;
    setState(() {
      _isBackfilling = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backfilled coordinates for $count photos')),
    );
  }

  @override
  Widget build(BuildContext context) {"""
if old_class not in content:
    print("ERROR: class declaration not found")
else:
    content = content.replace(old_class, new_class)
    print("Converted to StatefulWidget with backfill logic")

old_button = """            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {"""
new_button = """            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isBackfilling ? null : _runBackfill,
                icon: _isBackfilling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(_isBackfilling
                    ? 'Backfilling...'
                    : 'Backfill photo coordinates (dev)'),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {"""
if old_button not in content:
    print("ERROR: search box InkWell not found")
else:
    content = content.replace(old_button, new_button)
    print("Added backfill trigger button")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
