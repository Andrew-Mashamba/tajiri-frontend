import 'package:flutter/material.dart';
import '../../models/contribution_models.dart';
import '../../services/contribution_service.dart';
import '../../widgets/cached_media_image.dart';

/// Campaign Withdraw screen – Story 83.
/// Path: Profile → Michango → [Campaign] → Withdraw.
/// Allows organizer to withdraw raised funds to bank or mobile money; requires KYC verification.
class CampaignWithdrawScreen extends StatefulWidget {
  /// Pre-selected campaign (e.g. from campaign detail). If null, user picks from list.
  final Campaign? campaign;
  final int userId;

  const CampaignWithdrawScreen({
    super.key,
    this.campaign,
    required this.userId,
  });

  @override
  State<CampaignWithdrawScreen> createState() => _CampaignWithdrawScreenState();
}

class _CampaignWithdrawScreenState extends State<CampaignWithdrawScreen> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _background = Color(0xFFFAFAFA);

  final ContributionService _contributionService = ContributionService();

  List<Campaign> _campaigns = [];
  List<Withdrawal> _withdrawals = [];
  Campaign? _selectedCampaign;
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;
  String? _submitError;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _destinationType = 'mobile_money'; // 'bank' | 'mobile_money'
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _mobileMoneyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCampaign = widget.campaign;
    if (_selectedCampaign != null) {
      _prefillFromCampaign(_selectedCampaign!);
      _loadWithdrawalsForCampaign(_selectedCampaign!.id);
    } else {
      _loadCampaigns();
    }
  }

  void _prefillFromCampaign(Campaign c) {
    if (c.bankName != null && c.bankName!.isNotEmpty) {
      _bankNameController.text = c.bankName!;
      _accountNumberController.text = c.accountNumber ?? '';
    }
    if (c.mobileMoneyNumber != null && c.mobileMoneyNumber!.isNotEmpty) {
      _mobileMoneyController.text = c.mobileMoneyNumber!;
      _destinationType = 'mobile_money';
    } else if (c.bankName != null && c.bankName!.isNotEmpty) {
      _destinationType = 'bank';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _mobileMoneyController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _contributionService.getUserCampaigns(widget.userId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _campaigns = result.campaigns
            .where((c) =>
                (c.status == CampaignStatus.active ||
                    c.status == CampaignStatus.completed) &&
                c.raisedAmount > 0)
            .toList();
        _error = _campaigns.isEmpty ? 'Hakuna michango yenye salio la kutoa' : null;
      } else {
        _error = result.message ?? 'Imeshindwa kupakia michango';
      }
    });
  }

  Future<void> _loadWithdrawalsForCampaign(int campaignId) async {
    final result = await _contributionService.getCampaignWithdrawals(campaignId);
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _withdrawals = result.withdrawals;
      });
    }
  }

  double get _availableBalance {
    if (_selectedCampaign == null) return 0;
    final completed = _withdrawals
        .where((w) => w.status == WithdrawalStatus.completed)
        .fold<double>(0, (s, w) => s + w.amount);
    return (_selectedCampaign!.raisedAmount - completed).clamp(0.0, double.infinity);
  }

  KycStatus get _kycStatus {
    final organizer = _selectedCampaign?.organizer;
    return organizer?.kycStatus ?? KycStatus.notStarted;
  }

  bool get _canWithdraw => _kycStatus == KycStatus.verified;

  Future<void> _selectCampaign(Campaign campaign) async {
    setState(() {
      _selectedCampaign = campaign;
      _prefillFromCampaign(campaign);
      _withdrawals = [];
      _isLoading = true;
    });
    await _loadWithdrawalsForCampaign(campaign.id);
    if (mounted) setState(() => _isLoading = false);
  }

  void _goBackToCampaignList() {
    setState(() {
      _selectedCampaign = null;
      _amountController.clear();
      _withdrawals = [];
    });
    _loadCampaigns();
  }

  Future<void> _submitWithdrawal() async {
    _submitError = null;
    if (_selectedCampaign == null) return;
    if (!_canWithdraw) {
      setState(() => _submitError =
          'Thibitisha utambulisho wako (KYC) kabla ya kutoa fedha. Wasiliana na msaada.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _submitError = 'Ingiza kiasi halali');
      return;
    }
    if (amount > _availableBalance) {
      setState(() => _submitError =
          'Kiasi kinazidi salio linalopatikana (TSh ${_formatCurrency(_availableBalance)})');
      return;
    }

    String destinationDetails;
    if (_destinationType == 'bank') {
      final bank = _bankNameController.text.trim();
      final account = _accountNumberController.text.trim();
      if (bank.isEmpty || account.isEmpty) {
        setState(() => _submitError = 'Ingiza jina la benki na nambari ya akaunti');
        return;
      }
      destinationDetails = '$bank|$account';
    } else {
      final phone = _mobileMoneyController.text.trim();
      if (phone.isEmpty) {
        setState(() => _submitError = 'Ingiza nambari ya simu (pesa za simu)');
        return;
      }
      destinationDetails = phone;
    }

    setState(() => _isSubmitting = true);
    final result = await _contributionService.requestWithdrawal(
      _selectedCampaign!.id,
      amount: amount,
      destinationType: _destinationType,
      destinationDetails: destinationDetails,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ombi lako la kutoa fedha limepokelewa. Utawasilishwa hali yake.'),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
      await _loadWithdrawalsForCampaign(_selectedCampaign!.id);
      _amountController.clear();
      if (mounted) setState(() {});
    } else {
      setState(() => _submitError = result.message ?? 'Imeshindwa kutuma ombi');
    }
  }

  String _formatCurrency(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        title: Text(
          _selectedCampaign == null ? 'Kutoa Fedha za Mchango' : 'Kutoa Fedha',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _primary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selectedCampaign != null && widget.campaign == null) {
              _goBackToCampaignList();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: _isLoading && _selectedCampaign == null
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _error != null && _selectedCampaign == null
                ? _buildErrorState()
                : _selectedCampaign == null
                    ? _buildCampaignList()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildKycBanner(),
                              const SizedBox(height: 16),
                              _buildBalanceCard(),
                              const SizedBox(height: 24),
                              _buildAmountField(),
                              const SizedBox(height: 20),
                              _buildDestinationSection(),
                              if (_submitError != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _submitError!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _buildSubmitButton(),
                              const SizedBox(height: 24),
                              _buildWithdrawalHistory(),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _secondary),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _secondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Rudi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _campaigns.length,
      itemBuilder: (context, index) {
        final c = _campaigns[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: const BoxConstraints(minHeight: 72),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            child: InkWell(
              onTap: () => _selectCampaign(c),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (c.coverImageUrl != null && c.coverImageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedMediaImage(
                          imageUrl: c.coverImageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.volunteer_activism, color: _primary, size: 28),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TSh ${_formatCurrency(c.raisedAmount)} imekusanywa',
                            style: const TextStyle(fontSize: 12, color: _secondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: _secondary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKycBanner() {
    if (_canWithdraw) return const SizedBox.shrink();
    final String message;
    switch (_kycStatus) {
      case KycStatus.notStarted:
        message = 'Thibitisha utambulisho wako (KYC) ili kutoa fedha za mchango.';
        break;
      case KycStatus.pending:
        message = 'Thibitisho lako (KYC) linasubiri kukaguliwa. Huwezi kutoa fedha hadi lipothibitishwa.';
        break;
      case KycStatus.rejected:
        message = 'Thibitisho lako (KYC) limekataliwa. Wasiliana na msaada ili kurekebisha.';
        break;
      case KycStatus.verified:
        message = '';
    }
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Salio linalopatikana',
            style: TextStyle(fontSize: 12, color: _secondary),
          ),
          const SizedBox(height: 4),
          Text(
            'TSh ${_formatCurrency(_availableBalance)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primary),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Kiasi (TSh)',
        hintText: 'Ingiza kiasi unachotaka kutoa',
        prefixText: 'TSh ',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Ingiza kiasi';
        final n = double.tryParse(v.trim().replaceAll(',', ''));
        if (n == null || n <= 0) return 'Ingiza kiasi halali';
        if (n > _availableBalance) return 'Kiasi kinazidi salio';
        return null;
      },
    );
  }

  Widget _buildDestinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pokezi',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDestinationChip('mobile_money', 'Pesa za Simu', Icons.phone_android),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDestinationChip('bank', 'Benki', Icons.account_balance),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_destinationType == 'bank') ...[
          TextFormField(
            controller: _bankNameController,
            decoration: const InputDecoration(
              labelText: 'Jina la benki',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (v) {
              if (_destinationType != 'bank') return null;
              if (v == null || v.trim().isEmpty) return 'Ingiza jina la benki';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nambari ya akaunti',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (v) {
              if (_destinationType != 'bank') return null;
              if (v == null || v.trim().isEmpty) return 'Ingiza nambari ya akaunti';
              return null;
            },
          ),
        ] else
          TextFormField(
            controller: _mobileMoneyController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nambari ya simu (M-Pesa, Tigo Pesa, Airtel)',
              hintText: '07XXXXXXXX',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (v) {
              if (_destinationType != 'mobile_money') return null;
              if (v == null || v.trim().isEmpty) return 'Ingiza nambari ya simu';
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildDestinationChip(String value, String label, IconData icon) {
    final selected = _destinationType == value;
    return Material(
      color: selected ? _primary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => setState(() => _destinationType = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: selected ? Colors.white : _primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      child: Material(
        color: _canWithdraw ? _primary : _secondary,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: _canWithdraw && !_isSubmitting ? _submitWithdrawal : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _canWithdraw ? 'Tuma ombi la kutoa' : 'Thibitisha KYC kwanza',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawalHistory() {
    if (_withdrawals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historia ya matoleo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary),
        ),
        const SizedBox(height: 12),
        ..._withdrawals.take(10).map((w) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TSh ${_formatCurrency(w.amount)} - ${w.destinationType == 'bank' ? 'Benki' : 'Pesa za simu'}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _statusText(w.status),
                          style: const TextStyle(fontSize: 12, color: _secondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(w.createdAt),
                    style: const TextStyle(fontSize: 11, color: _secondary),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _statusText(WithdrawalStatus s) {
    switch (s) {
      case WithdrawalStatus.pending:
        return 'Inasubiri';
      case WithdrawalStatus.approved:
        return 'Imekubaliwa';
      case WithdrawalStatus.processing:
        return 'Inachakata';
      case WithdrawalStatus.completed:
        return 'Imekamilika';
      case WithdrawalStatus.rejected:
        return 'Imekataliwa';
      case WithdrawalStatus.failed:
        return 'Imeshindwa';
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
