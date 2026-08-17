path = 'lib/screens/home/party_game_duo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old = """    }, onError: (e) {
      // ignore scan errors
    });"""
new = """    }, onError: (e) {
      print('DUO_DEBUG: SCAN ERROR: $e');
    });"""
if old not in content:
    print("ERROR: onError block not found - aborting")
else:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("Done! Scan errors will now print to console.")
