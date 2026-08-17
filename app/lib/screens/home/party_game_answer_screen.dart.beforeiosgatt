import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

import '../../theme/app_theme.dart';
import '../../data/party_questions.dart';

class PartyGameAnswerScreen extends StatefulWidget {
  final PartyQuestion question;

  const PartyGameAnswerScreen({
    super.key,
    required this.question,
  });

  @override
  State<PartyGameAnswerScreen> createState() => _PartyGameAnswerScreenState();
}

class _PartyGameAnswerScreenState extends State<PartyGameAnswerScreen> {
  static const int _maxAnswerLength = 20;

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  final TextEditingController _answerController = TextEditingController();

  bool _isBroadcasting = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _peripheral.stop();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _sendAnswer() async {
    final answerText = _answerController.text.trim();
    if (answerText.isEmpty) {
      setState(() {
        _errorMessage = 'Please type an answer first.';
      });
      return;
    }

    setState(() {
      _isBroadcasting = true;
      _errorMessage = null;
    });

    try {
      final isSupported = await _peripheral.isSupported;
      if (!isSupported) {
        setState(() {
          _isBroadcasting = false;
          _errorMessage = 'This device does not support BLE advertising.';
        });
        return;
      }

      // Truncate to fit the BLE advertising payload limit.
      final truncated = answerText.length > _maxAnswerLength
          ? answerText.substring(0, _maxAnswerLength)
          : answerText;

      // No service UUID here (unlike the question broadcast) - this frees up
      // advertising payload space for the answer text itself. The host
      // distinguishes this from other broadcasts using the 0xFFFF
      // manufacturer id marker plus payload length (>1 byte = answer text,
      // vs 1 byte = question id).
      // 0xA2 marks this as an ANSWER broadcast (vs 0xA1 for questions).
      final answerBytes = utf8.encode(truncated);
      final manufacturerData = Uint8List.fromList([0xA2, ...answerBytes]);

      final advertiseData = AdvertiseData(
        manufacturerId: 0xFFFF,
        manufacturerData: manufacturerData,
      );

      final advertiseSettings = AdvertiseSettings(
        connectable: false,
      );

      await _peripheral.start(
        advertiseData: advertiseData,
        advertiseSettings: advertiseSettings,
      );

      if (!mounted) return;
      setState(() {
        _isBroadcasting = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBroadcasting = false;
        _errorMessage = 'Failed to send answer: $e';
      });
    }
  }

  Future<void> _stopBroadcasting() async {
    await _peripheral.stop();
    if (!mounted) return;
    setState(() {
      _sent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Answer the Question',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.appBarText,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                    Icons.help_outline_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.question.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.appBarText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.question.hint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isBroadcasting ? null : _sendAnswer,
                icon: _isBroadcasting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isBroadcasting ? 'Sending...' : 'Send Answer'),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.bluetooth_audio_rounded,
                      size: 40,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Broadcasting your answer...',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.appBarText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _answerController.text.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Keep this screen open until your friend confirms they got it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.mutedText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  await _stopBroadcasting();
                  if (!mounted) return;
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                child: const Text('Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
