path = 'lib/screens/home/party_game_duo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

# 1. Add import
old_import = "import '../../data/party_questions.dart';"
new_import = "import '../../data/party_questions.dart';\nimport '../../data/party_query_engine.dart';"
if new_import not in content:
    content = content.replace(old_import, new_import)
    print("Added query engine import")
else:
    print("Import already present")

# 2. Trigger auto-computation when a new friend question arrives
old_new_question = """        if (_friendQuestion?.id != question.id) {
          setState(() {
            _friendQuestion = question;
            _replySent = false;
            _replyController.clear();
          });
        }"""
new_new_question = """        if (_friendQuestion?.id != question.id) {
          setState(() {
            _friendQuestion = question;
            _replySent = false;
            _replyController.clear();
            _isComputingReply = false;
            _autoComputedReply = null;
          });
          if (question.queryType != null) {
            _computeAutoReply(question);
          }
        }"""
if old_new_question not in content:
    print("ERROR: friend question setState block not found")
else:
    content = content.replace(old_new_question, new_new_question)
    print("Added auto-compute trigger on new question")

# 3. Add the state fields + compute method right after class state fields
old_field = "  bool _replySent = false;"
new_field = """  bool _replySent = false;
  bool _isComputingReply = false;
  String? _autoComputedReply;

  Future<void> _computeAutoReply(PartyQuestion question) async {
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
if old_field not in content:
    print("ERROR: _replySent field not found")
else:
    content = content.replace(old_field, new_field, 1)
    print("Added auto-reply state and compute method")

# 4. Add UI indicator above the reply TextField
old_ui = """                    const SizedBox(height: 12),
                    if (!_replySent) ...[
                      TextField(
                        controller: _replyController,
                        maxLength: _maxAnswerLength,
                        decoration: const InputDecoration(
                          labelText: 'Your reply',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),"""
new_ui = """                    const SizedBox(height: 12),
                    if (_friendQuestion!.queryType != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isComputingReply
                              ? Colors.grey.shade100
                              : AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            if (_isComputingReply)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(
                                _autoComputedReply != null
                                    ? Icons.auto_awesome_rounded
                                    : Icons.info_outline_rounded,
                                size: 15,
                                color: AppColors.accent,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isComputingReply
                                    ? 'Looking up your answer...'
                                    : (_autoComputedReply != null
                                        ? 'Found automatically from your data'
                                        : 'Could not auto-find - type your own'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (!_replySent) ...[
                      TextField(
                        controller: _replyController,
                        maxLength: _maxAnswerLength,
                        decoration: const InputDecoration(
                          labelText: 'Your reply',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),"""
if old_ui not in content:
    print("ERROR: reply TextField UI block not found")
else:
    content = content.replace(old_ui, new_ui)
    print("Added auto-answer UI indicator to duo screen")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
