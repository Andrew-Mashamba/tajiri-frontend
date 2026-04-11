import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';
import '../widgets/earnings_module_breakdown.dart';

class EarningsOverviewPage extends StatefulWidget {
  const EarningsOverviewPage({super.key});

  @override
  State<EarningsOverviewPage> createState() => _EarningsOverviewPageState();
}

class _EarningsOverviewPageState extends State<EarningsOverviewPage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  PartnerEarnings _earnings = PartnerEarnings();
  Map<String, double> _byModule = {};
  List<Payout> _payoutHistory = [];
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = 'monthly'; // 'weekly' | 'monthly'
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    _userId ??= storage.getUser()?.userId;
    return storage.getAuthToken();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null || _userId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated';
        });
        return;
      }

      final results = await Future.wait([
        TajirikaService.getEarnings(token, _userId!, period: _selectedPeriod),
        TajirikaService.getEarningsByModule(token, _userId!),
        TajirikaService.getPayoutHistory(token, _userId!),
      ]);

      if (!mounted) return;
      setState(() {
        _earnings = results[0] as PartnerEarnings;
        _byModule = results[1] as Map<String, double>;
        final payoutResult = results[2] as PayoutListResult;
        _payoutHistory = payoutResult.success ? payoutResult.payouts : [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showWithdrawDialog() async {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final amountController = TextEditingController();
    String selectedMethod = 'mpesa';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                sw ? 'Toa Pesa' : 'Withdraw',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw
                        ? 'Kiasi kinachopatikana: TZS ${_earnings.pendingPayout.toStringAsFixed(0)}'
                        : 'Available: TZS ${_earnings.pendingPayout.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: sw ? 'Kiasi (TZS)' : 'Amount (TZS)',
                      labelStyle: const TextStyle(color: _kSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    sw ? 'Njia ya malipo' : 'Payout method',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kPrimary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'mpesa',
                        child: Text('M-Pesa'),
                      ),
                      DropdownMenuItem(
                        value: 'tigopesa',
                        child: Text('Tigo Pesa'),
                      ),
                      DropdownMenuItem(
                        value: 'airtelmoney',
                        child: Text('Airtel Money'),
                      ),
                      DropdownMenuItem(
                        value: 'bank',
                        child: Text('Bank Transfer'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedMethod = v);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    sw ? 'Ghairi' : 'Cancel',
                    style: const TextStyle(color: _kSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount =
                        double.tryParse(amountController.text.trim());
                    if (amount == null ||
                        amount <= 0 ||
                        amount > _earnings.pendingPayout) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            sw
                                ? 'Kiasi si sahihi'
                                : 'Invalid amount',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(sw ? 'Thibitisha' : 'Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) return;

    try {
      final token = await _getToken();
      if (token == null || _userId == null) return;

      final result = await TajirikaService.requestPayout(
        token,
        _userId!,
        amount,
        selectedMethod,
      );

      if (!mounted) return;

      final sw2 = AppStringsScope.of(context)?.isSwahili ?? false;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sw2
                  ? 'Ombi la malipo limetumwa'
                  : 'Payout request submitted',
            ),
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? (sw2 ? 'Imeshindwa' : 'Failed')),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _payoutStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'processing':
        return const Color(0xFFFFA726);
      case 'failed':
        return const Color(0xFFE53935);
      default:
        return _kSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          sw ? 'Muhtasari wa Mapato' : 'Earnings Overview',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kPrimary),
        elevation: 0.5,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _error != null
                ? _buildError(sw)
                : RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPeriodToggle(sw),
                          const SizedBox(height: 16),
                          _buildTotalEarningsCard(sw),
                          const SizedBox(height: 16),
                          _buildModuleBreakdown(sw),
                          const SizedBox(height: 16),
                          _buildPendingPayoutCard(sw),
                          const SizedBox(height: 24),
                          _buildPayoutHistory(sw),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildError(bool sw) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
          const SizedBox(height: 12),
          Text(
            _error ?? (sw ? 'Hitilafu' : 'Error'),
            style: const TextStyle(fontSize: 14, color: _kSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadData,
            child: Text(
              sw ? 'Jaribu tena' : 'Try again',
              style: const TextStyle(color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(bool sw) {
    return Center(
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: 'weekly',
            label: Text(sw ? 'Wiki' : 'Weekly'),
          ),
          ButtonSegment(
            value: 'monthly',
            label: Text(sw ? 'Mwezi' : 'Monthly'),
          ),
        ],
        selected: {_selectedPeriod},
        onSelectionChanged: (selection) {
          setState(() => _selectedPeriod = selection.first);
          _loadData();
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _kPrimary;
            }
            return Colors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return _kPrimary;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalEarningsCard(bool sw) {
    final amount = _selectedPeriod == 'weekly'
        ? _earnings.weeklyEarnings
        : _earnings.monthlyEarnings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            sw ? 'Jumla ya mapato' : 'Total earnings',
            style: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 8),
          Text(
            'TZS ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _selectedPeriod == 'weekly'
                ? (sw ? 'Wiki hii' : 'This week')
                : (sw ? 'Mwezi huu' : 'This month'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleBreakdown(bool sw) {
    if (_byModule.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Mapato kwa Moduli' : 'Earnings by Module',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          EarningsModuleBreakdown(byModule: _byModule),
        ],
      ),
    );
  }

  Widget _buildPendingPayoutCard(bool sw) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Malipo yanayosubiri' : 'Pending payout',
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'TZS ${_earnings.pendingPayout.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _earnings.pendingPayout > 0 ? _showWithdrawDialog : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(sw ? 'Toa Pesa' : 'Withdraw'),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutHistory(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Historia ya Malipo' : 'Payout History',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_payoutHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 40,
                  color: _kSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  sw ? 'Hakuna historia bado' : 'No payout history yet',
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                ),
              ],
            ),
          )
        else
          ...List.generate(_payoutHistory.length, (i) {
            final payout = _payoutHistory[i];
            return _buildPayoutItem(payout, sw);
          }),
      ],
    );
  }

  Widget _buildPayoutItem(Payout payout, bool sw) {
    final statusColor = _payoutStatusColor(payout.status);
    final dateStr =
        '${payout.createdAt.day}/${payout.createdAt.month}/${payout.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(payout.methodIcon, size: 20, color: _kSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payout.methodLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TZS ${payout.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sw ? payout.statusLabelSwahili : payout.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
