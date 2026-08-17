path = 'lib/screens/home/party_game_answer_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_ui = """            const SizedBox(height: 24),
            if (!_sent) ...[
              TextField(
                controller: _answerController,
                maxLength: _maxAnswerLength,
                decoration: const InputDecoration(
                  labelText: 'Your answer',
                  helperText: 'Keep it short - up to 20 characters',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isBroadcasting,
              ),"""
new_ui = """            const SizedBox(height: 24),
            if (widget.question.queryType != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isComputingAnswer
                      ? Colors.grey.shade100
                      : AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    if (_isComputingAnswer)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _autoComputedAnswer != null
                            ? Icons.auto_awesome_rounded
                            : Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isComputingAnswer
                            ? 'Looking up your answer automatically...'
                            : (_autoComputedAnswer != null
                                ? 'Found automatically from your data'
                                : 'Could not find this automatically - '
                                    'type your own answer below'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (!_sent) ...[
              TextField(
                controller: _answerController,
                maxLength: _maxAnswerLength,
                decoration: const InputDecoration(
                  labelText: 'Your answer',
                  helperText: 'Keep it short - up to 20 characters',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isBroadcasting,
              ),"""
if old_ui not in content:
    print("ERROR: TextField UI block not found")
else:
    content = content.replace(old_ui, new_ui)
    print("Added auto-answer UI indicator")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
