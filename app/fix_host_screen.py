import sys

with open('lib/screens/home/party_game_host_screen.dart', 'r') as f:
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

# 2. Update advertiseData to include manufacturerData
old_advert = """final advertiseData = AdvertiseData(
  serviceUuid: '0000DDDD-0000-1000-8000-00805F9B34FB',
  localName: 'DL_Q${widget.questionId}',
);"""

new_advert = """final advertiseData = AdvertiseData(
  serviceUuid: '0000DDDD-0000-1000-8000-00805F9B34FB',
  localName: 'DL_Q${widget.questionId}',
  manufacturerData: Uint8List.fromList([
    0xFF, 0xFF,                        // company ID
    widget.questionId & 0xFF,          // question ID
  ]),
);"""

if old_advert in content:
    content = content.replace(old_advert, new_advert)
    print("✅ Updated advertiseData with manufacturerData")
else:
    print("❌ ERROR: Could not find advertiseData — aborting!")
    sys.exit(1)

if content != original:
    with open('lib/screens/home/party_game_host_screen.dart', 'w') as f:
        f.write(content)
    print("\n✅ File saved successfully!")
else:
    print("\n⚠️  No changes were made!")
