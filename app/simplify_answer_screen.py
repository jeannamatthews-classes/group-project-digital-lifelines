path = 'lib/screens/home/party_game_answer_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_compute = """  Future<void> _computeAutoAnswer() async {
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
new_compute = """  Future<void> _computeAutoAnswer() async {
    setState(() {
      _isComputingAnswer = true;
    });

    final result = await runQueryForQuestion(widget.question);

    if (!mounted) return;
    setState(() {
      _isComputingAnswer = false;
      _autoComputedAnswer = result;
      if (result != null) {
        _answerController.text = result;
      }
    });
  }"""
if old_compute not in content:
    print("ERROR: _computeAutoAnswer block not found")
else:
    content = content.replace(old_compute, new_compute)
    print("Simplified _computeAutoAnswer to use runQueryForQuestion")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
