// lib/my_parents/pages/insurance_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_parents_models.dart';
import '../services/my_parents_service.dart';
import '../services/parents_notification_helper.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kWarning = Color(0xFFFFA726);

class InsurancePage extends StatefulWidget {
  final Parent parent;

  const InsurancePage({super.key, required this.parent});

  @override
  State<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends State<InsurancePage> {
  final MyParentsService _service = MyParentsService();
  String? _token;
  bool _isLoading = true;
  List<FinancialSupport> _insurancePayments = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadInsuranceData();
  }

  Future<void> _loadInsuranceData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getSupportHistory(_token!, widget.parent.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _insurancePayments = result.items
              .where((s) => s.type == 'insurance')
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          // Schedule NHIF renewal reminder if we have NHIF info
          _scheduleNhifReminder();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Imeshindikana kupakia data'
            : 'Failed to load data')),
      );
    }
  }

  /// Fire-and-forget: schedule NHIF renewal reminder if NHIF status is not active.
  void _scheduleNhifReminder() {
    if (!_hasNhif) return;
    if (widget.parent.nhifStatus == 'expired' || widget.parent.nhifStatus == 'suspended') {
      // Schedule reminder for 30 days from now as a nudge to renew
      try {
        ParentsNotificationHelper.scheduleNhifRenewalReminder(
          widget.parent.id,
          widget.parent.name,
          DateTime.now().add(const Duration(days: 30)),
          _sw,
        );
      } catch (_) {}
    }
  }

  double get _totalInsurancePaid =>
      _insurancePayments.fold(0.0, (sum, p) => sum + p.amount);

  double get _yearlyInsurancePaid {
    final now = DateTime.now();
    return _insurancePayments
        .where((p) => p.date.year == now.year)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  bool get _hasNhif =>
      widget.parent.nhifNumber != null &&
      widget.parent.nhifNumber!.isNotEmpty;

  String _nhifStatusLabel(String? status, bool sw) {
    switch (status) {
      case 'active':
        return sw ? 'Inatumika' : 'Active';
      case 'expired':
        return sw ? 'Imekwisha' : 'Expired';
      case 'suspended':
        return sw ? 'Imesimamishwa' : 'Suspended';
      default:
        return sw ? 'Haijulikani' : 'Unknown';
    }
  }

  Color _nhifStatusColor(String? status) {
    switch (status) {
      case 'active':
        return _kSuccess;
      case 'expired':
      case 'suspended':
        return _kWarning;
      default:
        return _kSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Bima ya Afya' : 'Health Insurance',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadInsuranceData,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // NHIF Card
                  _buildNhifCard(sw),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickAction(
                    icon: Icons.autorenew_rounded,
                    label: sw ? 'Fanya Upya NHIF' : 'Renew NHIF',
                    subtitle: sw
                        ? 'Lipia bima ya NHIF'
                        : 'Pay NHIF insurance premium',
                    onTap: () {
                      Navigator.pushNamed(context, '/insurance');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildQuickAction(
                    icon: Icons.search_rounded,
                    label: sw ? 'Tafuta Bima ya Afya' : 'Browse Health Insurance',
                    subtitle: sw
                        ? 'Linganisha mipango ya bima'
                        : 'Compare insurance plans',
                    onTap: () {
                      Navigator.pushNamed(context, '/insurance');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildQuickAction(
                    icon: Icons.receipt_long_rounded,
                    label: sw ? 'Tazama Madai' : 'View Claims',
                    subtitle: sw
                        ? 'Historia ya madai ya bima'
                        : 'Insurance claim history',
                    onTap: () {
                      Navigator.pushNamed(context, '/insurance');
                    },
                  ),
                  const SizedBox(height: 24),

                  // Insurance payment summary
                  if (_insurancePayments.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(sw ? 'Mwaka Huu' : 'This Year',
                                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
                                const SizedBox(height: 4),
                                Text('TSh ${_formatAmount(_yearlyInsurancePaid)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 32, color: _kPrimary.withValues(alpha: 0.08)),
                          Expanded(
                            child: Column(
                              children: [
                                Text(sw ? 'Jumla' : 'All Time',
                                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
                                const SizedBox(height: 4),
                                Text('TSh ${_formatAmount(_totalInsurancePaid)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Payment History
                  Text(
                    sw ? 'Historia ya Malipo ya Bima' : 'Insurance Payment History',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  const SizedBox(height: 12),
                  if (_insurancePayments.isEmpty)
                    _buildEmptyPayments(sw)
                  else
                    ..._insurancePayments.map((p) => _buildPaymentCard(p, sw)),

                  const SizedBox(height: 20),

                  // Cross-module links
                  _buildCrossModuleLink(
                    icon: Icons.account_balance_wallet_rounded,
                    label: sw
                        ? 'Tazama Bajeti ya Bima'
                        : 'View Insurance Budget',
                    onTap: () {
                      Navigator.pushNamed(context, '/budget');
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildCrossModuleLink(
                    icon: Icons.smart_toy_rounded,
                    label: sw
                        ? 'Uliza Shangazi kuhusu bima ya afya'
                        : 'Ask Shangazi about health insurance',
                    onTap: () {
                      Navigator.pushNamed(context, '/chat/0');
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildNhifCard(bool sw) {
    final statusColor = _nhifStatusColor(widget.parent.nhifStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_rounded,
                  size: 24, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'NHIF',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9)),
              ),
              const Spacer(),
              if (_hasNhif)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _nhifStatusLabel(widget.parent.nhifStatus, sw),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_hasNhif) ...[
            Text(
              sw ? 'Nambari ya NHIF' : 'NHIF Number',
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 4),
            Text(
              widget.parent.nhifNumber!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.parent.name,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7)),
            ),
          ] else ...[
            Text(
              sw
                  ? 'Nambari ya NHIF haijasajiliwa'
                  : 'No NHIF number registered',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              sw
                  ? 'Ongeza nambari ya NHIF kwenye wasifu wa mzazi'
                  : 'Add NHIF number in parent profile',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPayments(bool sw) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            sw ? 'Hakuna malipo ya bima' : 'No insurance payments',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(FinancialSupport payment, bool sw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.health_and_safety_rounded,
                size: 18, color: Color(0xFF42A5F5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Bima' : 'Insurance',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                if (payment.description != null && payment.description!.isNotEmpty)
                  Text(payment.description!,
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TSh ${_formatAmount(payment.amount)}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              Text(
                '${payment.date.day}/${payment.date.month}/${payment.date.year}',
                style: const TextStyle(fontSize: 10, color: _kSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 13, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
