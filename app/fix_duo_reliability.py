path = 'lib/screens/home/party_game_duo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

# ---- 1. Add a small delay between stop() and start() when broadcasting a question ----
old_q = """      await _peripheral.stop();

      // 0xA1 marks this as a QUESTION broadcast.
      final manufacturerData =
          Uint8List.fromList([0xA1, _myQuestion!.id & 0xFF]);"""
new_q = """      await _peripheral.stop();
      // Small delay avoids a known Android BLE issue where restarting
      // advertising immediately after stopping it can silently fail.
      await Future.delayed(const Duration(milliseconds: 300));

      // 0xA1 marks this as a QUESTION broadcast.
      final manufacturerData =
          Uint8List.fromList([0xA1, _myQuestion!.id & 0xFF]);"""
if old_q not in content:
    print("ERROR: question broadcast block not found")
else:
    content = content.replace(old_q, new_q)
    print("Added delay before question broadcast")

# ---- 2. Same delay for the answer broadcast ----
old_a = """      await _peripheral.stop();

      final truncated = replyText.length > _maxAnswerLength"""
new_a = """      await _peripheral.stop();
      await Future.delayed(const Duration(milliseconds: 300));

      final truncated = replyText.length > _maxAnswerLength"""
if old_a not in content:
    print("ERROR: answer broadcast block not found")
else:
    content = content.replace(old_a, new_a)
    print("Added delay before answer broadcast")

# ---- 3. Add periodic scan restart to combat Android scan-result staleness ----
old_init = """  @override
  void initState() {
    super.initState();
    _startListening();
  }"""
new_init = """  Timer? _scanRestartTimer;

  @override
  void initState() {
    super.initState();
    _startListening();
    // Android's BLE scanner can stop reporting fresh advertisement updates
    // for a device it has already "seen" once, especially when that
    // device's payload changes (like when a friend picks a new question).
    // Periodically restarting the scan forces it to treat every device as
    // new again, so updated broadcasts get picked up reliably.
    _scanRestartTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _scanSubscription?.cancel();
      _startListening();
    });
  }"""
if old_init not in content:
    print("ERROR: initState block not found")
else:
    content = content.replace(old_init, new_init)
    print("Added periodic scan restart")

old_dispose = """  @override
  void dispose() {
    _scanSubscription?.cancel();
    _resumeQuestionTimer?.cancel();
    _peripheral.stop();
    _replyController.dispose();
    super.dispose();
  }"""
new_dispose = """  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanRestartTimer?.cancel();
    _resumeQuestionTimer?.cancel();
    _peripheral.stop();
    _replyController.dispose();
    super.dispose();
  }"""
if old_dispose not in content:
    print("ERROR: dispose block not found")
else:
    content = content.replace(old_dispose, new_dispose)
    print("Updated dispose to cancel scan restart timer")

if content == original:
    print("NOTHING CHANGED - aborting write")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
