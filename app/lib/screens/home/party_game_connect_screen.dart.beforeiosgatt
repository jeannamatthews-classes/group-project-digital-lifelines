import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:typed_data';

import '../../theme/app_theme.dart';
import '../../data/party_questions.dart';
import 'party_game_answer_screen.dart';

class PartyGameConnectScreen extends StatefulWidget {
  const PartyGameConnectScreen({super.key});

  @override
  State<PartyGameConnectScreen> createState() =>
      _PartyGameConnectScreenState();
}

class _PartyGameConnectScreenState extends State<PartyGameConnectScreen> {
  // iOS native channel
  static const _channel = MethodChannel('digital_lifelines/ble_scanner');

  // Android BLE scanner
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  static final Uuid _serviceUuid =
      Uuid.parse('0000dddd-0000-1000-8000-00805f9b34fb');

  bool _isScanning = false;
  final Map<String, Map<String, dynamic>> _foundDevices = {};

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    if (Platform.isIOS) {
      _channel.invokeMethod('stopScan');
    }
    super.dispose();
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'deviceFound') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      final id = data['id'] as String;
      if (!mounted) return;
      setState(() {
        _foundDevices[id] = data;
      });
    }
  }

  // Manufacturer data layout we broadcast: [0xFF, 0xFF, 0xA1, questionId]
  int? _parseQuestionId(Uint8List data) {
    if (data.length < 4) return null;
    if (data[0] != 0xFF || data[1] != 0xFF) return null;
    if (data[2] != 0xA1) return null;
    return data[3];
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    if (Platform.isIOS) {
      _channel.invokeMethod('startScan');
    } else {
      _scanSubscription = _ble.scanForDevices(
        withServices: [_serviceUuid],
        scanMode: ScanMode.lowLatency,
      ).listen((device) {
        final questionId = _parseQuestionId(device.manufacturerData);
        if (!mounted) return;
        setState(() {
          _foundDevices[device.id] = {
            'id': device.id,
            'name': device.name,
            'rssi': device.rssi,
            'questionId': questionId,
          };
        });
      }, onError: (e) {
        // ignore scan errors
      });
    }
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    if (Platform.isIOS) {
      _channel.invokeMethod('stopScan');
    }
    setState(() {
      _isScanning = false;
    });
  }

  void _connectToDevice(Map<String, dynamic> device) {
    _stopScan();
    final questionId = device['questionId'] as int?;
    final question =
        questionId != null ? findPartyQuestionById(questionId) : null;

    if (question != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PartyGameAnswerScreen(question: question),
        ),
      );
    } else {
      final name = (device['name'] as String?) ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to: $name (no question id found)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = _foundDevices.values.toList();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Find a Player',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.appBarText,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? _stopScan : _startScan,
                icon: Icon(
                  _isScanning
                      ? Icons.stop_circle_rounded
                      : Icons.bluetooth_searching_rounded,
                ),
                label: Text(_isScanning ? 'Stop Scanning' : 'Scan for Nearby Phones'),
              ),
            ),
            const SizedBox(height: 16),
            if (_isScanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning
                            ? 'Looking for nearby phones...'
                            : 'No devices found yet.\nTap "Scan" to start.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final questionId = device['questionId'] as int?;
                        final name = questionId != null
                            ? 'Question #$questionId'
                            : ((device['name'] as String?)?.isNotEmpty == true
                                ? device['name'] as String
                                : '(unnamed)');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(
                              Icons.smartphone_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(name),
                            subtitle: Text('Signal: ${device['rssi']} dBm'),
                            trailing: ElevatedButton(
                              onPressed: () => _connectToDevice(device),
                              child: const Text('Connect'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
