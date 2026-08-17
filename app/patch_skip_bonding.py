path = '/Users/ashikahamed/.pub-cache/hosted/pub.dev/ble_peripheral-1.0.0/android/src/main/kotlin/com/rohit/ble_peripheral/BlePeripheralPlugin.kt'
with open(path, 'r') as f:
    content = f.read()

old = """                        if (device.bondState == BluetoothDevice.BOND_NONE) {
                            // Wait for bonding
                            listOfDevicesWaitingForBond.add(device.address)
                            device.createBond()
                        } else if (device.bondState == BluetoothDevice.BOND_BONDED) {
                            handler.post {
                                gattServer?.connect(device, true)
                            }
                            synchronized(bluetoothDevicesMap) {
                                bluetoothDevicesMap.put(
                                    device.address,
                                    device
                                )
                            }
                        }"""

new = """                        // Skip bonding entirely - our characteristics don't require
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

if old not in content:
    print("ERROR: could not find the exact block - no changes made")
else:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("Done! Patched plugin to skip bonding on connect.")
