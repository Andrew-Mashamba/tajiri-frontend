import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F7 #52 — Pre-call mic / camera / bandwidth test before video.
///
/// Runs three checks sequentially with simulated stubs (real implementations
/// would request actual permission probes via `permission_handler` and a quick
/// download of a 100KB blob to gauge throughput). Reports overall pass/fail
/// to backend so the consultation page can gate the join CTA.
class PreCallTestPage extends StatefulWidget {
  final int userId;
  final int consultationId;
  const PreCallTestPage({
    super.key,
    required this.userId,
    required this.consultationId,
  });

  @override
  State<PreCallTestPage> createState() => _PreCallTestPageState();
}

class _PreCallTestPageState extends State<PreCallTestPage> {
  bool? _micOk;
  bool? _cameraOk;
  int? _bandwidthKbps;
  bool _running = false;
  bool? _passed;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _micOk = null;
      _cameraOk = null;
      _bandwidthKbps = null;
      _passed = null;
    });

    final micStatus = await Permission.microphone.request();
    if (!mounted) return;
    setState(() => _micOk = micStatus.isGranted);

    final cameraStatus = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _cameraOk = cameraStatus.isGranted);

    // Simulated bandwidth probe (real implementation would download a 100 KB blob).
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _bandwidthKbps = 1024);

    final allOk = _micOk == true && _cameraOk == true;
    if (allOk) {
      final passed = await PreCallTestService.submit(
        userId: widget.userId,
        consultationId: widget.consultationId,
        micOk: _micOk!,
        cameraOk: _cameraOk!,
        bandwidthKbps: _bandwidthKbps,
      );
      if (!mounted) return;
      setState(() {
        _passed = passed;
        _running = false;
      });
    } else {
      setState(() {
        _passed = false;
        _running = false;
      });
    }
  }

  Widget _checkRow(String label, bool? ok, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF666666)),
      title: Text(label),
      trailing: ok == null
          ? const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(
              ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: ok ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Jaribio la simu' : 'Pre-call test'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isSw
                ? 'Tunajaribu mic, kamera, na intaneti yako kabla ya simu.'
                : 'We test your mic, camera, and bandwidth before the call.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                if (_running || _micOk != null)
                  _checkRow(isSw ? 'Mic' : 'Microphone', _micOk, Icons.mic_rounded),
                if (_running || _cameraOk != null)
                  _checkRow(
                      isSw ? 'Kamera' : 'Camera', _cameraOk, Icons.videocam_rounded),
                if (_running || _bandwidthKbps != null)
                  ListTile(
                    leading: const Icon(Icons.network_check_rounded,
                        color: Color(0xFF666666)),
                    title: Text(isSw ? 'Intaneti' : 'Bandwidth'),
                    subtitle: Text(
                      isSw ? '(Kigezo)' : '(Simulated)',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                    ),
                    trailing: _bandwidthKbps == null
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('$_bandwidthKbps kbps',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_passed != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _passed!
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _passed!
                    ? (isSw
                        ? 'Vifaa vyako viko sawa. Unaweza kujiunga na simu.'
                        : 'You\'re ready to join the call.')
                    : (isSw
                        ? 'Tatizo limegunduliwa — angalia mic / kamera / intaneti.'
                        : 'A problem was detected — check mic / camera / network.'),
                style: TextStyle(
                  color: _passed!
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFFB71C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A)),
              onPressed: _running ? null : _run,
              child: Text(_running
                  ? (isSw ? 'Inajaribu…' : 'Testing…')
                  : (isSw ? 'Anza jaribio' : 'Start test')),
            ),
          ),
        ],
      ),
    );
  }
}
