import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/profile_service.dart';

/// Username (@handle) management screen.
/// Path: Home → Profile → Settings → Username.
///
/// Conforms to docs/ENGINEERING_PLAYBOOK.md:
///   • No SnackBars — inline error banner + form `errorText` only.
///   • `Navigator.pop(context, true)` on success (no toast — navigation IS
///     the confirmation). Caller `ProfileService.invalidate()` runs first.
///   • Page chrome: AppBar, SafeArea, tap-outside-dismiss-keyboard,
///     `textInputAction: TextInputAction.done`, `keyboardDismissBehavior.onDrag`.
///   • Bilingual via `AppStringsScope`.
///   • `Semantics(liveRegion: true)` on error states.
///   • `autofillHints: [AutofillHints.username]` so password managers
///     can suggest it.
class UsernameSettingsScreen extends StatefulWidget {
  final int currentUserId;

  const UsernameSettingsScreen({super.key, required this.currentUserId});

  @override
  State<UsernameSettingsScreen> createState() => _UsernameSettingsScreenState();
}

class _UsernameSettingsScreenState extends State<UsernameSettingsScreen> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);

  final ProfileService _profileService = ProfileService();
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // Track first-blur so we don't validate while the user is still typing
  // their first 3 letters (Part VII → Form input UX).
  final FocusNode _focus = FocusNode();
  bool _touched = false;

  bool _loading = true;
  bool _saving = false;
  String? _currentUsername;
  String? _loadError;     // sentinel key, mapped at render
  String? _formError;     // sentinel key, mapped at render

  // Live availability state — debounced check against /users/check-handle.
  bool _checking = false;
  bool? _available;       // null = unknown / not checked yet
  Timer? _debounce;
  String _lastChecked = '';

  // Aligned with backend validator + checkHandle endpoint:
  // must start with a letter, lowercase only, [a-z][a-z0-9_], 3-20 chars.
  static const int _minLength = 3;
  static const int _maxLength = 20;
  static final RegExp _validHandle = RegExp(r'^[a-z][a-z0-9_]{2,19}$');

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    _loadProfile();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Flip _touched the first time the user leaves the field with content.
    if (!_focus.hasFocus && _controller.text.isNotEmpty && !_touched) {
      setState(() => _touched = true);
    }
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
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
        _currentUsername = result.profile!.username;
        _controller.text = _currentUsername ?? '';
      } else {
        _loadError = 'profile';
      }
    });
  }

  String? _validateUsername(String? value) {
    // Skip validation until first blur to avoid hostile errors mid-type.
    if (!_touched) return null;
    final s = AppStringsScope.of(context);
    if (value == null || value.isEmpty) {
      return s?.usernameRequired ?? 'Enter a username';
    }
    final trimmed = value.trim();
    if (trimmed.length < _minLength) {
      return s?.usernameMinLength(_minLength) ??
          'Username must be at least $_minLength characters';
    }
    if (trimmed.length > _maxLength) {
      return s?.usernameMaxLength(_maxLength) ??
          'Username cannot exceed $_maxLength characters';
    }
    // Distinct error if the only problem is the leading character.
    if (!RegExp(r'^[a-z]').hasMatch(trimmed)) {
      return s?.usernameMustStartWithLetter ?? 'Must start with a letter';
    }
    if (!_validHandle.hasMatch(trimmed)) {
      return s?.usernameInvalidChars ??
          'Use only letters, numbers, and underscore (_)';
    }
    if (_available == false && trimmed == _lastChecked) {
      return s?.usernameTaken ?? 'Already taken';
    }
    return null;
  }

  void _onTextChanged(String value) {
    if (_formError != null) {
      setState(() => _formError = null);
    }
    final v = value.trim();

    // Reset availability state when value changes — the previous check
    // may no longer apply.
    setState(() {
      _available = null;
      _checking = false;
    });
    _debounce?.cancel();

    // Skip live availability check unless the local format is valid;
    // saves a network round-trip when the value can't possibly succeed.
    if (v.isEmpty || v == _currentUsername || !_validHandle.hasMatch(v)) {
      return;
    }

    setState(() => _checking = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final available = await _profileService.checkHandleAvailability(v);
      if (!mounted) return;
      // Bail if the input changed while we were waiting.
      if (_controller.text.trim() != v) return;
      setState(() {
        _checking = false;
        _available = available;
        _lastChecked = v;
      });
      // Re-run the form validator so `_validateUsername` can surface the
      // taken-state inline.
      _formKey.currentState?.validate();
    });
  }

  Future<void> _save() async {
    setState(() => _touched = true);
    if (!_formKey.currentState!.validate()) return;
    final raw = _controller.text.trim();
    if (raw == _currentUsername) {
      setState(() => _formError = 'unchanged');
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final result = await _profileService.updateUsername(
      userId: widget.currentUserId,
      username: raw,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ProfileService.invalidate(widget.currentUserId);
      // No SnackBar — navigation IS the confirmation. The Settings list
      // (and the parent Profile when user goes further back) will reflect
      // the new handle on next render via the cache miss.
      Navigator.pop(context, true);
    } else {
      setState(() {
        _formError = result.message ?? 'save_failed';
      });
    }
  }

  /// Delete (D in CRUD): clear the username. Backend now accepts
  /// `username: null` to remove it.
  Future<void> _remove() async {
    final s = AppStringsScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s?.usernameRemoveConfirm ?? 'Remove your username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
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
    if (ok != true || !mounted) return;
    setState(() {
      _saving = true;
      _formError = null;
    });
    final result = await _profileService.updateUsername(
      userId: widget.currentUserId,
      username: null,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ProfileService.invalidate(widget.currentUserId);
      Navigator.pop(context, true);
    } else {
      setState(() => _formError = result.message ?? 'save_failed');
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      // HitTestBehavior.opaque so taps on transparent regions reliably
      // dismiss the keyboard (playbook Part VI → Page chrome).
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          title: Text(s?.username ?? 'Username'),
          backgroundColor: Colors.white,
          foregroundColor: _primary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _loadError != null
                  ? _buildErrorState(s)
                  : _buildForm(s),
        ),
      ),
    );
  }

  /// Maps a sentinel error key to its bilingual message.
  String _localizedError(String? key, dynamic s) {
    switch (key) {
      case 'profile':
        return s?.failedToLoadProfile ?? 'Failed to load profile';
      case 'unchanged':
        return s?.usernameNoChange ?? 'Username unchanged';
      case 'save_failed':
        return s?.usernameSaveFailed ?? 'Could not save username — try again.';
      default:
        return key ?? '';
    }
  }

  Widget _buildErrorState(dynamic s) => Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_localizedError(_loadError, s),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _secondary)),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: _loadProfile,
                  child: Text(s?.retry ?? 'Retry'),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildInlineErrorBanner(dynamic s) {
    final message = _localizedError(_formError, s);
    if (message.isEmpty) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 20, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.red),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              label: s?.close ?? 'Close',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                onPressed: () => setState(() => _formError = null),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(dynamic s) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_formError != null) _buildInlineErrorBanner(s),
              Text(
                s?.usernameDescription ??
                    'Your username (@handle) will appear on your profile and posts.',
                style: const TextStyle(fontSize: 14, color: _secondary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _controller,
                focusNode: _focus,
                decoration: InputDecoration(
                  labelText: s?.username ?? 'Username',
                  hintText: s?.usernameHint ?? 'example_name',
                  prefixText: '@ ',
                  suffixIcon: _availabilitySuffixIcon(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  counterText: '', // hide built-in counter; we render our own helper
                ),
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                onChanged: _onTextChanged,
                inputFormatters: [
                  // Force lowercase + allowed character set at the keystroke
                  // level — the validator still runs as a safety net.
                  _LowercaseFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                  LengthLimitingTextInputFormatter(_maxLength),
                ],
                validator: _validateUsername,
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              _AvailabilityHint(
                checking: _checking,
                available: _available,
                helper: s?.usernameHelperText(_minLength, _maxLength) ??
                    'Lowercase letters, numbers and _, $_minLength–$_maxLength chars. Must start with a letter.',
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(s?.save ?? 'Save'),
                ),
              ),
              if ((_currentUsername ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextButton.icon(
                    onPressed: _saving ? null : _remove,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      s?.usernameRemove ?? 'Remove username',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

  Widget? _availabilitySuffixIcon() {
    if (_checking) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _secondary),
        ),
      );
    }
    if (_available == true) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
      );
    }
    if (_available == false) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
      );
    }
    return null;
  }
}

/// Inline status row below the field — shows "Checking…", "Available",
/// "Already taken", or the helper text by default. Wrapped in
/// `Semantics(liveRegion: true)` so screen readers announce changes.
class _AvailabilityHint extends StatelessWidget {
  final bool checking;
  final bool? available;
  final String helper;
  const _AvailabilityHint({
    required this.checking,
    required this.available,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (checking) {
      return Semantics(
        liveRegion: true,
        child: Text(
          s?.usernameChecking ?? 'Checking…',
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      );
    }
    if (available == true) {
      return Semantics(
        liveRegion: true,
        child: Text(
          s?.usernameAvailable ?? 'Available',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (available == false) {
      return Semantics(
        liveRegion: true,
        child: Text(
          s?.usernameTaken ?? 'Already taken',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Text(
      helper,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
    );
  }
}

/// Force every typed character to lowercase. Cheaper than running the
/// whole text through `.toLowerCase()` after the fact (preserves caret).
class _LowercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text == newValue.text.toLowerCase()) return newValue;
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}
