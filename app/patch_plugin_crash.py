path = '/Users/ashikahamed/.pub-cache/hosted/pub.dev/ble_peripheral-1.0.0/android/src/main/kotlin/com/rohit/ble_peripheral/BlePeripheralPlugin.kt'
with open(path, 'r') as f:
    content = f.read()

old = """                handler.post {
                    bleCallback?.onBondStateChange(
                        device?.address ?: \"\",
                        state.toBondState(),
                    ) {}
                }"""

new = """                if (::handler.isInitialized) {
                    handler.post {
                        bleCallback?.onBondStateChange(
                            device?.address ?: \"\",
                            state.toBondState(),
                        ) {}
                    }
                }"""

if old not in content:
    print("ERROR: could not find the exact block - no changes made")
else:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("Done! Patched BlePeripheralPlugin.kt to guard against uninitialized handler.")
