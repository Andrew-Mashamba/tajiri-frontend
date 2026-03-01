// Phase 4: Leave voice message after missed call. POST /api/calls/{id}/missed-call-voice-message.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/call_signaling_service.dart';

class MissedCallVoiceScreen extends StatefulWidget {
  final String callId;
  final int currentUserId;
  final String? authToken;
  final String? otherUserName;

  const MissedCallVoiceScreen({
    super.key,
    required this.callId,
    required this.currentUserId,
    this.authToken,
    this.otherUserName,
  });

  @override
  State<MissedCallVoiceScreen> createState() => _MissedCallVoiceScreenState();
}

class _MissedCallVoiceScreenState extends State<MissedCallVoiceScreen> {
  final CallSignalingService _signaling = CallSignalingService();
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  int _durationSec = 0;
  String? _recordedPath;
  bool _sending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_recorder == null) return;
    try {
      final dir = await getTemporaryDirectory();
      _recordedPath = '${dir.path}/missed_call_voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder!.openRecorder();
      await _recorder!.startRecorder(
        toFile: _recordedPath,
        codec: Codec.aacADTS,
      );
      if (mounted) {
        setState(() {
          _isRecording = true;
          _durationSec = 0;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _durationSec += 1);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    if (_recorder == null || !_isRecording) return;
    try {
      await _recorder!.stopRecorder();
      await _recorder!.closeRecorder();
    } catch (_) {}
    if (mounted) setState(() => _isRecording = false);
  }

  Future<void> _sendVoiceMessage() async {
    if (_recordedPath == null) return;
    final file = File(_recordedPath!);
    if (!await file.exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording file not found')));
      return;
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;
    setState(() => _sending = true);
    final resp = await _signaling.postMissedCallVoiceMessage(
      callId: widget.callId,
      voiceFileBytes: bytes,
      fileName: 'voice.aac',
      durationSeconds: _durationSec,
      authToken: widget.authToken,
      userId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice message sent')));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.message ?? 'Failed to send')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.otherUserName ?? 'User';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave voice message'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'After missed call to $name',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isRecording) ...[
                Text(
                  '$_durationSec s',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ] else if (_recordedPath != null) ...[
                Text(
                  '$_durationSec s recorded',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _sending ? null : () => setState(() => _recordedPath = null),
                      child: const Text('Record again'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _sending ? null : _sendVoiceMessage,
                      child: _sending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send'),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _sending ? null : _startRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text('Record voice message'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
