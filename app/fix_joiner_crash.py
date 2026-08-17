path = 'lib/screens/home/party_game_connect_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old_import = "import 'party_game_answer_screen.dart';"
new_import = "import 'party_game_answer_screen.dart';\nimport 'package:ble_peripheral/ble_peripheral.dart';"

if new_import not in content:
    content = content.replace(old_import, new_import)
    print("Added ble_peripheral import")

old_init = """  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }"""

new_init = """  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _channel.setMethodCallHandler(_handleMethodCall);
    } else {
      // ble_peripheral registers a system Bluetooth broadcast receiver as
      // soon as the plugin loads, but its internal handler is only set up
      // by initialize(). Without this, an incoming BOND_STATE_CHANGED
      // broadcast crashes the app with UninitializedPropertyAccessException,
      // even though this screen never advertises anything itself.
      BlePeripheral.initialize();
    }
  }"""

if old_init not in content:
    print("ERROR: could not find initState block - aborting")
else:
    content = content.replace(old_init, new_init)
    with open(path, 'w') as f:
        f.write(content)
    print("Done! Joiner now initializes ble_peripheral to prevent the crash.")
