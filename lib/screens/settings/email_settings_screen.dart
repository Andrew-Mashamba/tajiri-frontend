import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/profile_service.dart';
import '../../services/user_service.dart';
import 'username_settings_screen.dart';

/// Email management — full CRUD with two paths:
///   • TAJIRI provided: read-only `{username}@tajiri.co.tz` derived from
///     the user's handle. Requires username to exist; routes to
///     UsernameSettingsScreen if not.
///   • Custom: editable text field with email regex validation.
///
/// Performance: invalidates ProfileService cache on save/remove so the
/// new state is visible immediately (per docs/PERFORMANCE_STRATEGY.md
/// §3b — profile uses 5-min in-memory cache, no SQLite per
/// docs/SQLITE_ADOPTION_ROADMAP.md "Not Worth SQLite" list).
class EmailSettingsScreen extends StatefulWidget {
  final int currentUserId;

  const EmailSettingsScreen({super.key, required this.currentUserId});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

enum _EmailMode { tajiri, custom }

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  static const _tajiriDomain = '@tajiri.co.tz';
  static const _primary = Color(0xFF1A1A1A);
  static const _bg = Color(0xFFFAFAFA);
  static const _minTouch = 48.0;
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();
  final TextEditingController _customCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _phone;
  String? _username;
  String? _initialEmail;
  _EmailMode _mode = _EmailMode.custom;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
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
        final p = result.profile!;
        _phone = p.phoneNumber;
        _username = p.username;
        _initialEmail = p.email;
        // Detect which mode the existing email is in.
        if (_initialEmail != null && _initialEmail!.toLowerCase().endsWith(_tajiriDomain)) {
          _mode = _EmailMode.tajiri;
        } else {
          _mode = _EmailMode.custom;
          _customCtrl.text = _initialEmail ?? '';
        }
      } else {
        _loadError = result.message ??
            (AppStringsScope.of(context)?.failedToLoadProfile ??
                'Failed to load profile');
      }
    });
  }

  String? get _tajiriAddress {
    final u = (_username ?? '').trim();
    if (u.isEmpty) return null;
    return '${u.toLowerCase()}$_tajiriDomain';
  }

  /// Returns the email value the user is committing to, or null if they
  /// chose TAJIRI mode but don't have a username (caller must guard).
  String? _resolveSelectedEmail() {
    switch (_mode) {
      case _EmailMode.tajiri:
        return _tajiriAddress;
      case _EmailMode.custom:
        final raw = _customCtrl.text.trim();
        return raw.isEmpty ? null : raw;
    }
  }

  String? _validateCustom(String? value) {
    if (_mode != _EmailMode.custom) return null;
    final s = AppStringsScope.of(context);
    final v = (value ?? '').trim();
    if (v.isEmpty) return null; // empty == remove (handled separately)
    if (!_emailRegex.hasMatch(v)) {
      return s?.emailInvalid ?? 'Invalid email';
    }
    return null;
  }

  Future<void> _save() async {
    final s = AppStringsScope.of(context);
    if (_mode == _EmailMode.custom) {
      if (!_formKey.currentState!.validate()) return;
    }
    final phone = _phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.saveFailed ?? 'Failed to save')),
      );
      return;
    }
    if (_mode == _EmailMode.tajiri && (_username ?? '').isEmpty) {
      // Should not get here: button is disabled. Defensive guard.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.emailRequiresUsername ?? 'Set a username first')),
      );
      return;
    }
    final value = _resolveSelectedEmail();
    if (value == _initialEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.nothingToSave ?? 'Nothing to save')),
      );
      return;
    }
    await _putEmail(phone, value, successMessage: s?.profileSaved ?? 'Profile saved');
  }

  Future<void> _remove() async {
    final s = AppStringsScope.of(context);
    if ((_initialEmail ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.nothingToSave ?? 'Nothing to save')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s?.emailRemoveConfirm ?? 'Remove your email address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s?.cancel ?? 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s?.delete ?? 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final phone = _phone;
    if (phone == null || phone.isEmpty) return;
    await _putEmail(phone, null, successMessage: s?.emailRemoved ?? 'Email removed');
  }

  Future<void> _putEmail(String phone, String? value, {required String successMessage}) async {
    final s = AppStringsScope.of(context);
    setState(() => _saving = true);
    final result = await _userService.updateProfileByPhone(phone, {'email': value});
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ProfileService.invalidate(widget.currentUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (s?.saveFailed ?? 'Failed to save'))),
      );
    }
  }

  Future<void> _goToUsernameSetup() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UsernameSettingsScreen(currentUserId: widget.currentUserId),
      ),
    );
    if (updated == true && mounted) {
      ProfileService.invalidate(widget.currentUserId);
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(s?.editEmailTitle ?? 'Edit email'),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _loadError != null
                ? _buildErrorState(s)
                : _buildForm(s),
      ),
    );
  }

  Widget _buildErrorState(dynamic s) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_loadError ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF666666))),
            const SizedBox(height: 24),
            SizedBox(
              height: _minTouch,
              child: TextButton(
                onPressed: _loading ? null : _loadProfile,
                child: Text(s?.retry ?? 'Retry'),
              ),
            ),
          ],
        ),
      );

  Widget _buildForm(dynamic s) {
    final hasUsername = (_username ?? '').isNotEmpty;
    final tajiriAddr = _tajiriAddress;
    final hasExistingEmail = (_initialEmail ?? '').isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasExistingEmail) ...[
              _CurrentEmailCard(label: s?.current ?? 'Current', email: _initialEmail!),
              const SizedBox(height: 16),
            ],
            _OptionCard(
              selected: _mode == _EmailMode.tajiri,
              icon: Icons.verified_outlined,
              title: s?.emailUseTajiri ?? 'Use TAJIRI email (@tajiri.co.tz)',
              subtitle: hasUsername
                  ? (tajiriAddr ?? '')
                  : (s?.emailRequiresUsername ?? 'Set a username first to get a TAJIRI address'),
              enabled: !_saving && hasUsername,
              onTap: () => setState(() => _mode = _EmailMode.tajiri),
              trailing: hasUsername
                  ? null
                  : TextButton(
                      onPressed: _saving ? null : _goToUsernameSetup,
                      child: Text(s?.setUsername ?? 'Set username'),
                    ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              selected: _mode == _EmailMode.custom,
              icon: Icons.email_outlined,
              title: s?.emailUseCustom ?? 'Use a different email',
              subtitle: s?.emailUseCustomSubtitle ?? 'e.g. Gmail, Yahoo, work email',
              enabled: !_saving,
              onTap: () => setState(() => _mode = _EmailMode.custom),
            ),
            if (_mode == _EmailMode.custom) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                enabled: !_saving,
                validator: _validateCustom,
                decoration: InputDecoration(
                  labelText: s?.email ?? 'Email',
                  hintText: s?.emailHint ?? 'name@example.com',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
            const SizedBox(height: 28),
            _SaveButton(
              saving: _saving,
              onPressed: _save,
              label: s?.save ?? 'Save',
              enabled: !(_mode == _EmailMode.tajiri && !hasUsername),
            ),
            if (hasExistingEmail) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: _minTouch,
                child: TextButton.icon(
                  onPressed: _saving ? null : _remove,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(
                    s?.emailRemove ?? 'Remove email',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrentEmailCard extends StatelessWidget {
  final String label;
  final String email;
  const _CurrentEmailCard({required this.label, required this.email});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.email_outlined, size: 20, color: Color(0xFF666666)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _OptionCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final Widget? trailing;

  const _OptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF1A1A1A)
        : Colors.grey.shade300;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 0.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 22,
                color: selected
                    ? const Color(0xFF1A1A1A)
                    : Colors.grey.shade500,
              ),
              const SizedBox(width: 12),
              Icon(icon, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final bool enabled;
  final VoidCallback onPressed;
  final String label;
  const _SaveButton({
    required this.saving,
    required this.onPressed,
    required this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: (saving || !enabled) ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: saving
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(label),
        ),
      );
}
