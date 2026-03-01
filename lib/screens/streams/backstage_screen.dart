/// Backstage screen - Streamer preparation room before going live
/// Final checks, camera preview, settings adjustment
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/livestream_models.dart';

class BackstageScreen extends StatefulWidget {
  final LiveStream stream;
  final VoidCallback? onGoLive;
  final VoidCallback? onCancel;

  const BackstageScreen({
    super.key,
    required this.stream,
    this.onGoLive,
    this.onCancel,
  });

  @override
  State<BackstageScreen> createState() => _BackstageScreenState();
}

class _BackstageScreenState extends State<BackstageScreen>
    with TickerProviderStateMixin {
  late AnimationController _readyPulseController;
  late Animation<double> _readyPulseAnimation;

  // System checks
  bool _cameraReady = false;
  bool _microphoneReady = false;
  bool _internetReady = false;
  bool _isCheckingSystem = true;

  // Camera/Mic toggles
  bool _cameraEnabled = true;
  bool _microphoneEnabled = true;

  // Stream settings
  String _quality = 'HD';
  bool _beautyMode = false;

  Timer? _systemCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _performSystemChecks();
  }

  void _initializeAnimations() {
    _readyPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _readyPulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _readyPulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _performSystemChecks() async {
    // Simulate system checks (replace with actual checks)
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _cameraReady = true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _microphoneReady = true);

    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _internetReady = true);

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isCheckingSystem = false);
  }

  bool get _allSystemsReady =>
      _cameraReady && _microphoneReady && _internetReady;

  @override
  void dispose() {
    _readyPulseController.dispose();
    _systemCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, s),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCameraPreview(s),
                    const SizedBox(height: 24),
                    _buildSystemChecks(s),
                    const SizedBox(height: 24),
                    _buildStreamSettings(s),
                    const SizedBox(height: 24),
                    _buildStreamInfoCard(s),
                  ],
                ),
              ),
            ),
            _buildBottomActions(s),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppStrings? s) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onCancel ?? () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Text(
                  (s?.backstageBadge ?? 'Backstage').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(AppStrings? s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade900,
        border: Border.all(
          color: _cameraReady ? Colors.green : Colors.grey.shade700,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _cameraReady
                ? Colors.green.withOpacity(0.3)
                : Colors.transparent,
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _cameraReady ? Icons.videocam : Icons.videocam_off,
                    size: 64,
                    color: _cameraReady ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _cameraReady
                        ? (s?.cameraReady ?? 'Camera ready')
                        : (s?.checkingCamera ?? 'Checking camera...'),
                    style: TextStyle(
                      color: _cameraReady ? Colors.green : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_cameraReady)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: _buildCameraControls(s),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraControls(AppStrings? s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.flip_camera_ios,
          label: s?.flipCamera ?? 'Flip',
          onTap: () {},
        ),
        const SizedBox(width: 16),
        _buildControlButton(
          icon: _cameraEnabled ? Icons.videocam : Icons.videocam_off,
          label: _cameraEnabled ? (s?.turnOff ?? 'Off') : (s?.turnOn ?? 'On'),
          isActive: _cameraEnabled,
          onTap: () {
            setState(() => _cameraEnabled = !_cameraEnabled);
          },
        ),
        const SizedBox(width: 16),
        _buildControlButton(
          icon: _microphoneEnabled ? Icons.mic : Icons.mic_off,
          label: _microphoneEnabled ? (s?.turnOff ?? 'Off') : (s?.turnOn ?? 'On'),
          isActive: _microphoneEnabled,
          onTap: () {
            setState(() => _microphoneEnabled = !_microphoneEnabled);
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.2)
              : Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.white.withOpacity(0.3) : Colors.red,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemChecks(AppStrings? s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s?.areYouReady ?? 'Are you ready?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildCheckItem(
            icon: Icons.videocam,
            label: s?.camera ?? 'Camera',
            isReady: _cameraReady,
            isChecking: _isCheckingSystem && !_cameraReady,
          ),
          const SizedBox(height: 12),
          _buildCheckItem(
            icon: Icons.mic,
            label: s?.microphone ?? 'Microphone',
            isReady: _microphoneReady,
            isChecking: _isCheckingSystem && !_microphoneReady,
          ),
          const SizedBox(height: 12),
          _buildCheckItem(
            icon: Icons.wifi,
            label: s?.network ?? 'Network',
            isReady: _internetReady,
            isChecking: _isCheckingSystem && !_internetReady,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required IconData icon,
    required String label,
    required bool isReady,
    required bool isChecking,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isReady ? Colors.green : Colors.grey,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isReady ? Colors.white : Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isChecking)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          )
        else if (isReady)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.green,
              size: 16,
            ),
          )
        else
          const Icon(
            Icons.close,
            color: Colors.red,
            size: 20,
          ),
      ],
    );
  }

  Widget _buildStreamSettings(AppStrings? s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s?.settings ?? 'Settings',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.hd, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                s?.quality ?? 'Quality',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'SD', label: Text('SD')),
                  ButtonSegment(value: 'HD', label: Text('HD')),
                  ButtonSegment(value: 'FHD', label: Text('FHD')),
                ],
                selected: {_quality},
                onSelectionChanged: (Set<String> selection) {
                  setState(() => _quality = selection.first);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return const Color(0xFF1E88E5);
                    }
                    return Colors.white.withOpacity(0.1);
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.face_retouching_natural,
                  color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s?.beautyMode ?? 'Beauty mode',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Switch(
                value: _beautyMode,
                onChanged: (value) {
                  setState(() => _beautyMode = value);
                },
                activeColor: const Color(0xFF1E88E5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreamInfoCard(AppStrings? s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5).withOpacity(0.2),
            const Color(0xFF1E88E5).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF1E88E5), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.stream.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (widget.stream.description != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.stream.description!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.stream.category != null)
                _buildInfoChip(
                    Icons.category, widget.stream.category!, Colors.orange),
              _buildInfoChip(
                  Icons.lock_outline,
                  widget.stream.privacy == 'public'
                      ? (s?.publicLabel ?? 'Public')
                      : (s?.privacy ?? 'Privacy'),
                  Colors.blue),
              if (widget.stream.isRecorded)
                _buildInfoChip(
                    Icons.fiber_manual_record,
                    s?.recording ?? 'Recording',
                    Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(AppStrings? s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_allSystemsReady)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s?.waitForSystemsReady ?? 'Wait for all systems to be ready...',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          AnimatedBuilder(
            animation: _readyPulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _allSystemsReady ? _readyPulseAnimation.value : 1.0,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _allSystemsReady
                        ? () {
                            widget.onGoLive?.call();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _allSystemsReady
                          ? Colors.red
                          : Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _allSystemsReady ? 12 : 0,
                      shadowColor: Colors.red.withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_filled, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          _allSystemsReady
                              ? (s?.goLiveButton ?? 'Go live').toUpperCase()
                              : (s?.waiting ?? 'Waiting...').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
