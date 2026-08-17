path = 'lib/screens/home/party_game_host_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old = """    // Called when the joiner writes their answer to the answer characteristic.
    // Note: characteristicId here is an internal int handle (not the UUID
    // string), and since this service only has one writable characteristic
    // we don't need to filter on it - any write is the answer.
    BlePeripheral.setWriteRequestCallback(
      (String deviceId, int characteristicId, Uint8List? value, dynamic request) {
        if (value == null) return;
        final answerText = utf8.decode(value, allowMalformed: true);
        if (!mounted) return;
        setState(() {
          _receivedAnswer = answerText;
        });
      },
    );"""

new = """    // Called when the joiner writes their answer to the answer characteristic.
    BlePeripheral.setWriteRequestCallback(
      (String characteristicId, int offset, Uint8List? value) {
        if (value == null) return;
        final answerText = utf8.decode(value, allowMalformed: true);
        if (!mounted) return;
        setState(() {
          _receivedAnswer = answerText;
        });
      },
    );"""

if old not in content:
    print("ERROR: could not find the write callback block - no changes made")
else:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("Done! Write callback now matches the real 3-param typedef.")
