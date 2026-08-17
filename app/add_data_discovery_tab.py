path = 'lib/main.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_import = "import 'screens/record/record_screen.dart';"
new_import = "import 'screens/record/record_screen.dart';\nimport 'screens/home/data_discovery_screen.dart';"
if new_import not in content:
    content = content.replace(old_import, new_import)
    print("Added import")

old_screens = """  final List<Widget> _screens = const [
    HomeScreen(),
    RecordScreen(),
    AboutScreen(),
  ];"""
new_screens = """  final List<Widget> _screens = const [
    HomeScreen(),
    RecordScreen(),
    DataDiscoveryScreen(),
    AboutScreen(),
  ];"""
if old_screens not in content:
    print("ERROR: _screens list not found")
else:
    content = content.replace(old_screens, new_screens)
    print("Added DataDiscoveryScreen to _screens list")

old_items = """          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'About',
          ),"""
new_items = """          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Data discovery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'About',
          ),"""
if old_items not in content:
    print("ERROR: BottomNavigationBarItem list not found")
else:
    content = content.replace(old_items, new_items)
    print("Added Data discovery tab item")

if content == original:
    print("NOTHING CHANGED - aborting write")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
