import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  static final ClipboardService _instance = ClipboardService._internal();
  factory ClipboardService() => _instance;
  ClipboardService._internal();

  final StreamController<String> _clipboardController =
      StreamController<String>.broadcast();
  Timer? _clipboardTimer;
  String? _lastClipboardContent;

  Stream<String> get clipboardStream => _clipboardController.stream;

  void startMonitoring() {
    _clipboardTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkClipboard();
    });
  }

  void stopMonitoring() {
    _clipboardTimer?.cancel();
  }

  Future<void> _checkClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final content = clipboardData?.text;

      if (content != null && content != _lastClipboardContent) {
        _lastClipboardContent = content;
        _clipboardController.add(content);
      }
    } catch (e) {
      print('Error checking clipboard: $e');
    }
  }

  Future<String?> getClipboardContent() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text;
    } catch (e) {
      print('Error getting clipboard content: $e');
      return null;
    }
  }

  Future<void> setClipboardContent(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      _lastClipboardContent = content;
    } catch (e) {
      print('Error setting clipboard content: $e');
    }
  }

  void dispose() {
    stopMonitoring();
    _clipboardController.close();
  }
}
