import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../services/auth_service.dart';
import '../../../services/biometric_auth_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/security_service.dart';
import 'pin_change_screen.dart';
import '_security_widgets.dart';

/// Two-factor authentication + biometric login.
///
/// Scope: ONLY 2FA setup/disable/recovery codes and biometric login
/// (with related auto-lock timeout). PIN management lives on the
/// dedicated Change PIN screen — a notice on this screen links there.
class TwoFactorBiometricScreen extends StatefulWidget {
  final int currentUserId;
  const TwoFactorBiometricScreen({super.key, required this.currentUserId});

  @override
  State<TwoFactorBiometricScreen> createState() => _TwoFactorBiometricScreenState();
}

class _TwoFactorBiometricScreenState extends State<TwoFactorBiometricScreen> {
  final SecurityService _service = SecurityService();
  final BiometricAuthService _bio = BiometricAuthService.instance;
  final TextEditingController _codeController = TextEditingController();

  bool _loading = true;
  bool _processing = false;
  String? _error;
  String? _success;

  // 2FA state
  bool _twoFAEnabled = false;
  String? _qrUrl;
  List<String> _recoveryCodes = const [];
  bool _setupMode = false; // showing the QR + verify form

  // Biometric / auto-lock state.
  // _biometricAvailability captures the *capability* (no sensor / not
  // enrolled / weak only / available); _biometricEnabled is whether the
  // user has actually armed quick-login on this device.
  BiometricAvailability _biometricAvailability = BiometricAvailability.notSupported;
  BiometricKind _biometricKind = BiometricKind.generic;
  bool _biometricEnabled = false;
  bool _hasPin = false;
  int _timeoutSeconds = 300;

  static const _timeoutPresets = [0, 60, 300, 900];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    final results = await Future.wait([
      _service.check2FAStatus(widget.currentUserId),
      _service.checkAppLockStatus(widget.currentUserId),
      _bio.checkAvailability(),
      _bio.kind(),
      AuthService.instance.hasBiometricLogin(),
    ]);
    if (!mounted) return;
    final twoFA = results[0] as ({bool success, bool enabled, String? error});
    final lock = results[1] as ({bool success, bool hasPin, bool biometricEnabled, int timeout, String? error});
    final avail = results[2] as BiometricAvailability;
    final kind = results[3] as BiometricKind;
    final actuallyEnrolled = results[4] as bool;
    setState(() {
      _loading = false;
      _twoFAEnabled = twoFA.enabled;
      _hasPin = lock.hasPin;
      _timeoutSeconds = lock.timeout;
      _biometricAvailability = avail;
      _biometricKind = kind;
      // The toggle reflects whether quick-login is actually armed
      // (i.e. an encrypted token exists), not just whether the backend
      // flag is set. The backend flag stays in sync.
      _biometricEnabled = actuallyEnrolled;
    });
  }

  // ── 2FA actions ───────────────────────────────────────────────────────────

  Future<void> _enable2FA() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _processing = true;
      _error = null;
      _success = null;
    });
    final r = await _service.enable2FA(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _processing = false;
      if (r.success) {
        _qrUrl = r.qrUrl;
        _recoveryCodes = r.recoveryCodes;
        _setupMode = true;
      } else {
        _error = r.error;
      }
    });
  }

  Future<void> _confirm2FA() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    final s = AppStringsScope.of(context);
    final r = await _service.confirm2FA(widget.currentUserId, code);
    if (!mounted) return;
    setState(() {
      _processing = false;
      if (r.success) {
        _twoFAEnabled = true;
        _setupMode = false;
        _qrUrl = null;
        _codeController.clear();
        _success = s?.twoFAEnabledSuccess ?? '2FA enabled';
      } else {
        _error = r.error;
      }
    });
  }

  Future<void> _disable2FA() async {
    final s = AppStringsScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.disable2FAConfirmTitle ?? 'Disable 2FA'),
        content: Semantics(
          liveRegion: true,
          child: Text(s?.disable2FAConfirmMessage ?? 'Are you sure?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s?.disable2FA ?? 'Disable',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    final r = await _service.disable2FA(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _processing = false;
      if (r.success) {
        _twoFAEnabled = false;
        _recoveryCodes = const [];
        _qrUrl = null;
        _success = s?.twoFADisabledSuccess ?? '2FA disabled';
      } else {
        _error = r.error;
      }
    });
  }

  Future<void> _regenerateCodes() async {
    final s = AppStringsScope.of(context);
    setState(() {
      _processing = true;
      _error = null;
    });
    final r = await _service.regenerateRecoveryCodes(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _processing = false;
      if (r.success) {
        _recoveryCodes = r.codes;
        _success = s?.recoveryCodesCopied ?? 'Recovery codes regenerated';
      } else {
        _error = r.error;
      }
    });
  }

  void _copyRecoveryCodes() {
    Clipboard.setData(ClipboardData(text: _recoveryCodes.join('\n')));
    final s = AppStringsScope.of(context);
    setState(() => _success = s?.recoveryCodesCopied ?? 'Copied');
  }

  // ── Biometric / timeout ───────────────────────────────────────────────────

  Future<void> _toggleBiometric(bool value) async {
    final s = AppStringsScope.of(context);
    if (!_hasPin) {
      setState(() => _error = s?.usalamaBiometricRequiresPin ??
          'Set a PIN before enabling biometric unlock.');
      return;
    }
    if (_biometricAvailability != BiometricAvailability.available) {
      // Shouldn't be tappable in this state; defensive.
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _processing = true;
      _error = null;
      _success = null;
    });

    if (value) {
      // Enrolling: ask the user to type their current PIN. We forward
      // it to the server's /api/auth/biometric-enroll endpoint, which
      // verifies it before storing the public key — the same PIN that
      // gates the user's account is what authorizes biometric
      // enrollment.
      final pin = await _confirmPinDialog(s);
      if (pin == null) {
        setState(() => _processing = false);
        return;
      }

      final enrolled = await AuthService.instance.enrollBiometric(
        userId: widget.currentUserId,
        pin: pin,
        // device_name shows up on the Sessions / Activity screens.
        deviceName: 'TAJIRI mobile',
      );
      if (!enrolled.success || !mounted) {
        setState(() {
          _processing = false;
          _error = enrolled.error ??
              s?.usalamaBiometricEnableFailed ??
              'Could not enable biometric unlock. Please try again.';
        });
        return;
      }
      // Mirror the flag onto the legacy app-lock settings so older
      // surfaces that read it stay consistent.
      final r = await _service.updateAppLockSettings(
        widget.currentUserId,
        biometricEnabled: true,
      );
      if (!mounted) return;
      if (!r.success) {
        await AuthService.instance.revokeBiometric(userId: widget.currentUserId);
        setState(() {
          _processing = false;
          _error = r.error;
        });
        return;
      }
      final storage = await LocalStorageService.getInstance();
      await storage.setAppLockBiometric(true);
      setState(() {
        _processing = false;
        _biometricEnabled = true;
        _success = s?.usalamaBiometricEnabledSuccess ?? 'Biometric unlock enabled';
      });
    } else {
      // Disabling: revoke server-side AND wipe the local key + mirror
      // the legacy flag.
      await AuthService.instance.revokeBiometric(userId: widget.currentUserId);
      final r = await _service.updateAppLockSettings(
        widget.currentUserId,
        biometricEnabled: false,
      );
      if (!mounted) return;
      if (!r.success) {
        setState(() {
          _processing = false;
          _error = r.error;
        });
        return;
      }
      final storage = await LocalStorageService.getInstance();
      await storage.setAppLockBiometric(false);
      setState(() {
        _processing = false;
        _biometricEnabled = false;
        _success = s?.usalamaBiometricDisabledSuccess ?? 'Biometric unlock disabled';
      });
    }
  }

  /// Shows a 4-digit PIN entry dialog and verifies it via the backend
  /// (POST /api/security/pin/verify, exposed on AppLockController).
  /// Returns the verified PIN on success, null on cancel/failure.
  /// We return the raw PIN so the caller can forward it to
  /// /api/auth/biometric-enroll without re-prompting.
  Future<String?> _confirmPinDialog(dynamic s) async {
    final ctrl = TextEditingController();
    bool verifying = false;
    String? localError;
    String? result;

    await showDialog<void>(
      context: context,
      barrierDismissible: !verifying,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(s?.usalamaBiometricEnableTitle ?? 'Enable biometric unlock?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  s?.usalamaBiometricEnablePromptPin ??
                      'Enter your current PIN to confirm',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, letterSpacing: 8),
                // The Verify button's enabled state depends on ctrl.text.length.
                // Without an onChanged that calls setLocal, the dialog never
                // rebuilds after typing and the button stays grey.
                onChanged: (_) => setLocal(() {}),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorText: localError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: verifying ? null : () => Navigator.pop(ctx),
              child: Text(s?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: verifying || ctrl.text.length != 4
                  ? null
                  : () async {
                      setLocal(() {
                        verifying = true;
                        localError = null;
                      });
                      final r = await _service.verifyAppLockPin(
                        widget.currentUserId,
                        ctrl.text,
                      );
                      if (!ctx.mounted) return;
                      if (r.success) {
                        result = ctrl.text;
                        Navigator.pop(ctx);
                      } else {
                        setLocal(() {
                          verifying = false;
                          localError = r.error ?? 'Incorrect PIN';
                        });
                      }
                    },
              child: verifying
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(s?.verify ?? 'Verify'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  Future<void> _setTimeout(int seconds) async {
    HapticFeedback.selectionClick();
    final prev = _timeoutSeconds;
    setState(() {
      _timeoutSeconds = seconds;
      _error = null;
    });
    final r = await _service.updateAppLockSettings(
      widget.currentUserId,
      timeoutSeconds: seconds,
    );
    if (!mounted) return;
    if (!r.success) {
      setState(() {
        _timeoutSeconds = prev;
        _error = r.error;
      });
    }
  }

  String _timeoutLabel(int seconds, dynamic s) {
    switch (seconds) {
      case 0:
        return s?.lockTimeoutImmediate ?? 'Immediate';
      case 60:
        return s?.lockTimeout1Min ?? '1 min';
      case 300:
        return s?.lockTimeout5Min ?? '5 min';
      case 900:
        return s?.lockTimeout15Min ?? '15 min';
      default:
        return '${seconds}s';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kUsalamaBg,
        appBar: AppBar(
          title: Text(s?.usalamaCardTwoFactorBiometric ?? 'Two-factor & biometric'),
          backgroundColor: kUsalamaCard,
          foregroundColor: kUsalamaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kUsalamaPrimary))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      UsalamaInlineErrorBanner(
                        message: _error,
                        onDismiss: () => setState(() => _error = null),
                        closeLabel: s?.close ?? 'Close',
                      ),
                      UsalamaInlineSuccessBanner(
                        message: _success,
                        onDismiss: () => setState(() => _success = null),
                        closeLabel: s?.close ?? 'Close',
                      ),

                      // ── Two-factor authentication ───────────────────────
                      UsalamaSection(title: s?.twoFactorTitle ?? 'Two-factor authentication'),
                      _twoFactorCard(s),

                      // ── Biometric login ─────────────────────────────────
                      UsalamaSection(title: s?.usalamaBiometricLogin ?? 'Biometric login'),
                      _biometricCard(s),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _twoFactorCard(dynamic s) {
    if (_setupMode && _qrUrl != null) return _twoFactorSetupCard(s);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kUsalamaCard,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _twoFAEnabled
                          ? Colors.green.withValues(alpha: 0.15)
                          : kUsalamaIconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _twoFAEnabled ? Icons.verified_user_rounded : Icons.shield_outlined,
                      color: _twoFAEnabled ? Colors.green : Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _twoFAEnabled
                              ? (s?.twoFAEnabled ?? 'Enabled')
                              : (s?.twoFADisabled ?? 'Disabled'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kUsalamaPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s?.twoFADescription ?? 'A 6-digit code from your authenticator app',
                          style: const TextStyle(fontSize: 12, color: kUsalamaSecondary),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_twoFAEnabled) ...[
                if (_recoveryCodes.isNotEmpty) ...[
                  _recoveryCodesBlock(s),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : _regenerateCodes,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(s?.regenerateCodes ?? 'Regenerate codes'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : _disable2FA,
                        icon: const Icon(Icons.shield_outlined, size: 18, color: Colors.red),
                        label: Text(
                          s?.disable2FA ?? 'Disable',
                          style: const TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : _enable2FA,
                    icon: _processing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.shield_outlined),
                    label: Text(s?.enable2FA ?? 'Enable two-factor'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _twoFactorSetupCard(dynamic s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kUsalamaCard,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s?.twoFAScanInstructions ?? 'Scan with your authenticator app',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kUsalamaPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: kUsalamaCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    _qrUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kUsalamaPrimary,
                        ),
                      );
                    },
                    errorBuilder: (_, e, st) => Center(
                      child: Text(
                        s?.twoFAQrUnavailable ?? 'QR unavailable',
                        style: const TextStyle(color: kUsalamaSecondary, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
              if (_recoveryCodes.isNotEmpty) ...[
                const SizedBox(height: 16),
                _recoveryCodesBlock(s),
              ],
              const SizedBox(height: 16),
              Text(
                s?.twoFAEnterCode ?? 'Enter 6-digit code:',
                style: const TextStyle(fontSize: 13, color: kUsalamaPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  hintText: s?.twoFACodeHint ?? '000000',
                  filled: true,
                  fillColor: kUsalamaBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                  color: kUsalamaPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _processing
                          ? null
                          : () => setState(() {
                                _setupMode = false;
                                _qrUrl = null;
                                _recoveryCodes = const [];
                                _codeController.clear();
                              }),
                      child: Text(s?.cancel ?? 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _processing ? null : _confirm2FA,
                      child: _processing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(s?.verifyAndEnable ?? 'Verify & enable'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recoveryCodesBlock(dynamic s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kUsalamaBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s?.recoveryCodes ?? 'Recovery codes',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kUsalamaPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _copyRecoveryCodes,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(s?.copyRecoveryCodes ?? 'Copy'),
                style: TextButton.styleFrom(
                  foregroundColor: kUsalamaSecondary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s?.recoveryCodesDesc ?? 'Save these somewhere safe.',
            style: const TextStyle(fontSize: 11, color: kUsalamaSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _recoveryCodes
                .map((code) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kUsalamaCard,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                          color: kUsalamaPrimary,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _biometricCard(dynamic s) {
    // Disabled-state precedence: missing PIN beats device-capability
    // problems, since "Set a PIN" is the most actionable hint.
    final String? disabledReason;
    if (!_hasPin) {
      disabledReason = s?.usalamaBiometricRequiresPin ??
          'Set a PIN before enabling biometric unlock.';
    } else {
      switch (_biometricAvailability) {
        case BiometricAvailability.notSupported:
          disabledReason = s?.usalamaBiometricUnavailable ??
              'No biometric sensor on this device';
          break;
        case BiometricAvailability.notEnrolled:
          disabledReason = s?.usalamaBiometricNotEnrolled ??
              'Enroll a fingerprint or face in your phone settings first';
          break;
        case BiometricAvailability.weakOnly:
          disabledReason = s?.usalamaBiometricWeakOnly ??
              "Your device's biometric isn't strong enough for sign-in";
          break;
        case BiometricAvailability.available:
          disabledReason = null;
          break;
      }
    }

    // Biometric-type-aware copy: "fingerprint" / "Face ID" / generic.
    final IconData kindIcon = _biometricKind == BiometricKind.face
        ? Icons.face_outlined
        : _biometricKind == BiometricKind.iris
            ? Icons.visibility_outlined
            : Icons.fingerprint_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kUsalamaCard,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UsalamaSwitchTile(
                icon: kindIcon,
                title: s?.usalamaBiometricLogin ?? 'Biometric unlock',
                subtitle: disabledReason ??
                    (s?.usalamaBiometricSub ??
                        'Use fingerprint or face to skip PIN entry when reopening the app'),
                value: _biometricEnabled,
                saving: _processing,
                onChanged: disabledReason != null ? (_) {} : _toggleBiometric,
              ),
              if (!_hasPin)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PinChangeScreen(currentUserId: widget.currentUserId),
                        ),
                      ).then((_) => _load());
                    },
                    icon: const Icon(Icons.pin_outlined, size: 18),
                    label: Text(s?.usalamaSetPinCta ?? 'Set PIN'),
                  ),
                ),
              const Divider(height: 24),
              Text(
                s?.usalamaAutoLockTitle ?? 'Auto-lock after inactivity',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kUsalamaPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeoutPresets
                    .map((sec) => ChoiceChip(
                          label: Text(_timeoutLabel(sec, s)),
                          selected: _timeoutSeconds == sec,
                          onSelected:
                              _hasPin ? (_) => _setTimeout(sec) : null,
                          selectedColor: kUsalamaPrimary,
                          backgroundColor: kUsalamaBg,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: _timeoutSeconds == sec
                                ? Colors.white
                                : kUsalamaPrimary,
                          ),
                          showCheckmark: false,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
