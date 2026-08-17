path = 'lib/screens/home/party_game_connect_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old = """  @override
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

new = """  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
    // Note: the underlying ble_peripheral plugin (used only by the host
    // screen) was patched directly in pub-cache to guard against an
    // uninitialized handler crash, so no initialize() call is needed here.
  }"""

if old not in content:
    print("ERROR: could not find the initState block - no changes made")
else:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("Done! Reverted the joiner-side initialize() call.")
