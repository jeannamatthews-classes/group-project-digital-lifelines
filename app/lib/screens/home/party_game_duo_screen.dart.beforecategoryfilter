import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/app_theme.dart';
import '../../data/party_questions.dart';

class PartyGameDuoScreen extends StatefulWidget {
  final int pairCode;

  const PartyGameDuoScreen({super.key, required this.pairCode});

  @override
  State<PartyGameDuoScreen> createState() => _PartyGameDuoScreenState();
}

class _PartyGameDuoScreenState extends State<PartyGameDuoScreen> {
  static const int _maxAnswerLength = 20;

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  Timer? _resumeQuestionTimer;

  PartyQuestion? _myQuestion;
  bool _isBroadcastingQuestion = false;
  bool _isBroadcastingAnswer = false;
  String? _errorMessage;

  PartyQuestion? _friendQuestion;
  final TextEditingController _replyController = TextEditingController();
  bool _replySent = false;

  String? _friendAnswer;

  Timer? _scanRestartTimer;

  @override
  void initState() {
    super.initState();
    _requestPermissionsThenListen();
    // Android's BLE scanner can stop reporting fresh advertisement updates
    // for a device it has already "seen" once, especially when that
    // device's payload changes (like when a friend picks a new question).
    // Periodically restarting the scan forces it to treat every device as
    // new again, so updated broadcasts get picked up reliably.
    _scanRestartTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _scanSubscription?.cancel();
      _startListening();
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanRestartTimer?.cancel();
    _resumeQuestionTimer?.cancel();
    _peripheral.stop();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsThenListen() async {
    // Android needs these granted at runtime, not just declared in the
    // manifest - toggling them manually in Settings doesn't always
    // register correctly, especially on some OEM Android skins.
    await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();
    _startListening();
  }

  void _startListening() {
    _scanSubscription = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      final data = device.manufacturerData;
      if (data.length < 4) return;
      if (data[0] != 0xFF || data[1] != 0xFF) return;

      print('DUO_DEBUG: saw broadcast type=0x${data[2].toRadixString(16)} '
          'incomingPairCode=${data[3]} myPairCode=${widget.pairCode} '
          'fullData=$data');

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
      }
    }, onError: (e) {
      print('DUO_DEBUG: SCAN ERROR: $e');
    });
  }

  Future<void> _pickQuestion(PartyQuestion question) async {
    setState(() {
      _myQuestion = question;
      _friendAnswer = null;
      _errorMessage = null;
    });
    await _startBroadcastingQuestion();
  }

  Future<void> _startBroadcastingQuestion() async {
    if (_myQuestion == null) return;
    try {
      final isSupported = await _peripheral.isSupported;
      if (!isSupported) {
        setState(() {
          _errorMessage = 'This device does not support BLE advertising.';
        });
        return;
      }

      await _peripheral.stop();
      // Small delay avoids a known Android BLE issue where restarting
      // advertising immediately after stopping it can silently fail.
      await Future.delayed(const Duration(milliseconds: 300));

      // 0xA1 marks this as a QUESTION broadcast. Byte layout:
      // [0xA1, pairCode, questionId]
      final manufacturerData = Uint8List.fromList(
          [0xA1, widget.pairCode & 0xFF, _myQuestion!.id & 0xFF]);

      final advertiseData = AdvertiseData(
        serviceUuid: '0000DDDD-0000-1000-8000-00805F9B34FB',
        manufacturerId: 0xFFFF,
        manufacturerData: manufacturerData,
      );

      await _peripheral.start(
        advertiseData: advertiseData,
        advertiseSettings: AdvertiseSettings(connectable: true),
      );

      if (!mounted) return;
      setState(() {
        _isBroadcastingQuestion = true;
        _isBroadcastingAnswer = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to broadcast question: $e';
      });
    }
  }

  Future<void> _sendReply() async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) {
      setState(() {
        _errorMessage = 'Please type an answer first.';
      });
      return;
    }

    try {
      final isSupported = await _peripheral.isSupported;
      if (!isSupported) {
        setState(() {
          _errorMessage = 'This device does not support BLE advertising.';
        });
        return;
      }

      await _peripheral.stop();
      await Future.delayed(const Duration(milliseconds: 300));

      final truncated = replyText.length > _maxAnswerLength
          ? replyText.substring(0, _maxAnswerLength)
          : replyText;

      // 0xA2 marks this as an ANSWER broadcast. Byte layout:
      // [0xA2, pairCode, ...answerBytes]
      final answerBytes = utf8.encode(truncated);
      final manufacturerData =
          Uint8List.fromList([0xA2, widget.pairCode & 0xFF, ...answerBytes]);

      final advertiseData = AdvertiseData(
        manufacturerId: 0xFFFF,
        manufacturerData: manufacturerData,
      );

      await _peripheral.start(
        advertiseData: advertiseData,
        advertiseSettings: AdvertiseSettings(connectable: false),
      );

      if (!mounted) return;
      setState(() {
        _isBroadcastingAnswer = true;
        _isBroadcastingQuestion = false;
        _replySent = true;
        _errorMessage = null;
      });

      // After a few seconds, automatically go back to broadcasting our own
      // question (if we have one selected) - phones can only advertise one
      // thing at a time, so this is how we "take turns" without the user
      // having to manually switch anything.
      _resumeQuestionTimer?.cancel();
      _resumeQuestionTimer = Timer(const Duration(seconds: 6), () {
        if (!mounted) return;
        if (_myQuestion != null) {
          _startBroadcastingQuestion();
        } else {
          _peripheral.stop();
          setState(() {
            _isBroadcastingAnswer = false;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to send answer: $e';
      });
    }
  }

  void _showQuestionPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: partyQuestions.length,
            itemBuilder: (context, index) {
              final q = partyQuestions[index];
              return ListTile(
                leading: const Icon(Icons.help_outline_rounded,
                    color: AppColors.primary),
                title: Text(q.question),
                subtitle: Text(q.hint),
                onTap: () {
                  Navigator.pop(context);
                  _pickQuestion(q);
                },
              );
            },
          ),
        );
      },
    );
  }

  String get _broadcastStatusLabel {
    if (_isBroadcastingAnswer) return 'Sending your answer...';
    if (_isBroadcastingQuestion) return 'Broadcasting your question...';
    return 'Not broadcasting';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0.5,
        title: Text(
          'Ask & Answer  \u2022  Code ${widget.pairCode}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.appBarText,
            letterSpacing: -0.5,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- My question section ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Question',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_myQuestion == null)
                    Text(
                      'Pick a question to start broadcasting it.',
                      style: const TextStyle(color: AppColors.mutedText),
                    )
                  else
                    Text(
                      _myQuestion!.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.appBarText,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (_myQuestion != null)
                    Row(
                      children: [
                        Icon(
                          _isBroadcastingQuestion
                              ? Icons.bluetooth_audio_rounded
                              : Icons.bluetooth_rounded,
                          size: 14,
                          color: _isBroadcastingQuestion
                              ? AppColors.accent
                              : AppColors.mutedText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _broadcastStatusLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  if (_friendAnswer != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Friend's answer:",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _friendAnswer!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.appBarText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _showQuestionPicker,
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: Text(
                      _myQuestion == null ? 'Pick a Question' : 'Change Question',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- Friend's question section ---
            if (_friendQuestion != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Friend's Question",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _friendQuestion!.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.appBarText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 14,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _friendQuestion!.hint,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_replySent) ...[
                      TextField(
                        controller: _replyController,
                        maxLength: _maxAnswerLength,
                        decoration: const InputDecoration(
                          labelText: 'Your reply',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _sendReply,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Send Reply'),
                      ),
                    ] else
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Sent: ${_replyController.text.trim()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.appBarText,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "Waiting for your friend's question...",
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                ),
              ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
