// lib/my_wallet/pages/mobile_accounts_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class MobileAccountsPage extends StatefulWidget {
  final int userId;
  const MobileAccountsPage({super.key, required this.userId});

  @override
  State<MobileAccountsPage> createState() => _MobileAccountsPageState();
}

class _MobileAccountsPageState extends State<MobileAccountsPage> {
  final WalletService _walletService = WalletService();

  List<MobileMoneyAccount> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final result = await _walletService.getMobileAccounts(widget.userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) _accounts = result.accounts;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addAccount() async {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    String selectedProvider = 'mpesa';
    final isSwahili = _isSwahili;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSwahili ? 'Ongeza Akaunti' : 'Add Account',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Provider
                  Text(isSwahili ? 'Mtoa Huduma' : 'Provider', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ('mpesa', 'M-Pesa'),
                      ('tigopesa', 'Tigo Pesa'),
                      ('airtelmoney', 'Airtel Money'),
                      ('halopesa', 'Halo Pesa'),
                    ].map((p) {
                      final isSelected = selectedProvider == p.$1;
                      return ChoiceChip(
                        label: Text(p.$2, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: _kPrimary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : _kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setSheetState(() => selectedProvider = p.$1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: isSwahili ? 'Nambari ya Simu' : 'Phone Number',
                      hintText: '0712 345 678',
                      filled: true,
                      fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Account name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: isSwahili ? 'Jina la Akaunti' : 'Account Name',
                      hintText: isSwahili ? 'Mfano: Simu yangu ya M-Pesa' : 'E.g.: My M-Pesa phone',
                      filled: true,
                      fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        if (phoneController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
                          return;
                        }
                        try {
                          final addResult = await _walletService.addMobileAccount(
                            userId: widget.userId,
                            provider: selectedProvider,
                            phoneNumber: phoneController.text.trim(),
                            accountName: nameController.text.trim(),
                          );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext, addResult.success);
                          }
                        } catch (_) {
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext, false);
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isSwahili ? 'Ongeza' : 'Add',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    phoneController.dispose();
    nameController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSwahili ? 'Akaunti imeongezwa' : 'Account added')),
      );
      _loadAccounts();
    }
  }

  Future<void> _deleteAccount(MobileMoneyAccount account) async {
    final isSwahili = _isSwahili;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSwahili ? 'Futa Akaunti' : 'Delete Account'),
        content: Text(isSwahili
            ? 'Una uhakika unataka kufuta "${account.accountName}"?'
            : 'Are you sure you want to delete "${account.accountName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isSwahili ? 'Hapana' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _walletService.deleteMobileAccount(
          userId: widget.userId,
          accountId: account.id,
        );
        if (mounted) {
          if (success) {
            _loadAccounts();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isSwahili ? 'Imeshindwa kufuta akaunti' : 'Failed to delete account')),
            );
          }
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isSwahili ? 'Hitilafu imetokea' : 'An error occurred')),
          );
        }
      }
    }
  }

  Future<void> _setPrimary(MobileMoneyAccount account) async {
    try {
      final success = await _walletService.setPrimaryAccount(
        userId: widget.userId,
        accountId: account.id,
      );
      if (mounted && success) {
        _loadAccounts();
      }
    } catch (_) {
      // Silently handle
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSwahili ? 'Akaunti za Simu' : 'Mobile Accounts',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _addAccount,
            tooltip: isSwahili ? 'Ongeza Akaunti' : 'Add Account',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _accounts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          isSwahili ? 'Hakuna akaunti za simu' : 'No mobile accounts',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _addAccount,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(isSwahili ? 'Ongeza Akaunti' : 'Add Account'),
                          style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAccounts,
                    color: _kPrimary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _accounts.length,
                      itemBuilder: (context, index) {
                        final account = _accounts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kCardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: account.isPrimary
                                ? Border.all(color: _kPrimary, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.phone_android_rounded, color: _kPrimary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            account.accountName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _kPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (account.isPrimary) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _kPrimary,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isSwahili ? 'Kuu' : 'Primary',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${account.providerName} • ${account.maskedPhone}',
                                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: _kSecondary, size: 20),
                                onSelected: (value) {
                                  if (value == 'primary') _setPrimary(account);
                                  if (value == 'delete') _deleteAccount(account);
                                },
                                itemBuilder: (context) => [
                                  if (!account.isPrimary)
                                    PopupMenuItem(
                                      value: 'primary',
                                      child: Text(isSwahili ? 'Fanya Akaunti Kuu' : 'Set as Primary'),
                                    ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      isSwahili ? 'Futa' : 'Delete',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
