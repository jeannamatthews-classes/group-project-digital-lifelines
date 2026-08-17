path = 'lib/screens/home/party_game_connect_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_handler = """  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'deviceFound') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      final id = data['id'] as String;
      if (!mounted) return;
      setState(() {
        _foundDevices[id] = data;
      });
    }
  }"""
new_handler = """  bool _connecting = false;

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'deviceFound') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      final id = data['id'] as String;
      if (!mounted) return;
      setState(() {
        _foundDevices[id] = data;
      });
    } else if (call.method == 'questionRead') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      final deviceId = data['deviceId'] as String;
      final questionId = data['questionId'] as int;
      final question = findPartyQuestionById(questionId);
      if (!mounted) return;
      setState(() {
        _connecting = false;
      });
      if (question != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PartyGameAnswerScreen(
              question: question,
              iosDeviceId: deviceId,
            ),
          ),
        );
      }
    } else if (call.method == 'connectionFailed') {
      if (!mounted) return;
      setState(() {
        _connecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect. Try again.')),
      );
    }
  }"""
if old_handler not in content:
    print("ERROR: _handleMethodCall block not found")
else:
    content = content.replace(old_handler, new_handler)
    print("Updated _handleMethodCall with questionRead/connectionFailed")

old_connect = """  void _connectToDevice(Map<String, dynamic> device) {
    _stopScan();
    final questionId = device['questionId'] as int?;
    final question =
        questionId != null ? findPartyQuestionById(questionId) : null;

    if (question != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PartyGameAnswerScreen(question: question),
        ),
      );
    } else {
      final name = (device['name'] as String?) ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to: $name (no question id found)')),
      );
    }
  }"""
new_connect = """  void _connectToDevice(Map<String, dynamic> device) {
    if (Platform.isIOS) {
      _stopScan();
      setState(() {
        _connecting = true;
      });
      _channel.invokeMethod('connectAndReadQuestion', {'deviceId': device['id']});
      return;
    }

    _stopScan();
    final questionId = device['questionId'] as int?;
    final question =
        questionId != null ? findPartyQuestionById(questionId) : null;

    if (question != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PartyGameAnswerScreen(question: question),
        ),
      );
    } else {
      final name = (device['name'] as String?) ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to: $name (no question id found)')),
      );
    }
  }"""
if old_connect not in content:
    print("ERROR: _connectToDevice block not found")
else:
    content = content.replace(old_connect, new_connect)
    print("Updated _connectToDevice to use GATT connect on iOS")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
