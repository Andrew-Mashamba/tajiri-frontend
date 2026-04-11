// lib/business/pages/email_setup_page.dart
// Business email service setup — @tajiri.co.tz or custom domain.
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmailSetupPage extends StatefulWidget {
  final int userId;
  final Business business;
  const EmailSetupPage({super.key, required this.userId, required this.business});
  @override
  State<EmailSetupPage> createState() => _EmailSetupPageState();
}

class _EmailSetupPageState extends State<EmailSetupPage> {
  String? _token;
  bool _isSettingUp = false;

  // Setup state
  String _domainType = 'tajiri'; // 'tajiri' or 'custom'
  final _customDomainCtrl = TextEditingController();

  // Email accounts
  List<BusinessEmail> _accounts = [];
  bool _isLoadingAccounts = false;

  // Create account
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'info';

  bool get _hasEmailService => widget.business.hasEmailService;
  String get _domain => widget.business.emailDomain ??
      (_domainType == 'tajiri' ? 'tajiri.co.tz' : _customDomainCtrl.text.trim());

  @override
  void initState() {
    super.initState();
    if (widget.business.emailDomainType != null) {
      _domainType = widget.business.emailDomainType!;
    }
    if (widget.business.emailDomain != null && widget.business.emailDomainType == 'custom') {
      _customDomainCtrl.text = widget.business.emailDomain!;
    }
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    if (_hasEmailService) _loadAccounts();
  }

  @override
  void dispose() {
    _customDomainCtrl.dispose();
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    if (_token == null || widget.business.id == null) return;
    setState(() => _isLoadingAccounts = true);
    final result = await BusinessService.getEmailAccounts(_token!, widget.business.id!);
    if (mounted) {
      setState(() {
        _isLoadingAccounts = false;
        if (result.success) _accounts = result.data;
      });
    }
  }

  Future<void> _setupEmailService() async {
    if (_token == null || widget.business.id == null) return;
    if (_domainType == 'custom' && _customDomainCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your domain')),
      );
      return;
    }

    setState(() => _isSettingUp = true);
    final result = await BusinessService.setupEmailService(
      _token!,
      widget.business.id!,
      domainType: _domainType,
      customDomain: _domainType == 'custom' ? _customDomainCtrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _isSettingUp = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email service enabled!')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _createAccount() async {
    if (_token == null || widget.business.id == null) return;
    final username = _usernameCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty || displayName.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all fields')),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be 8 or more characters')),
      );
      return;
    }

    final result = await BusinessService.createEmailAccount(
      _token!,
      widget.business.id!,
      username: username,
      displayName: displayName,
      password: password,
      role: _role,
    );
    if (!mounted) return;

    if (result.success) {
      _usernameCtrl.clear();
      _displayNameCtrl.clear();
      _passwordCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$username@$_domain created!')),
      );
      _loadAccounts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _deleteAccount(BusinessEmail account) async {
    if (_token == null || widget.business.id == null || account.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Delete ${account.address}? All email data will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await BusinessService.deleteEmailAccount(_token!, widget.business.id!, account.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.success ? 'Account deleted' : (result.message ?? 'Failed'))),
      );
      if (result.success) _loadAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg, elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Business Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.email_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text('Business Email', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _hasEmailService
                      ? 'Domain: @$_domain'
                      : 'Get a professional email for your business.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // If not set up yet — domain selection
          if (!_hasEmailService) ...[
            const Text('Choose Domain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text(
              'Your email will look like: name@domain.com',
              style: TextStyle(fontSize: 12, color: _kSecondary),
            ),
            const SizedBox(height: 12),

            // Option 1: @tajiri.co.tz
            _DomainOption(
              isSelected: _domainType == 'tajiri',
              title: 'Use @tajiri.co.tz',
              subtitle: 'Free — e.g. ${widget.business.name.toLowerCase().replaceAll(' ', '')}@tajiri.co.tz',
              icon: Icons.rocket_launch_rounded,
              badge: 'Free',
              onTap: () => setState(() => _domainType = 'tajiri'),
            ),
            const SizedBox(height: 10),

            // Option 2: Custom domain
            _DomainOption(
              isSelected: _domainType == 'custom',
              title: 'Use Your Own Domain',
              subtitle: 'e.g. info@${widget.business.name.toLowerCase().replaceAll(' ', '')}.co.tz',
              icon: Icons.language_rounded,
              badge: null,
              onTap: () => setState(() => _domainType = 'custom'),
            ),

            if (_domainType == 'custom') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customDomainCtrl,
                decoration: InputDecoration(
                  labelText: 'Your Domain',
                  hintText: 'e.g. company.co.tz',
                  helperText: 'You must own this domain. We will send you DNS records to configure.',
                  prefixIcon: const Icon(Icons.language_rounded, color: _kSecondary),
                  filled: true, fillColor: _kCardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'After setup, you will receive DNS records (MX, SPF, DKIM) to add to your domain.',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            SizedBox(
              height: 52, width: double.infinity,
              child: FilledButton(
                onPressed: _isSettingUp ? null : _setupEmailService,
                style: FilledButton.styleFrom(backgroundColor: _kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _isSettingUp
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enable Email Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],

          // If already set up — manage accounts
          if (_hasEmailService) ...[
            // Create new account
            const Text('Create New Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role selector
                  const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      ('info', 'Info (info@)'),
                      ('admin', 'Admin (admin@)'),
                      ('support', 'Support (support@)'),
                      ('sales', 'Sales (sales@)'),
                      ('custom', 'Other'),
                    ].map((r) {
                      final isSelected = _role == r.$1;
                      return ChoiceChip(
                        label: Text(r.$2, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : _kPrimary)),
                        selected: isSelected,
                        selectedColor: _kPrimary,
                        onSelected: (_) {
                          setState(() {
                            _role = r.$1;
                            if (r.$1 != 'custom') _usernameCtrl.text = r.$1;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Username
                  TextField(
                    controller: _usernameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      hintText: 'e.g. info',
                      suffixText: '@$_domain',
                      suffixStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                      filled: true, fillColor: _kBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Display name
                  TextField(
                    controller: _displayNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'e.g. ${widget.business.name}',
                      filled: true, fillColor: _kBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: '8 or more characters',
                      filled: true, fillColor: _kBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    height: 44, width: double.infinity,
                    child: FilledButton(
                      onPressed: _createAccount,
                      style: FilledButton.styleFrom(backgroundColor: _kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: Text(
                        'Create ${_usernameCtrl.text.isNotEmpty ? '${_usernameCtrl.text}@$_domain' : 'Account'}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Existing accounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Email Accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                Text('${_accounts.length}', style: const TextStyle(fontSize: 13, color: _kSecondary)),
              ],
            ),
            const SizedBox(height: 10),

            if (_isLoadingAccounts)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
            else if (_accounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('No accounts yet', style: TextStyle(color: Colors.grey.shade500))),
              )
            else
              ..._accounts.map((account) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.email_rounded, size: 20, color: _kPrimary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(account.address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                              Text(account.displayName, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                            ],
                          ),
                        ),
                        if (account.role != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(account.role!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                          onPressed: () => _deleteAccount(account),
                        ),
                      ],
                    ),
                  )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DomainOption extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _DomainOption({
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _kPrimary : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (isSelected ? _kPrimary : _kSecondary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: isSelected ? _kPrimary : _kSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isSelected ? _kPrimary : _kSecondary)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check_circle_rounded, color: _kPrimary, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
