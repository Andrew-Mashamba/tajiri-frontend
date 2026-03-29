import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/ad_service.dart';
import '../../services/local_storage_service.dart';

class DepositAdBalanceScreen extends StatefulWidget {
  const DepositAdBalanceScreen({super.key});

  @override
  State<DepositAdBalanceScreen> createState() => _DepositAdBalanceScreenState();
}

class _DepositAdBalanceScreenState extends State<DepositAdBalanceScreen> {
  double _balance = 0.0;
  bool _loading = true;
  bool _showSummary = false;
  bool _submitting = false;
  String? _token;

  final _amountController = TextEditingController();

  static const _presets = [10000.0, 25000.0, 50000.0, 100000.0];
  static const _feeRate = 0.25;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    if (_token == null) return;

    final balance = await AdService.getAdBalance(_token);
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _loading = false;
    });
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  double get _fee => _amount * _feeRate;
  double get _netAmount => _amount - _fee;

  String _formatTZS(double value) {
    // Simple thousands formatting
    final str = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return 'TZS $buf';
  }

  Future<void> _deposit() async {
    if (_token == null || _submitting || _amount <= 0) return;
    setState(() => _submitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final s = AppStringsScope.of(context)!;

    try {
      final result = await AdService.depositAdBalance(_token, _amount);
      final success = result['success'] == true;

      if (success) {
        messenger.showSnackBar(SnackBar(content: Text(s.amanaImefanikiwa)));
        nav.pop(true);
      } else {
        final msg = result['message'] as String? ?? 'Failed';
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.ongezaSalio, maxLines: 1, overflow: TextOverflow.ellipsis),
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Current balance
                  _buildBalanceDisplay(s, isDark),
                  const SizedBox(height: 24),

                  if (!_showSummary) ...[
                    // Amount input
                    Text(
                      s.ongezaKiasi,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        prefixText: 'TZS ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 16),

                    // Preset chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presets.map((preset) {
                        final selected = _amount == preset;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _amountController.text = preset.toStringAsFixed(0);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A))
                                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Text(
                              _formatTZS(preset),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA))
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Continue button
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _amount > 0 ? () => setState(() => _showSummary = true) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                          foregroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(s.continueBtn, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ] else ...[
                    // Summary view
                    _buildSummary(s, isDark),
                    const SizedBox(height: 24),

                    // Back to edit
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showSummary = false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(s.back, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirm button
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _deposit,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                          foregroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(s.thibitisha, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildBalanceDisplay(AppStrings s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        children: [
          Text(
            s.salio,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTZS(_balance),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(AppStrings s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow(s.ongezaKiasi, _formatTZS(_amount), isDark),
          const SizedBox(height: 12),
          _summaryRow(
            '${s.karoYaHuduma}: ${(_feeRate * 100).toStringAsFixed(0)}%',
            _formatTZS(_fee),
            isDark,
          ),
          const Divider(height: 24),
          _summaryRow(
            s.salioLitakaloongezwa,
            _formatTZS(_netAmount),
            isDark,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: bold ? null : (isDark ? const Color(0xFF999999) : const Color(0xFF666666)),
              fontWeight: bold ? FontWeight.bold : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
