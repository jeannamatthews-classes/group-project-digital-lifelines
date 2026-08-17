path = 'lib/screens/home/party_game_answer_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_import = "import '../../data/party_questions.dart';"
new_import = "import '../../data/party_questions.dart';\nimport '../../data/party_query_engine.dart';"
if new_import not in content:
    content = content.replace(old_import, new_import)
    print("Added query engine import")
else:
    print("Import already present")

old_init_area = """  @override
  void initState() {
    super.initState();
    if (Platform.isIOS && widget.iosDeviceId != null) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }"""
new_init_area = """  bool _isComputingAnswer = false;
  String? _autoComputedAnswer;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS && widget.iosDeviceId != null) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
    if (widget.question.queryType != null) {
      _computeAutoAnswer();
    }
  }

  Future<void> _computeAutoAnswer() async {
    setState(() {
      _isComputingAnswer = true;
    });

    String? result;
    if (widget.question.queryType == 'mostFrequentFieldValue' &&
        widget.question.targetTimeline != null &&
        widget.question.targetField != null) {
      result = await computeMostFrequentFieldValue(
        timelineName: widget.question.targetTimeline!,
        fieldName: widget.question.targetField!,
      );
    }

    if (!mounted) return;
    setState(() {
      _isComputingAnswer = false;
      _autoComputedAnswer = result;
      if (result != null) {
        _answerController.text = result;
      }
    });
  }"""
if old_init_area not in content:
    print("ERROR: initState block not found")
else:
    content = content.replace(old_init_area, new_init_area)
    print("Added auto-answer computation logic")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
