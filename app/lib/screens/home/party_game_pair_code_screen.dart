import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'party_game_duo_screen.dart';

class PartyGamePairCodeScreen extends StatefulWidget {
  final Set<String> selectedCategories;

  const PartyGamePairCodeScreen({
    super.key,
    this.selectedCategories = const {'photos'},
  });

  @override
  State<PartyGamePairCodeScreen> createState() =>
      _PartyGamePairCodeScreenState();
}

class _PartyGamePairCodeScreenState extends State<PartyGamePairCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _continue() {
    final text = _codeController.text.trim();
    final code = int.tryParse(text);
    if (code == null || code < 0 || code > 255) {
      setState(() {
        _errorMessage = 'Enter a number between 0 and 255.';
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartyGameDuoScreen(
          pairCode: code,
          selectedCategories: widget.selectedCategories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Pair Up',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.appBarText,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.tag_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pick any number and agree on it with your partner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.appBarText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This keeps your questions and answers separate from other groups nearby.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                labelText: 'Your pair code (0-255)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _continue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
