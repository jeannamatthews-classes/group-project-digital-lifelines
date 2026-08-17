path = 'lib/screens/home/party_game_duo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

# 1. Add pairCode field to widget
old_class = """class PartyGameDuoScreen extends StatefulWidget {
  const PartyGameDuoScreen({super.key});

  @override
  State<PartyGameDuoScreen> createState() => _PartyGameDuoScreenState();
}"""
new_class = """class PartyGameDuoScreen extends StatefulWidget {
  final int pairCode;

  const PartyGameDuoScreen({super.key, required this.pairCode});

  @override
  State<PartyGameDuoScreen> createState() => _PartyGameDuoScreenState();
}"""
if old_class not in content:
    print("ERROR: class declaration not found")
else:
    content = content.replace(old_class, new_class)
    print("Added pairCode field")

# 2. Update scan listener to check pair code and adjust byte offsets
old_listen = """      final data = device.manufacturerData;
      if (data.length < 3) return;
      if (data[0] != 0xFF || data[1] != 0xFF) return;

      if (data[2] == 0xA1) {
        // Friend is broadcasting a question.
        if (data.length < 4) return;
        final questionId = data[3];
        final question = findPartyQuestionById(questionId);
        if (question == null || !mounted) return;
        if (_friendQuestion?.id != question.id) {
          setState(() {
            _friendQuestion = question;
            _replySent = false;
            _replyController.clear();
          });
        }
      } else if (data[2] == 0xA2) {
        // Friend is broadcasting an answer to our question.
        if (_myQuestion == null) return;
        final payload = data.sublist(3);
        if (payload.isEmpty || !mounted) return;
        final answerText = utf8.decode(payload, allowMalformed: true);
        setState(() {
          _friendAnswer = answerText;
        });
      }"""
new_listen = """      final data = device.manufacturerData;
      if (data.length < 4) return;
      if (data[0] != 0xFF || data[1] != 0xFF) return;

      // Ignore broadcasts from other pairs in the room - only accept ones
      // tagged with our own pair code.
      if (data[3] != widget.pairCode) return;

      if (data[2] == 0xA1) {
        // Friend is broadcasting a question.
        if (data.length < 5) return;
        final questionId = data[4];
        final question = findPartyQuestionById(questionId);
        if (question == null || !mounted) return;
        if (_friendQuestion?.id != question.id) {
          setState(() {
            _friendQuestion = question;
            _replySent = false;
            _replyController.clear();
          });
        }
      } else if (data[2] == 0xA2) {
        // Friend is broadcasting an answer to our question.
        if (_myQuestion == null) return;
        final payload = data.sublist(4);
        if (payload.isEmpty || !mounted) return;
        final answerText = utf8.decode(payload, allowMalformed: true);
        setState(() {
          _friendAnswer = answerText;
        });
      }"""
if old_listen not in content:
    print("ERROR: scan listener not found")
else:
    content = content.replace(old_listen, new_listen)
    print("Updated scan listener with pair code check")

# 3. Update question broadcast to include pair code
old_q_data = """      // 0xA1 marks this as a QUESTION broadcast.
      final manufacturerData =
          Uint8List.fromList([0xA1, _myQuestion!.id & 0xFF]);"""
new_q_data = """      // 0xA1 marks this as a QUESTION broadcast. Byte layout:
      // [0xA1, pairCode, questionId]
      final manufacturerData = Uint8List.fromList(
          [0xA1, widget.pairCode & 0xFF, _myQuestion!.id & 0xFF]);"""
if old_q_data not in content:
    print("ERROR: question manufacturerData block not found")
else:
    content = content.replace(old_q_data, new_q_data)
    print("Updated question broadcast with pair code")

# 4. Update answer broadcast to include pair code
old_a_data = """      // 0xA2 marks this as an ANSWER broadcast.
      final answerBytes = utf8.encode(truncated);
      final manufacturerData = Uint8List.fromList([0xA2, ...answerBytes]);"""
new_a_data = """      // 0xA2 marks this as an ANSWER broadcast. Byte layout:
      // [0xA2, pairCode, ...answerBytes]
      final answerBytes = utf8.encode(truncated);
      final manufacturerData =
          Uint8List.fromList([0xA2, widget.pairCode & 0xFF, ...answerBytes]);"""
if old_a_data not in content:
    print("ERROR: answer manufacturerData block not found")
else:
    content = content.replace(old_a_data, new_a_data)
    print("Updated answer broadcast with pair code")

if content == original:
    print("NOTHING CHANGED - aborting write")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
