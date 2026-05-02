import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../services/auth_service.dart';
import '../../../services/biometric_step_up.dart';
import '../../../services/security_service.dart';
import '_security_widgets.dart';

/// Single screen that owns the entire 4-digit PIN lifecycle.
///
/// In TAJIRI auth: phone + 4-digit PIN logs the user in
/// (POST /api/users/login-by-phone). The PIN is bcrypt-hashed in
/// `user_profiles.app_lock_pin` and is the SAME secret that locks the
/// app on device.
///
/// Modes (auto-detected from `checkAppLockStatus.hasPin`):
///   • setNew    — no PIN exists yet: ask new + confirm only
///   • change    — PIN exists: ask current + new + confirm
///   • remove    — surfaced as a button at bottom when PIN exists
class PinChangeScreen extends StatefulWidget {
  final int currentUserId;
  const PinChangeScreen({super.key, required this.currentUserId});

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

enum _PinMode { loading, setNew, change }

class _PinChangeScreenState extends State<PinChangeScreen> {
  final _service = SecurityService();
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _currentFocus = FocusNode();
  final _nextFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _removePinFocus = FocusNode();

  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;
  bool _submitting = false;
  bool _removing = false;
  String? _error;
  String? _success;
  _PinMode _mode = _PinMode.loading;

  @override
  void initState() {
    super.initState();
    _detectMode();
  }

  Future<void> _detectMode() async {
    final r = await _service.checkAppLockStatus(widget.currentUserId);
    if (!mounted) return;
    setState(() => _mode = r.hasPin ? _PinMode.change : _PinMode.setNew);
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    _currentFocus.dispose();
    _nextFocus.dispose();
    _confirmFocus.dispose();
    _removePinFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppStringsScope.of(context);
    if (s == null || !_form.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });

    // For setNew there's no biometric step-up — the user hasn't yet
    // enrolled biometric. For change, the backend requires a fresh
    // step-up if they have biometric armed; BiometricStepUp.confirm
    // returns the `skipStepUp` sentinel for PIN-only users.
    String? stepUp;
    if (_mode == _PinMode.change) {
      stepUp = await BiometricStepUp.confirm(purpose: 'pin_change');
      if (!mounted) return;
      if (stepUp == null) {
        // User cancelled the biometric prompt or the server rejected.
        setState(() {
          _submitting = false;
          _error = s.usalamaStepUpCancelled;
        });
        return;
      }
    }

    final ({bool success, String? error, bool requiresStepUp}) r;
    if (_mode == _PinMode.setNew) {
      final r0 = await _service.setAppLockPin(widget.currentUserId, _next.text);
      r = (success: r0.success, error: r0.error, requiresStepUp: false);
    } else {
      r = await _service.changeAppLockPin(
        widget.currentUserId,
        _current.text,
        _next.text,
        stepUpToken: stepUp,
      );
    }

    if (!mounted) return;
    final wasChange = _mode == _PinMode.change;
    setState(() {
      _submitting = false;
      if (r.success) {
        _success = _mode == _PinMode.setNew
            ? (s.usalamaPinCreated)
            : (s.usalamaPinSaved);
        _current.clear();
        _next.clear();
        _confirm.clear();
        _mode = _PinMode.change;
        FocusScope.of(context).unfocus();
      } else {
        _error = r.error ?? s.failedToLoadSettings;
      }
    });

    // After a successful PIN *change* the server rotates refresh tokens;
    // the biometric credential is still valid (server-side row hasn't
    // moved) but the local key is fine. We don't revoke biometric on
    // PIN change in Flow 2 — the credential is independent of the PIN
    // beyond the enrollment-time PIN check.
    if (r.success && wasChange) {
      // No-op: in Flow 2 the biometric credential survives PIN change.
    }
  }

  Future<void> _removePin() async {
    final s = AppStringsScope.of(context);
    if (s == null) return;
    final pin = await _promptForRemovePin(s);
    if (pin == null || pin.length != 4) return;

    setState(() {
      _removing = true;
      _error = null;
      _success = null;
    });

    // PIN removal is sensitive — require a fresh biometric step-up if
    // the user has biometric armed. PIN-only users get the skip
    // sentinel and pass through.
    final stepUp = await BiometricStepUp.confirm(purpose: 'pin_remove');
    if (!mounted) return;
    if (stepUp == null) {
      setState(() {
        _removing = false;
        _error = s.usalamaStepUpCancelled;
      });
      return;
    }

    final r = await _service.removeAppLockPin(
      widget.currentUserId,
      pin,
      stepUpToken: stepUp,
    );
    if (!mounted) return;
    setState(() {
      _removing = false;
      if (r.success) {
        _success = s.usalamaPinRemovedSuccess;
        _mode = _PinMode.setNew;
        _current.clear();
        _next.clear();
        _confirm.clear();
      } else {
        _error = r.error ?? s.failedToLoadSettings;
      }
    });
    if (r.success) {
      // PIN-less means we can no longer authorize a biometric re-
      // enrollment (enrollment requires a server-verified PIN). Wipe
      // the credential so the user gets a clean state.
      await AuthService.instance.revokeBiometric(userId: widget.currentUserId);
    }
  }

  Future<String?> _promptForRemovePin(dynamic s) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.usalamaRemovePinConfirmTitle ?? 'Remove PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                s?.usalamaRemovePinConfirm ??
                    'Removing your PIN means anyone with your phone can sign in. Are you sure?',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              focusNode: _removePinFocus,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '••••',
                counterText: '',
                labelText: s?.usalamaCurrentPin ?? 'Current PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(
              s?.usalamaRemovePinAction ?? 'Remove',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final title = _mode == _PinMode.setNew
        ? (s?.usalamaSetPinTitle ?? 'Set PIN')
        : (s?.usalamaCardChangePin ?? 'Change PIN');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kUsalamaBg,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: kUsalamaCard,
          foregroundColor: kUsalamaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _mode == _PinMode.loading
              ? const Center(child: CircularProgressIndicator(color: kUsalamaPrimary))
              : Form(
                  key: _form,
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

                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        child: Text(
                          _mode == _PinMode.setNew
                              ? (s?.usalamaPinSetExplainer ??
                                  'Choose a 4-digit PIN. You will use it to sign in and to unlock the app on this device.')
                              : (s?.usalamaPinExplainer ?? ''),
                          style: const TextStyle(fontSize: 12, color: kUsalamaSecondary),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      if (_mode == _PinMode.change) ...[
                        _pinField(
                          controller: _current,
                          focusNode: _currentFocus,
                          nextFocus: _nextFocus,
                          label: s?.usalamaCurrentPin ?? 'Current PIN',
                          obscure: !_showCurrent,
                          toggle: () => setState(() => _showCurrent = !_showCurrent),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return s?.usalamaPinRequired ?? 'Required';
                            }
                            if (v.length != 4) {
                              return s?.usalamaPin4Digits ?? 'PIN must be 4 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      _pinField(
                        controller: _next,
                        focusNode: _nextFocus,
                        nextFocus: _confirmFocus,
                        label: s?.usalamaNewPin ?? 'New PIN',
                        obscure: !_showNext,
                        toggle: () => setState(() => _showNext = !_showNext),
                        validator: (v) {
                          if (v == null || v.length != 4) {
                            return s?.usalamaPin4Digits ?? 'PIN must be 4 digits';
                          }
                          if (_mode == _PinMode.change && v == _current.text) {
                            return s?.usalamaPinSameAsCurrent ??
                                'New PIN must be different';
                          }
                          if (_isWeakPin(v)) {
                            return s?.usalamaPinWeak ??
                                'Avoid sequential or repeated digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _pinField(
                        controller: _confirm,
                        focusNode: _confirmFocus,
                        nextFocus: null,
                        label: s?.usalamaConfirmNewPin ?? 'Confirm new PIN',
                        obscure: !_showConfirm,
                        toggle: () => setState(() => _showConfirm = !_showConfirm),
                        validator: (v) {
                          if (v == null || v.length != 4) {
                            return s?.usalamaPin4Digits ?? 'PIN must be 4 digits';
                          }
                          if (v != _next.text) {
                            return s?.usalamaPinsDoNotMatch ?? 'PINs do not match';
                          }
                          return null;
                        },
                        onSubmit: _submitting ? null : _submit,
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_mode == _PinMode.setNew
                                  ? (s?.usalamaPinCreateCta ?? 'Create PIN')
                                  : (s?.usalamaPinSaveCta ?? 'Save PIN')),
                        ),
                      ),

                      if (_mode == _PinMode.change) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton.icon(
                            onPressed: _removing ? null : _removePin,
                            icon: _removing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Icon(Icons.lock_open_outlined,
                                    size: 18, color: Colors.red),
                            label: Text(
                              s?.usalamaRemovePin ?? 'Remove PIN',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      if (s != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            s.usalamaPinAlsoLogin,
                            style: const TextStyle(
                              fontSize: 11,
                              color: kUsalamaSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  bool _isWeakPin(String v) {
    if (v.length != 4) return false;
    final digits = v.codeUnits;
    if (digits.toSet().length == 1) return true;
    bool asc = true, desc = true;
    for (int i = 1; i < 4; i++) {
      if (digits[i] != digits[i - 1] + 1) asc = false;
      if (digits[i] != digits[i - 1] - 1) desc = false;
    }
    return asc || desc;
  }

  Widget _pinField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
    VoidCallback? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      maxLength: 4,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      style: const TextStyle(fontSize: 22, letterSpacing: 8),
      textAlign: TextAlign.center,
      onChanged: (v) {
        if (v.length == 4 && nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      onFieldSubmitted: (_) => onSubmit?.call(),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: kUsalamaCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: toggle,
        ),
      ),
      validator: validator,
    );
  }
}
