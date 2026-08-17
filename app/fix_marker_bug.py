import re

# ---- 1. Host screen: question broadcast now includes a type marker ----
path = 'lib/screens/home/party_game_host_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old_q = """      final manufacturerData = Uint8List.fromList([widget.questionId & 0xFF]);"""
new_q = """      // 0xA1 marks this as a QUESTION broadcast (vs 0xA2 for answers).
      final manufacturerData = Uint8List.fromList([0xA1, widget.questionId & 0xFF]);"""
if old_q not in content:
    print("ERROR: host question payload block not found")
else:
    content = content.replace(old_q, new_q)

old_listen = """      final data = device.manufacturerData;
      if (data.length < 3) return;
      if (data[0] != 0xFF || data[1] != 0xFF) return;

      // More than 1 payload byte means this is answer text, not a question id.
      final payload = data.sublist(2);
      if (payload.length < 2) return; // question broadcasts are 1 byte

      final answerText = utf8.decode(payload, allowMalformed: true);"""
new_listen = """      final data = device.manufacturerData;
      if (data.length < 3) return;
      if (data[0] != 0xFF || data[1] != 0xFF) return;

      // 0xA2 marks this as an ANSWER broadcast - check the marker byte,
      // not the payload length (a 1-character answer is still valid!).
      if (data[2] != 0xA2) return;
      final payload = data.sublist(3);
      if (payload.isEmpty) return;

      final answerText = utf8.decode(payload, allowMalformed: true);"""
if old_listen not in content:
    print("ERROR: host answer listener block not found")
else:
    content = content.replace(old_listen, new_listen)

with open(path, 'w') as f:
    f.write(content)
print("Patched host screen")

# ---- 2. Connect screen: parse question with the new marker format ----
path = 'lib/screens/home/party_game_connect_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old = """  // Manufacturer data layout we broadcast: [0xFF, 0xFF, questionId]
  int? _parseQuestionId(Uint8List data) {
    if (data.length < 3) return null;
    if (data[0] != 0xFF || data[1] != 0xFF) return null;
    return data[2];
  }"""
new = """  // Manufacturer data layout we broadcast: [0xFF, 0xFF, 0xA1, questionId]
  int? _parseQuestionId(Uint8List data) {
    if (data.length < 4) return null;
    if (data[0] != 0xFF || data[1] != 0xFF) return null;
    if (data[2] != 0xA1) return null;
    return data[3];
  }"""
if old not in content:
    print("ERROR: connect screen parse block not found")
else:
    content = content.replace(old, new)

with open(path, 'w') as f:
    f.write(content)
print("Patched connect screen")

# ---- 3. Answer screen: broadcast answer with the 0xA2 marker ----
path = 'lib/screens/home/party_game_answer_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old = """      final advertiseData = AdvertiseData(
        manufacturerId: 0xFFFF,
        manufacturerData: Uint8List.fromList(utf8.encode(truncated)),
      );"""
new = """      // 0xA2 marks this as an ANSWER broadcast (vs 0xA1 for questions).
      final answerBytes = utf8.encode(truncated);
      final manufacturerData = Uint8List.fromList([0xA2, ...answerBytes]);

      final advertiseData = AdvertiseData(
        manufacturerId: 0xFFFF,
        manufacturerData: manufacturerData,
      );"""
if old not in content:
    print("ERROR: answer screen broadcast block not found")
else:
    content = content.replace(old, new)

with open(path, 'w') as f:
    f.write(content)
print("Patched answer screen")
