path = 'lib/screens/home/party_game_host_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_imports = """import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../theme/app_theme.dart';"""
new_imports = """import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../theme/app_theme.dart';"""
if old_imports not in content:
    print("ERROR: imports block not found")
else:
    content = content.replace(old_imports, new_imports)
    print("Updated imports")

old_top = """class _PartyGameHostScreenState extends State<PartyGameHostScreen> {
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
  }"""
new_top = """class _PartyGameHostScreenState extends State<PartyGameHostScreen> {
  static const _channel = MethodChannel('digital_lifelines/ble_scanner');

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _answerScanSubscription;

  bool _isAdvertising = false;
  String? _errorMessage;
  String? _receivedAnswer;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (!mounted) return;
    if (call.method == 'answerReceived') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      setState(() {
        _receivedAnswer = data['answer'] as String;
      });
    }
  }

  @override
  void dispose() {
    _peripheral.stop();
    _answerScanSubscription?.cancel();
    if (Platform.isIOS) {
      _channel.invokeMethod('stopHosting');
    }
    super.dispose();
  }"""
if old_top not in content:
    print("ERROR: state class top block not found")
else:
    content = content.replace(old_top, new_top)
    print("Added iOS method call handler")

old_start = """  Future<void> _startHosting() async {
    setState(() {
      _errorMessage = null;
      _receivedAnswer = null;
    });

    try {"""
new_start = """  Future<void> _startHosting() async {
    setState(() {
      _errorMessage = null;
      _receivedAnswer = null;
    });

    if (Platform.isIOS) {
      await _channel.invokeMethod('startHosting', {'questionId': widget.questionId});
      if (!mounted) return;
      setState(() {
        _isAdvertising = true;
      });
      return;
    }

    try {"""
if old_start not in content:
    print("ERROR: _startHosting block not found")
else:
    content = content.replace(old_start, new_start)
    print("Added iOS branch to _startHosting")

old_stop = """  Future<void> _stopHosting() async {
    await _peripheral.stop();
    _answerScanSubscription?.cancel();
    if (!mounted) return;
    setState(() {
      _isAdvertising = false;
    });
  }"""
new_stop = """  Future<void> _stopHosting() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod('stopHosting');
      if (!mounted) return;
      setState(() {
        _isAdvertising = false;
      });
      return;
    }
    await _peripheral.stop();
    _answerScanSubscription?.cancel();
    if (!mounted) return;
    setState(() {
      _isAdvertising = false;
    });
  }"""
if old_stop not in content:
    print("ERROR: _stopHosting block not found")
else:
    content = content.replace(old_stop, new_stop)
    print("Added iOS branch to _stopHosting")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
