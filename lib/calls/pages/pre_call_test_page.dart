import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../../services/http_retry.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/api_config.dart';
import '../../consultations/services/consultation_service.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 731 — pre-call mic / camera / bandwidth self-test.
/// Persists results in consultations.connectivity_test_passed.
class PreCallTestPage extends StatefulWidget {
  final int consultationId;
  final int userId;

  const PreCallTestPage({
    super.key,
    required this.consultationId,
    required this.userId,
  });

  @override
  State<PreCallTestPage> createState() => _PreCallTestPageState();
}

enum _TestState { idle, running, passed, failed }

class _PreCallTestPageState extends State<PreCallTestPage> {
  // Mic
  FlutterSoundRecorder? _recorder;
  AudioPlayer? _player;
  String? _recordPath;
  _TestState _micState = _TestState.idle;
  int _recordSec = 0;
  Timer? _recordTimer;

  // Camera
  CameraController? _camCtrl;
  List<CameraDescription> _cameras = [];
  _TestState _camState = _TestState.idle;
  XFile? _snapshot;

  // Bandwidth
  _TestState _bwState = _TestState.idle;
  double _bwKbps = 0;

  bool _saving = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  bool get _allPassed =>
      _micState == _TestState.passed &&
      _camState == _TestState.passed &&
      _bwState == _TestState.passed;

  bool get _anyFailed =>
      _micState == _TestState.failed ||
      _camState == _TestState.failed ||
      _bwState == _TestState.failed;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder?.closeRecorder();
    _player?.dispose();
    _camCtrl?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty && mounted) {
        _camCtrl = CameraController(
          _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras.first,
          ),
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _camCtrl!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('[PreCallTest] camera init error: $e');
    }
  }

  Future<void> _testMic() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      setState(() => _micState = _TestState.failed);
      return;
    }
    setState(() {
      _micState = _TestState.running;
      _recordSec = 0;
    });
    try {
      _recorder ??= FlutterSoundRecorder();
      final dir = await getTemporaryDirectory();
      _recordPath =
          '${dir.path}/pre_call_test_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder!.openRecorder();
      await _recorder!.startRecorder(
        toFile: _recordPath,
        codec: Codec.aacADTS,
      );
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordSec++);
        if (_recordSec >= 3) _stopRecording();
      });
    } catch (e) {
      debugPrint('[PreCallTest] record error: $e');
      if (mounted) setState(() => _micState = _TestState.failed);
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    try {
      await _recorder?.stopRecorder();
      await _recorder?.closeRecorder();
    } catch (e) {
      debugPrint('[PreCallTest] stop error: $e');
    }
    if (!mounted) return;
    setState(() => _micState = _TestState.passed);
    _playBack();
  }

  Future<void> _playBack() async {
    if (_recordPath == null) return;
    try {
      _player ??= AudioPlayer();
      await _player!.play(DeviceFileSource(_recordPath!));
    } catch (e) {
      debugPrint('[PreCallTest] playback error: $e');
    }
  }

  Future<void> _testCamera() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) {
      setState(() => _camState = _TestState.failed);
      return;
    }
    setState(() => _camState = _TestState.running);
    try {
      final file = await _camCtrl!.takePicture();
      if (mounted) {
        setState(() {
          _snapshot = file;
          _camState = _TestState.passed;
        });
      }
    } catch (e) {
      debugPrint('[PreCallTest] camera error: $e');
      if (mounted) setState(() => _camState = _TestState.failed);
    }
  }

  Future<void> _testBandwidth() async {
    setState(() => _bwState = _TestState.running);
    try {
      // Download a small test asset to measure throughput.
      final testUrl =
          '${ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '')}/favicon.png?cb=${Random().nextInt(999999)}';
      final start = DateTime.now();
      final res = await httpGetWithRetry(Uri.parse(testUrl)).timeout(
        const Duration(seconds: 15),
      );
      final elapsedMs = DateTime.now().difference(start).inMilliseconds;
      if (elapsedMs <= 0) {
        setState(() => _bwState = _TestState.failed);
        return;
      }
      final bytes = res.bodyBytes.length;
      final kbps = (bytes * 8) / (elapsedMs / 1000) / 1024;
      _bwKbps = kbps;
      // Threshold: 128 kbps minimum for usable video
      if (mounted) {
        setState(
            () => _bwState = kbps >= 128 ? _TestState.passed : _TestState.failed);
      }
    } catch (e) {
      debugPrint('[PreCallTest] bw error: $e');
      if (mounted) setState(() => _bwState = _TestState.failed);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final passed = _allPassed;
    final res = await ConsultationService.submitConnectivityTest(
      id: widget.consultationId,
      userId: widget.userId,
      passed: passed,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Imehifadhiwa' : 'Saved'),
      ));
      Navigator.pop(context, passed);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          isSw ? 'Kagua kifaa' : 'Pre-call test',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _testCard(
            title: isSw ? 'Kipaza sauti' : 'Microphone',
            subtitle: isSw
                ? 'Rekodi sauti ya sekunde 3 kisha isikilize'
                : 'Record 3 seconds then play it back',
            icon: Icons.mic_rounded,
            state: _micState,
            onRun: _testMic,
            child: _micState == _TestState.running
                ? Text(
                    '${3 - _recordSec}s',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary,
                    ),
                  )
                : _micState == _TestState.passed
                    ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF1B5E20), size: 32)
                    : null,
          ),
          const SizedBox(height: 12),
          _testCard(
            title: isSw ? 'Kamera' : 'Camera',
            subtitle: isSw
                ? 'Hakikisha kuona picha yako vizuri'
                : 'Make sure you can see yourself clearly',
            icon: Icons.videocam_rounded,
            state: _camState,
            onRun: _testCamera,
            child: _camCtrl != null && _camCtrl!.value.isInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 160,
                      color: Colors.black,
                      child: _snapshot != null
                          ? Image.file(
                              File(_snapshot!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : CameraPreview(_camCtrl!),
                    ),
                  )
                : const Icon(Icons.videocam_off_rounded,
                    color: _kSecondary, size: 32),
          ),
          const SizedBox(height: 12),
          _testCard(
            title: isSw ? 'Kasi ya mtandao' : 'Bandwidth',
            subtitle: isSw
                ? 'Kipimo cha kasi ya kupakua'
                : 'Download speed test',
            icon: Icons.network_check_rounded,
            state: _bwState,
            onRun: _testBandwidth,
            child: _bwState == _TestState.passed
                ? Text(
                    '${_bwKbps.toStringAsFixed(0)} kbps',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                    ),
                  )
                : _bwState == _TestState.failed
                    ? Text(
                        _bwKbps > 0
                            ? '${_bwKbps.toStringAsFixed(0)} kbps'
                            : (isSw ? 'Imeshindikana' : 'Failed'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB71C1C),
                        ),
                      )
                    : null,
          ),
          if (_anyFailed) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSw
                          ? 'Kuna tatizo la kiufundi. Usiendelee bila kurekebisha.'
                          : 'A technical issue was detected. Do not proceed without fixing it.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (_allPassed || _anyFailed) && !_saving ? _save : null,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(isSw ? 'Hifadhi matokeo' : 'Save results'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _allPassed
                    ? const Color(0xFF1B5E20)
                    : (_anyFailed ? const Color(0xFFB71C1C) : _kPrimary),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _testCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required _TestState state,
    required VoidCallback onRun,
    Widget? child,
  }) {
    final isSw = _isSwahili;
    final running = state == _TestState.running;
    final passed = state == _TestState.passed;
    final failed = state == _TestState.failed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: failed
              ? const Color(0xFFFFEBEE)
              : passed
                  ? const Color(0xFFE8F5E9)
                  : _kBorder,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: failed
                      ? const Color(0xFFFFEBEE)
                      : passed
                          ? const Color(0xFFE8F5E9)
                          : _kPrimary.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: failed
                      ? const Color(0xFFB71C1C)
                      : passed
                          ? const Color(0xFF1B5E20)
                          : _kPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!passed)
                TextButton(
                  onPressed: running ? null : onRun,
                  child: Text(
                    running
                        ? (isSw ? 'Inaendelea...' : 'Running...')
                        : (isSw ? 'Anza' : 'Run'),
                  ),
                ),
              if (passed)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF1B5E20)),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 10),
            Center(child: child),
          ],
        ],
      ),
    );
  }
}
