import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../theme/app_theme.dart';

class PartyGameHostScreen extends StatefulWidget {
  final int questionId;
  final String questionText;

  const PartyGameHostScreen({
    super.key,
    required this.questionId,
    required this.questionText,
  });

  @override
  State<PartyGameHostScreen> createState() => _PartyGameHostScreenState();
}

class _PartyGameHostScreenState extends State<PartyGameHostScreen> {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _answerScanSubscription;

  bool _isAdvertising = false;
  String? _errorMessage;
  String? _receivedAnswer;

  @override
  void dispose() {
    _peripheral.stop();
    _answerScanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startHosting() async {
    setState(() {
      _errorMessage = null;
      _receivedAnswer = null;
    });

    try {
      final isSupported = await _peripheral.isSupported;
      if (!isSupported) {
        setState(() {
          _errorMessage = 'This device does not support BLE advertising.';
        });
        return;
      }

      // Encode the question id into manufacturer data. Local name is
      // unreliable on Android (esp. Redmi/Xiaomi), so we avoid it.
      // 0xA1 marks this as a QUESTION broadcast (vs 0xA2 for answers).
      final manufacturerData = Uint8List.fromList([0xA1, widget.questionId & 0xFF]);

      final advertiseData = AdvertiseData(
        serviceUuid: '0000DDDD-0000-1000-8000-00805F9B34FB',
        manufacturerId: 0xFFFF,
        manufacturerData: manufacturerData,
      );

      final advertiseSettings = AdvertiseSettings(
        connectable: true,
      );

      await _peripheral.start(
        advertiseData: advertiseData,
        advertiseSettings: advertiseSettings,
      );

      if (!mounted) return;
      setState(() {
        _isAdvertising = true;
      });

      _startListeningForAnswer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to start advertising: $e';
      });
    }
  }

  void _startListeningForAnswer() {
    // The joiner broadcasts their answer as manufacturer data with the same
    // 0xFFFF marker prefix, but with no service UUID (to save advertising
    // payload space for the actual answer text). We scan broadly and check
    // the manufacturer data prefix ourselves rather than filtering by service.
    _answerScanSubscription?.cancel();
    _answerScanSubscription = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      final data = device.manufacturerData;
      if (data.length < 3) return;
      if (data[0] != 0xFF || data[1] != 0xFF) return;

      // 0xA2 marks this as an ANSWER broadcast - check the marker byte,
      // not the payload length (a 1-character answer is still valid!).
      if (data[2] != 0xA2) return;
      final payload = data.sublist(3);
      if (payload.isEmpty) return;

      final answerText = utf8.decode(payload, allowMalformed: true);
      if (!mounted) return;
      setState(() {
        _receivedAnswer = answerText;
      });
    }, onError: (e) {
      // ignore scan errors here; advertising still works independently
    });
  }

  Future<void> _stopHosting() async {
    await _peripheral.stop();
    _answerScanSubscription?.cancel();
    if (!mounted) return;
    setState(() {
      _isAdvertising = false;
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
          'Hosting Question',
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
                    widget.questionText,
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
            const SizedBox(height: 32),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isAdvertising
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : Colors.grey.shade100,
              ),
              child: Icon(
                _isAdvertising
                    ? Icons.bluetooth_audio_rounded
                    : Icons.bluetooth_rounded,
                size: 56,
                color: _isAdvertising ? AppColors.accent : AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isAdvertising
                  ? 'Broadcasting... ask your friend to scan!'
                  : 'Tap below to start broadcasting this question',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (_receivedAnswer != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Friend\'s answer:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _receivedAnswer!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.appBarText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAdvertising ? _stopHosting : _startHosting,
                icon: Icon(
                  _isAdvertising
                      ? Icons.stop_circle_rounded
                      : Icons.broadcast_on_personal_rounded,
                ),
                label: Text(
                  _isAdvertising ? 'Stop Broadcasting' : 'Start Broadcasting',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
