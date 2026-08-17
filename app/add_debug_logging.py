path = 'lib/screens/home/party_game_duo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old = """      final data = device.manufacturerData;
      if (data.length < 4) return;
      if (data[0] != 0xFF || data[1] != 0xFF) return;

      // Ignore broadcasts from other pairs in the room - only accept ones
      // tagged with our own pair code.
      if (data[3] != widget.pairCode) return;"""

new = """      final data = device.manufacturerData;
      if (data.length < 4) return;
      if (data[0] != 0xFF || data[1] != 0xFF) return;

      print('DUO_DEBUG: saw broadcast type=0x\${data[2].toRadixString(16)} '
          'incomingPairCode=\${data[3]} myPairCode=\${widget.pairCode} '
          'fullData=\$data');

      // Ignore broadcasts from other pairs in the room - only accept ones
      // tagged with our own pair code.
      if (data[3] != widget.pairCode) return;"""

if old not in content:
    print("ERROR: scan listener block not found - aborting")
else:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("Done! Debug logging added to scan listener.")
