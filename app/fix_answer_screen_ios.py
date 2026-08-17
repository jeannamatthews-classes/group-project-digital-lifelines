path = 'lib/screens/home/party_game_answer_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

old_imports = """import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

import '../../theme/app_theme.dart';
import '../../data/party_questions.dart';"""
new_imports = """import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

import '../../theme/app_theme.dart';
import '../../data/party_questions.dart';"""
if old_imports not in content:
    print("ERROR: imports block not found")
else:
    content = content.replace(old_imports, new_imports)
    print("Updated imports")

old_class = """class PartyGameAnswerScreen extends StatefulWidget {
  final PartyQuestion question;

  const PartyGameAnswerScreen({
    super.key,
    required this.question,
  });

  @override
  State<PartyGameAnswerScreen> createState() => _PartyGameAnswerScreenState();
}"""
new_class = """class PartyGameAnswerScreen extends StatefulWidget {
  final PartyQuestion question;
  final String? iosDeviceId;

  const PartyGameAnswerScreen({
    super.key,
    required this.question,
    this.iosDeviceId,
  });

  @override
  State<PartyGameAnswerScreen> createState() => _PartyGameAnswerScreenState();
}"""
if old_class not in content:
    print("ERROR: class block not found")
else:
    content = content.replace(old_class, new_class)
    print("Added iosDeviceId parameter")

old_state_top = """class _PartyGameAnswerScreenState extends State<PartyGameAnswerScreen> {
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
  }"""
new_state_top = """class _PartyGameAnswerScreenState extends State<PartyGameAnswerScreen> {
  static const int _maxAnswerLength = 20;
  static const _channel = MethodChannel('digital_lifelines/ble_scanner');

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  final TextEditingController _answerController = TextEditingController();

  bool _isBroadcasting = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS && widget.iosDeviceId != null) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (!mounted) return;
    if (call.method == 'answerSent') {
      setState(() {
        _isBroadcasting = false;
        _sent = true;
      });
    } else if (call.method == 'answerSendFailed') {
      setState(() {
        _isBroadcasting = false;
        _errorMessage = 'Failed to send answer. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _peripheral.stop();
    _answerController.dispose();
    super.dispose();
  }"""
if old_state_top not in content:
    print("ERROR: state class top block not found")
else:
    content = content.replace(old_state_top, new_state_top)
    print("Added iOS method call handler")

old_send = """  Future<void> _sendAnswer() async {
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

    try {"""
new_send = """  Future<void> _sendAnswer() async {
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

    if (Platform.isIOS && widget.iosDeviceId != null) {
      final truncated = answerText.length > _maxAnswerLength
          ? answerText.substring(0, _maxAnswerLength)
          : answerText;
      await _channel.invokeMethod('sendAnswer', {
        'deviceId': widget.iosDeviceId,
        'answer': truncated,
      });
      // UI updates when 'answerSent'/'answerSendFailed' comes back via
      // _handleMethodCall above.
      return;
    }

    try {"""
if old_send not in content:
    print("ERROR: _sendAnswer start block not found")
else:
    content = content.replace(old_send, new_send)
    print("Added iOS branch to _sendAnswer")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
