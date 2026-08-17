path = 'lib/screens/home/party_game_duo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old_import = "import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';"
new_import = "import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';\nimport 'package:permission_handler/permission_handler.dart';"
if new_import not in content:
    content = content.replace(old_import, new_import)
    print("Added import")

old_init = """  @override
  void initState() {
    super.initState();
    _startListening();"""
new_init = """  @override
  void initState() {
    super.initState();
    _requestPermissionsThenListen();"""
if old_init not in content:
    print("ERROR: initState block not found")
else:
    content = content.replace(old_init, new_init)
    print("Updated initState")

old_method = """  void _startListening() {"""
new_method = """  Future<void> _requestPermissionsThenListen() async {
    // Android needs these granted at runtime, not just declared in the
    // manifest - toggling them manually in Settings doesn't always
    // register correctly, especially on some OEM Android skins.
    await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();
    _startListening();
  }

  void _startListening() {"""
if old_method not in content:
    print("ERROR: _startListening method not found")
else:
    content = content.replace(old_method, new_method)
    print("Added permission request method")

with open(path, 'w') as f:
    f.write(content)
print("File saved.")
