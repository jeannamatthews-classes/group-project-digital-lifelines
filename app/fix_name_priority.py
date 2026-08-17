path = 'ios/Runner/BleScanner.swift'
with open(path, 'r') as f:
    content = f.read()

original = content

old_line = '        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""'
new_line = '        // Prefer the freshly-broadcast local name over any cached system\n        // name iOS may already know for this device (e.g. from Apple\'s own\n        // background Continuity features) - otherwise our custom pair-code\n        // name gets silently overridden and matching breaks.\n        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name ?? ""'

if old_line not in content:
    print("ERROR: name priority line not found")
else:
    content = content.replace(old_line, new_line)
    print("Fixed name priority - local broadcast name now takes precedence")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
