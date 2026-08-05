// lib/screens/profile/affiliate_settings_screen.dart
//
// UN-014 — strategy posts.md row 79. Creator sets their affiliate
// code; buyers enter the code at checkout and the order persists
// `affiliate_user_id`. On order completion the backend fires
// affiliate_conversion·author so the creator earns.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/affiliate_service.dart';

class AffiliateSettingsScreen extends StatefulWidget {
  final int currentUserId;

  const AffiliateSettingsScreen({super.key, required this.currentUserId});

  @override
  State<AffiliateSettingsScreen> createState() =>
      _AffiliateSettingsScreenState();
}

class _AffiliateSettingsScreenState extends State<AffiliateSettingsScreen> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kTertiary = Color(0xFF999999);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kSurface = Colors.white;
  static const _kBackground = Color(0xFFFAFAFA);
  static const _kIconBg = Color(0xFFF5F5F5);

  final _service = AffiliateService();
  final _ctrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _existing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final code = await _service.getMyCode(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _existing = code;
      _ctrl.text = code ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ok = await _service.setMyCode(widget.currentUserId, code.isEmpty ? null : code);
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (ok) _existing = code.isEmpty ? null : code;
      });
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(code.isEmpty ? 'Affiliate code cleared' : 'Affiliate code saved'),
          ),
        );
      } else {
        setState(() => _error = 'Could not save. Try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e == 'taken'
            ? 'That code is already in use'
            : 'Could not save. Try again.';
      });
    }
  }

  void _copyCode() {
    final code = _existing;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        foregroundColor: _kPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSw ? 'Msimbo wa Mshirika' : 'Affiliate code',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    isSw
                        ? 'Wateja wakitumia msimbo wako wakati wa kulipia, utapata mapato kwa kila ununuzi.'
                        : 'When buyers enter your code at checkout, you earn affiliate_conversion on every completed order.',
                    style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (_existing != null && _existing!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSw ? 'Msimbo wako' : 'Your code',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _existing!,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _copyCode,
                            icon: const Icon(Icons.copy_rounded, color: Colors.white),
                            tooltip: 'Copy',
                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    isSw ? 'Tengeneza au badilisha' : 'Set or change',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSw
                        ? 'Herufi 3-32 (A-Z, 0-9, _, -). Toa nafasi tupu ili kufuta msimbo.'
                        : '3-32 chars (A-Z, 0-9, _, -). Leave empty to clear your code.',
                    style: const TextStyle(fontSize: 11, color: _kTertiary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ctrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: _kPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'TAJIRI-CREATOR',
                      hintStyle: const TextStyle(fontSize: 14, color: _kTertiary),
                      filled: true,
                      fillColor: _kIconBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _error,
                      errorStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: _kBorder,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isSw ? 'Hifadhi' : 'Save',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
