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
  Timer? _pulseTimer;
  bool _pulseVisible = true;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseTimer?.cancel();
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
          _pulseVisible = true;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _durationSec += 1);
        });
        _pulseTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
          if (mounted) setState(() => _pulseVisible = !_pulseVisible);
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
    _pulseTimer?.cancel();
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

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.otherUserName ?? 'User';
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Leave voice message',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording)
                _buildRecordingState()
              else if (_recordedPath != null)
                _buildRecordedState()
              else
                _buildInitialState(name),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState(String name) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'After missed call to $name',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: 80,
          height: 80,
          child: Material(
            color: const Color(0xFF1A1A1A),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _sending ? null : _startRecording,
              customBorder: const CircleBorder(),
              child: const Center(
                child: Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap to record',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing red dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: _pulseVisible ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 400),
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFD32F2F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Recording...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Duration display
        Text(
          _formatDuration(_durationSec),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 48),
        // Stop button
        SizedBox(
          width: 64,
          height: 64,
          child: Material(
            color: const Color(0xFF1A1A1A),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _stopRecording,
              customBorder: const CircleBorder(),
              child: const Center(
                child: Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordedState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_durationSec seconds recorded',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Record again button — outlined style
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _sending
                    ? null
                    : () => setState(() => _recordedPath = null),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF1A1A1A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: const Text(
                  'Record again',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Send button — filled style
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _sendVoiceMessage,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF1A1A1A),
                  disabledBackgroundColor: const Color(0xFF1A1A1A).withAlpha(128),
                  disabledForegroundColor: Colors.white.withAlpha(128),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: const Text(
                  'Send',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
