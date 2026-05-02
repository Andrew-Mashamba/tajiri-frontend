import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../models/privacy_settings_model.dart';
import '../../../services/privacy_service.dart';
import '_privacy_widgets.dart';

/// Sensitive consent — face data + marketing email separation.
class SensitivePrivacyScreen extends StatefulWidget {
  final int currentUserId;
  const SensitivePrivacyScreen({super.key, required this.currentUserId});

  @override
  State<SensitivePrivacyScreen> createState() => _SensitivePrivacyScreenState();
}

class _SensitivePrivacyScreenState extends State<SensitivePrivacyScreen> {
  final _service = PrivacyService();
  PrivacySettings _s = const PrivacySettings();
  bool _loading = true;
  String? _formError;
  String? _info;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _service.getPrivacySettings(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success && r.settings != null) _s = r.settings!;
    });
  }

  Future<void> _toggleFaceConsent(bool consented) async {
    const key = 'face_embedding_consent';
    final prev = _s;
    setState(() {
      _saving.add(key);
      _s = _s.copyWith({key: consented});
      _formError = null;
      _info = null;
    });
    final purged = await _service.setFaceConsent(widget.currentUserId, consented);
    if (!mounted) return;
    if (purged < 0) {
      setState(() {
        _saving.remove(key);
        _s = prev;
        _formError = 'save_failed';
      });
    } else {
      setState(() {
        _saving.remove(key);
        if (!consented && purged > 0) {
          _info = '$purged purged';
        }
      });
    }
  }

  Future<void> _toggle(String key, bool value) async {
    final prev = _s;
    setState(() {
      _saving.add(key);
      _s = _s.copyWith({key: value});
      _formError = null;
    });
    final updated = await _service.patch(widget.currentUserId, {key: value});
    if (!mounted) return;
    setState(() {
      _saving.remove(key);
      if (updated == null) {
        _s = prev;
        _formError = 'save_failed';
      } else {
        _s = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kFaraghaBg,
        appBar: AppBar(
          title: Text(s?.faraghaCardSensitive ?? 'Sensitive data'),
          backgroundColor: kFaraghaCard,
          foregroundColor: kFaraghaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kFaraghaPrimary))
              : ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    FaraghaInlineErrorBanner(
                      message: _formError == 'save_failed'
                          ? (isSw ? 'Imeshindwa kuhifadhi' : 'Could not save change')
                          : null,
                      onDismiss: () => setState(() => _formError = null),
                      closeLabel: s?.close ?? 'Close',
                    ),

                    FaraghaSection(title: isSw ? 'Biometriki' : 'Biometrics'),
                    FaraghaSwitchTile(
                      icon: Icons.face_outlined,
                      title: s?.faraghaFaceConsent ?? 'Consent to store facial data',
                      subtitle: s?.faraghaFaceConsentSub,
                      value: _s.faceEmbeddingConsent,
                      saving: _saving.contains('face_embedding_consent'),
                      onChanged: _toggleFaceConsent,
                    ),
                    if (_info != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        child: Text(
                          isSw
                              ? 'Data ya uso imefutwa.'
                              : 'Existing facial data has been purged.',
                          style: const TextStyle(fontSize: 12, color: kFaraghaSecondary),
                        ),
                      ),

                    FaraghaSection(title: isSw ? 'Barua za masoko' : 'Marketing email'),
                    FaraghaSwitchTile(
                      icon: Icons.mark_email_unread_outlined,
                      title: s?.faraghaMarketingEmail ?? 'Receive marketing email',
                      subtitle: s?.faraghaMarketingEmailSub,
                      value: _s.marketingEmailEnabled,
                      saving: _saving.contains('marketing_email_enabled'),
                      onChanged: (v) => _toggle('marketing_email_enabled', v),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }
}
