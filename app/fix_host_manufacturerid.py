path = 'lib/screens/home/party_game_host_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old = """final advertiseData = AdvertiseData(
  serviceUuid: '0000DDDD-0000-1000-8000-00805F9B34FB',
  localName: 'DL_Q${widget.questionId}',
  manufacturerData: Uint8List.fromList([
    0xFF, 0xFF,                        // company ID
    widget.questionId & 0xFF,          // question ID
  ]),
);"""

new = """final advertiseData = AdvertiseData(
  serviceUuid: '0000DDDD-0000-1000-8000-00805F9B34FB',
  manufacturerId: 0xFFFF,
  manufacturerData: Uint8List.fromList([widget.questionId & 0xFF]),
);"""

if old not in content:
    print("ERROR: could not find the exact block to replace - no changes made")
else:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("Done! manufacturerId added, duplicate company-id bytes removed.")
