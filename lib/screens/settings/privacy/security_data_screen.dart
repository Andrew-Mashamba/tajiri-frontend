import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../services/privacy_service.dart';
import '../security/security_settings_screen.dart';
import '_privacy_widgets.dart';

/// Security & data — deep-links to the unified Security home and exposes
/// the data export + account-deletion actions.
class SecurityDataScreen extends StatefulWidget {
  final int currentUserId;
  const SecurityDataScreen({super.key, required this.currentUserId});

  @override
  State<SecurityDataScreen> createState() => _SecurityDataScreenState();
}

class _SecurityDataScreenState extends State<SecurityDataScreen> {
  final _service = PrivacyService();
  final bool _loading = false;
  bool _exporting = false;
  String? _exportSize;
  String? _formError;
  String? _info;

  Future<void> _exportData() async {
    setState(() {
      _exporting = true;
      _exportSize = null;
      _formError = null;
    });
    final body = await _service.dataExportJson(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _exporting = false;
      if (body == null) {
        _formError = 'save_failed';
      } else {
        final kb = (body.length / 1024).toStringAsFixed(1);
        _exportSize = '$kb KB';
      }
    });
  }

  Future<void> _confirmDeletion() async {
    final s = AppStringsScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s?.faraghaDeleteConfirm ?? 'Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s?.faraghaDeleteAccount ?? 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await _service.requestDeletion(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      if (success) {
        _info = s?.faraghaDeleteRequested ?? 'Request submitted. Check your email.';
        _formError = null;
      } else {
        _formError = 'save_failed';
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
          title: Text(s?.faraghaCardSecurity ?? 'Security & data'),
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
                          ? (isSw ? 'Imeshindwa' : 'Action failed')
                          : null,
                      onDismiss: () => setState(() => _formError = null),
                      closeLabel: s?.close ?? 'Close',
                    ),
                    if (_info != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _info!,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF1B5E20)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    FaraghaSection(title: isSw ? 'Usalama' : 'Security'),
                    // Deep-link to the unified Security home (sessions, 2FA, app
                    // lock, password change, activity log + login alerts all
                    // live there). Avoids duplicating the toggles here.
                    _navTile(
                      icon: Icons.shield_outlined,
                      title: s?.security ?? 'Security',
                      onTap: () => _push(SecuritySettingsScreen(currentUserId: widget.currentUserId)),
                    ),

                    FaraghaSection(title: isSw ? 'Data yangu' : 'My data'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: kFaraghaCard,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 72),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: kFaraghaIconBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.download_outlined, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        s?.faraghaDataExport ?? 'Download my data',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: kFaraghaPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _exportSize == null
                                            ? (s?.faraghaDataExportSub ?? '')
                                            : '${s?.faraghaDataExportReady ?? "Ready"} ($_exportSize)',
                                        style: const TextStyle(fontSize: 12, color: kFaraghaSecondary),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (_exporting)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kFaraghaSecondary,
                                    ),
                                  )
                                else
                                  TextButton(
                                    onPressed: _exportData,
                                    child: Text(s?.faraghaDataExport ?? 'Export'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    FaraghaSection(title: isSw ? 'Akaunti' : 'Account'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: kFaraghaCard,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        child: InkWell(
                          onTap: _confirmDeletion,
                          borderRadius: BorderRadius.circular(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 72),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          s?.faraghaDeleteAccount ?? 'Delete account',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          s?.faraghaDeleteAccountSub ?? '',
                                          style: const TextStyle(fontSize: 12, color: kFaraghaSecondary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: kFaraghaSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kFaraghaCard,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kFaraghaIconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kFaraghaPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kFaraghaSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
