import sys

with open('lib/screens/home/party_game_connect_screen.dart', 'r') as f:
    content = f.read()

original = content

# 1. Add import
if "import 'dart:typed_data';" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'dart:typed_data';"
    )
    print("✅ Added dart:typed_data import")
else:
    print("ℹ️  import already present")

# 2. Add parser helper before _startScan
parser = '''  int? _parseQuestionId(Uint8List data) {
    if (data.length < 3) return null;
    if (data[0] != 0xFF || data[1] != 0xFF) return null;
    return data[2];
  }

  void _startScan()'''

if '  void _startScan()' not in content:
    print("❌ ERROR: Could not find _startScan() — aborting!")
    sys.exit(1)

if '_parseQuestionId' not in content:
    content = content.replace('  void _startScan()', parser)
    print("✅ Added _parseQuestionId helper")
else:
    print("ℹ️  _parseQuestionId already present")

# 3. Update scan listener
old_listen = "'questionId': null,"
new_listen = "'questionId': _parseQuestionId(device.manufacturerData),"
if old_listen in content:
    content = content.replace(old_listen, new_listen)
    print("✅ Updated scan listener to use manufacturerData")
else:
    print("❌ ERROR: Could not find questionId: null — aborting!")
    sys.exit(1)

# 4. Update _connectToDevice
old_connect = """  void _connectToDevice(Map<String, dynamic> device) {
    _stopScan();
    final name = (device['name'] as String?) ?? '';
    // Extract question ID from name like "DL_Q5"
    int? questionId;
    if (name.startsWith('DL_Q')) {
      questionId = int.tryParse(name.substring(4));
    }
    if (questionId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected! Question ID: $questionId')),
      );
      // TODO: Navigate to answer screen with questionId
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to: $name')),
      );
    }
  }"""

new_connect = """  void _connectToDevice(Map<String, dynamic> device) {
    _stopScan();
    final questionId = device['questionId'] as int?;
    if (questionId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected! Question ID: $questionId')),
      );
      // TODO: Navigate to answer screen with questionId
    } else {
      final name = (device['name'] as String?) ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to: $name (no question id found)')),
      );
    }
  }"""

if old_connect in content:
    content = content.replace(old_connect, new_connect)
    print("✅ Updated _connectToDevice")
else:
    print("❌ ERROR: Could not find _connectToDevice old version — aborting!")
    sys.exit(1)

# 5. Update list tile display
old_tile = """                        final name = (device['name'] as String?)?.isNotEmpty == true
                            ? device['name'] as String
                            : '(unnamed)';"""
new_tile = """                        final questionId = device['questionId'] as int?;
                        final name = questionId != null
                            ? 'Question #$questionId'
                            : ((device['name'] as String?)?.isNotEmpty == true
                                ? device['name'] as String
                                : '(unnamed)');"""
if old_tile in content:
    content = content.replace(old_tile, new_tile)
    print("✅ Updated list tile display")
else:
    print("⚠️  Could not find list tile text — skipping (non-critical)")

if content != original:
    with open('lib/screens/home/party_game_connect_screen.dart', 'w') as f:
        f.write(content)
    print("\n✅ File saved successfully!")
else:
    print("\n⚠️  No changes were made!")
