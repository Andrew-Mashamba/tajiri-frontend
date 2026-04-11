// lib/business/pages/email/email_client_page.dart
// Account picker — entry point for the business Email tab.
// Shows email accounts from all user businesses; tap to open inbox.

import 'package:flutter/material.dart';
import '../../../services/local_storage_service.dart';
import '../../business_notifier.dart';
import '../../models/business_models.dart';
import '../../services/business_service.dart';
import '../email_setup_page.dart';
import 'email_inbox_page.dart';
import 'email_mock_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmailClientPage extends StatefulWidget {
  const EmailClientPage({super.key});

  @override
  State<EmailClientPage> createState() => _EmailClientPageState();
}

class _EmailClientPageState extends State<EmailClientPage> {
  String? _token;
  int? _userId;
  bool _isLoading = true;
  List<_AccountInfo> _accounts = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _userId = storage.getUser()?.userId;
    await _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Ensure businesses are loaded
    if (!BusinessNotifier.instance.loaded && _userId != null) {
      await BusinessNotifier.instance.load(_userId!);
    }

    final businesses = BusinessNotifier.instance.businesses;
    final accounts = <_AccountInfo>[];

    for (final biz in businesses) {
      if (biz.id == null) continue;

      // Always try fetching email accounts from API
      List<BusinessEmail> bizAccounts = [];
      if (_token != null) {
        final result =
            await BusinessService.getEmailAccounts(_token!, biz.id!);
        if (result.success && result.data.isNotEmpty) {
          bizAccounts = result.data;
        }
      }

      // Fallback to locally-known accounts
      if (bizAccounts.isEmpty && biz.hasEmailService) {
        bizAccounts = biz.emailAccounts;
      }

      if (bizAccounts.isEmpty) continue;

      for (final acct in bizAccounts) {
        if (!acct.isActive) continue;
        final lastEmail =
            EmailMockService.getLastInboxEmail(acct.address);
        final unread = EmailMockService.getTotalUnread(acct.address);
        accounts.add(_AccountInfo(
          email: acct,
          business: biz,
          unreadCount: unread,
          lastEmailPreview: lastEmail?.preview,
          lastEmailSubject: lastEmail?.subject,
          lastEmailDate: lastEmail?.date,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    }
  }

  // Bilingual helpers
  bool get _isSwahili => false; // English default
  String get _noAccountsTitle =>
      _isSwahili ? 'Hakuna akaunti za barua pepe' : 'No email accounts';
  String get _noAccountsBody => _isSwahili
      ? 'Ongeza huduma ya barua pepe kwenye biashara yako kuanza kutumia.'
      : 'Add email service to your business to get started.';
  String get _setupBtn =>
      _isSwahili ? 'Weka Barua Pepe' : 'Set Up Email';
  String get _unreadLabel => _isSwahili ? 'hazijasomwa' : 'unread';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kPrimary))
          : _accounts.isEmpty
              ? _buildEmpty()
              : _buildAccountList(),
    );
  }

  Widget _buildEmpty() {
    final businesses = BusinessNotifier.instance.businesses;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.email_outlined, size: 64, color: _kSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(_noAccountsTitle,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            Text(_noAccountsBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: _kSecondary)),
            if (businesses.isNotEmpty) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openSetup(businesses.first),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(_setupBtn),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountList() {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadAccounts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _accounts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final info = _accounts[index];
          return _AccountCard(
            info: info,
            unreadLabel: _unreadLabel,
            onTap: () => _openInbox(info),
          );
        },
      ),
    );
  }

  void _openInbox(_AccountInfo info) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EmailInboxPage(
        emailAddress: info.email.address,
        displayName: info.email.displayName,
      ),
    ));
  }

  void _openSetup(Business biz) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          EmailSetupPage(userId: _userId ?? 0, business: biz),
    ));
  }
}

// ---------------------------------------------------------------------------
// Account info wrapper
// ---------------------------------------------------------------------------

class _AccountInfo {
  final BusinessEmail email;
  final Business business;
  final int unreadCount;
  final String? lastEmailPreview;
  final String? lastEmailSubject;
  final DateTime? lastEmailDate;

  _AccountInfo({
    required this.email,
    required this.business,
    this.unreadCount = 0,
    this.lastEmailPreview,
    this.lastEmailSubject,
    this.lastEmailDate,
  });
}

// ---------------------------------------------------------------------------
// Account card widget
// ---------------------------------------------------------------------------

class _AccountCard extends StatelessWidget {
  final _AccountInfo info;
  final String unreadLabel;
  final VoidCallback onTap;

  const _AccountCard({
    required this.info,
    required this.unreadLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(info.email.displayName.isNotEmpty
        ? info.email.displayName
        : info.email.address);

    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.email.displayName.isNotEmpty
                          ? info.email.displayName
                          : info.email.address,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(info.email.address,
                        style: const TextStyle(
                            fontSize: 13, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (info.lastEmailSubject != null) ...[
                      const SizedBox(height: 6),
                      Text(info.lastEmailSubject!,
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Unread badge + chevron
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (info.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${info.unreadCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: _kSecondary, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'[\s@.]+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
