path = '/Users/ashikahamed/.pub-cache/hosted/pub.dev/ble_peripheral-1.0.0/android/src/main/kotlin/com/rohit/ble_peripheral/BlePeripheralPlugin.kt'
with open(path, 'r') as f:
    content = f.read()

old = """                        // Skip bonding entirely - our characteristics don't require
                        // encryption, and waiting for bonding was blowing past the
                        // joiner's service discovery timeout.
                        if (::handler.isInitialized) {
                            handler.post {
                                gattServer?.connect(device, true)
                            }
                        } else {
                            gattServer?.connect(device, true)
                        }
                        synchronized(bluetoothDevicesMap) {
                            bluetoothDevicesMap.put(
                                device.address,
                                device
                            )
                        }"""

new = """                        // Skip bonding entirely, and skip the redundant
                        // gattServer.connect() call - the device is already
                        // connected at this point (that's why we're here), and
                        // re-calling connect() was resetting the server's internal
                        // state and breaking the central's service discovery.
                        synchronized(bluetoothDevicesMap) {
                            bluetoothDevicesMap.put(
                                device.address,
                                device
                            )
                        }"""

if old not in content:
    print("ERROR: could not find the exact block - no changes made")
else:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("Done! Removed redundant gattServer.connect() call.")
