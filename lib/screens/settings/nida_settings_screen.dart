// lib/screens/settings/nida_settings_screen.dart
//
// CRUD for the user's own NIDA (Tanzania National ID) number on
// `user_profiles.nida_number`. Reachable from Settings → Account.
// Distinct from `lib/nida/` which surfaces NIDA government services
// (status tracking, office finder, document checklist).
//
// Playbook compliance: monochrome, 48dp targets, no SnackBars (errors
// surface as inline banner; success pops with `true`), `_rounded`
// icons, `FilledButton(#1A1A1A)` primary save, `OutlinedButton` retry,
// 12-radius filled inputs with `BorderSide.none`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../models/profile_models.dart';
import '../../services/local_storage_service.dart';
import '../../services/profile_service.dart';
import '../../services/user_service.dart';
import '../../widgets/tajiri_app_bar.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Colors.white;
const Color _kDanger = Color(0xFFD32F2F);

class NidaSettingsScreen extends StatefulWidget {
  final int currentUserId;
  const NidaSettingsScreen({super.key, required this.currentUserId});

  @override
  State<NidaSettingsScreen> createState() => _NidaSettingsScreenState();
}

class _NidaSettingsScreenState extends State<NidaSettingsScreen> {
  final _profileService = ProfileService();
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  FullProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _loadError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await _profileService.getProfile(
      userId: widget.currentUserId,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success && result.profile != null) {
        _profile = result.profile;
        _ctrl.text = _profile!.nidaNumber ?? '';
        _editing = (_profile!.nidaNumber ?? '').isEmpty; // start in edit mode if empty
      } else {
        _loadError = result.message ?? 'load_failed';
      }
    });
  }

  String? _validate(String? v) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final t = (v ?? '').trim();
    if (t.isEmpty) {
      return isSw
          ? 'Ingiza namba yako ya NIDA'
          : 'Enter your NIDA number';
    }
    // Allow digits + dashes; Tanzania NIDA is 20 digits often shown as
    // YYYYMMDD-XXXXX-XXXXX-XX. Accept 16-32 char digit/dash mix.
    if (!RegExp(r'^[0-9-]+$').hasMatch(t)) {
      return isSw
          ? 'Namba ya NIDA inaweza kuwa na nambari na alama "-" tu'
          : 'Only digits and dashes are allowed';
    }
    final digits = t.replaceAll('-', '');
    if (digits.length < 16 || digits.length > 24) {
      return isSw
          ? 'Lazima iwe nambari 16-24'
          : 'Must be 16-24 digits';
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    final phone = _profile?.phoneNumber;
    if (phone == null || phone.isEmpty) {
      setState(() => _formError = 'phone_unknown');
      return;
    }
    setState(() => _saving = true);
    final newValue = _ctrl.text.trim();
    final result = await _userService.updateProfileByPhone(phone, {
      'nida_number': newValue,
    });
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _saving = false;
        _formError = result.message ?? 'save_failed';
      });
      return;
    }
    // Sync local user object minimally — nidaNumber lives only on
    // FullProfile (HTTP fetched), not on RegistrationState. The next
    // ProfileService fetch will return the updated value after invalidate.
    await LocalStorageService.getInstance();
    ProfileService.invalidate(widget.currentUserId);
    if (mounted) {
      HapticFeedback.lightImpact();
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Ondoa NIDA' : 'Remove NIDA'),
        content: Text(isSw
            ? 'Ondoa namba yako ya NIDA kutoka kwenye akaunti yako?'
            : 'Remove your NIDA number from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _kDanger),
            child: Text(s?.delete ?? 'Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final phone = _profile?.phoneNumber;
    if (phone == null || phone.isEmpty) {
      setState(() => _formError = 'phone_unknown');
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final result = await _userService.updateProfileByPhone(phone, {
      'nida_number': null,
    });
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _saving = false;
        _formError = result.message ?? 'save_failed';
      });
      return;
    }
    ProfileService.invalidate(widget.currentUserId);
    if (mounted) {
      HapticFeedback.lightImpact();
      Navigator.pop(context, true);
    }
  }

  String _localizedError(String? key, bool isSw) {
    switch (key) {
      case 'load_failed':
        return isSw ? 'Imeshindwa kupakia.' : 'Failed to load.';
      case 'phone_unknown':
        return isSw
            ? 'Namba ya simu haijulikani.'
            : 'Phone number unknown.';
      case 'save_failed':
        return isSw
            ? 'Imeshindwa kuhifadhi. Jaribu tena.'
            : 'Failed to save. Try again.';
      default:
        return key ?? '';
    }
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _kBackground,
        appBar: const TajiriAppBar(title: 'NIDA'),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kPrimary,
                  ),
                )
              : _loadError != null
                  ? _buildLoadError(isSw)
                  : _buildBody(isSw),
        ),
      ),
    );
  }

  Widget _buildLoadError(bool isSw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _localizedError(_loadError, isSw),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: Text(isSw ? 'Jaribu tena' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isSw) {
    final hasNida = (_profile?.nidaNumber ?? '').isNotEmpty;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (_formError != null) ...[
          _ErrorBanner(
            message: _localizedError(_formError, isSw),
            onDismiss: () => setState(() => _formError = null),
          ),
          const SizedBox(height: 16),
        ],
        if (!_editing && hasNida) _buildReadCard(isSw) else _buildEditForm(isSw),
        const SizedBox(height: 16),
        _buildExplainerCard(isSw),
      ],
    );
  }

  Widget _buildReadCard(bool isSw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 22,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSw ? 'Namba ya NIDA' : 'NIDA number',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kSecondary,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _profile!.nidaNumber!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () {
                          setState(() {
                            _editing = true;
                            _formError = null;
                          });
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _focus.requestFocus(),
                          );
                        },
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(isSw ? 'Hariri' : 'Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(isSw ? 'Ondoa' : 'Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kDanger,
                    side: const BorderSide(color: _kDanger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(bool isSw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        // Validate only after the user has interacted with the form
        // (playbook §2316 — don't error while still typing).
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSw ? 'Namba ya NIDA' : 'NIDA number',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ctrl,
              focusNode: _focus,
              autofocus: !((_profile?.nidaNumber ?? '').isNotEmpty),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 32,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
              ],
              validator: _validate,
              onFieldSubmitted: (_) => _save(),
              style: const TextStyle(
                fontSize: 14,
                color: _kPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: isSw
                    ? 'Mfano: 19900101-12345-12345-12'
                    : 'e.g. 19900101-12345-12345-12',
                hintStyle: const TextStyle(color: _kTertiary, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _kPrimary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kDanger, width: 1.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kDanger, width: 1.5),
                ),
                errorStyle: const TextStyle(fontSize: 12, color: _kDanger),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if ((_profile?.nidaNumber ?? '').isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () {
                              setState(() {
                                _editing = false;
                                _ctrl.text = _profile?.nidaNumber ?? '';
                                _formError = null;
                              });
                              FocusScope.of(context).unfocus();
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                          AppStringsScope.of(context)?.cancel ?? 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _kPrimary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(AppStringsScope.of(context)?.save ?? 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplainerCard(bool isSw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 20, color: _kSecondary),
              const SizedBox(width: 8),
              Text(
                isSw ? 'Kwa nini NIDA?' : 'Why NIDA?',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSw
                ? 'Namba yako ya NIDA hutumika kwa huduma za serikali (BRELA, '
                    'TRA, NHIF) na uthibitisho wa uanachama wa biashara. '
                    'Tunaitunza kwa siri.'
                : 'Your NIDA powers government services (BRELA, TRA, NHIF) '
                    'and business membership verification. We keep it private.',
            style: const TextStyle(
              fontSize: 13,
              color: _kSecondary,
              height: 1.4,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: _kDanger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDanger.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: _kDanger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: _kDanger,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded,
                size: 18, color: _kDanger),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
