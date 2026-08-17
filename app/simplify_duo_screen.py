path = 'lib/screens/home/party_game_duo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_compute = """  Future<void> _computeAutoReply(PartyQuestion question) async {
    setState(() {
      _isComputingReply = true;
    });

    String? result;
    if (question.queryType == 'mostFrequentFieldValue' &&
        question.targetTimeline != null &&
        question.targetField != null) {
      result = await computeMostFrequentFieldValue(
        timelineName: question.targetTimeline!,
        fieldName: question.targetField!,
      );
    }

    if (!mounted) return;
    setState(() {
      _isComputingReply = false;
      _autoComputedReply = result;
      if (result != null) {
        _replyController.text = result;
      }
    });
  }"""
new_compute = """  Future<void> _computeAutoReply(PartyQuestion question) async {
    setState(() {
      _isComputingReply = true;
    });

    final result = await runQueryForQuestion(question);

    if (!mounted) return;
    setState(() {
      _isComputingReply = false;
      _autoComputedReply = result;
      if (result != null) {
        _replyController.text = result;
      }
    });
  }"""
if old_compute not in content:
    print("ERROR: _computeAutoReply block not found")
else:
    content = content.replace(old_compute, new_compute)
    print("Simplified _computeAutoReply to use runQueryForQuestion")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
