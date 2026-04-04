/// Guarantee Terms Screen
///
/// Shows detailed terms and liability information before guarantor approves.

import 'package:flutter/material.dart';
import '../../models/loan_models.dart';
import 'package:intl/intl.dart';

class GuaranteeTermsScreen extends StatefulWidget {
  final LoanApplication application;
  final Guarantor? guarantor;
  final Future<void> Function() onAccept;
  final Future<void> Function(String reason) onReject;

  const GuaranteeTermsScreen({
    Key? key,
    required this.application,
    this.guarantor,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  State<GuaranteeTermsScreen> createState() => _GuaranteeTermsScreenState();
}

class _GuaranteeTermsScreenState extends State<GuaranteeTermsScreen> {
  bool _termsAccepted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masharti ya Udhamini'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan summary card
            _LoanSummaryCard(application: widget.application),
            const SizedBox(height: 16),

            // Guarantee amount card
            if (widget.guarantor != null)
              _GuaranteeAmountCard(
                amount: widget.guarantor!.guaranteedAmount,
                totalLoan: widget.application.loanDetails.principalAmount,
              ),
            const SizedBox(height: 16),

            // Terms card
            _TermsCard(),
            const SizedBox(height: 16),

            // Liability warning card
            _LiabilityWarningCard(),
            const SizedBox(height: 16),

            // What happens on default
            _DefaultConsequencesCard(),
            const SizedBox(height: 24),

            // Terms acceptance checkbox
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (value) {
                      setState(() => _termsAccepted = value ?? false);
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _termsAccepted = !_termsAccepted);
                      },
                      child: const Text(
                        'Nimesoma na kukubali masharti yote ya udhamini',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _showRejectDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Kataa'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _termsAccepted && !_isLoading ? _handleAccept : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Kubali'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);

    try {
      await widget.onAccept();
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Umeidhinisha kikamilifu'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imeshindikana: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kataa Udhamini'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tafadhali eleza sababu ya kukataa:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Andika sababu...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tafadhali andika sababu')),
                );
                return;
              }
              Navigator.pop(context);
              await _handleReject(reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kataa'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReject(String reason) async {
    setState(() => _isLoading = true);

    try {
      await widget.onReject(reason);
      if (mounted) {
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Umekataa udhamini'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imeshindikana: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}

class _LoanSummaryCard extends StatelessWidget {
  final LoanApplication application;

  const _LoanSummaryCard({required this.application});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    _getInitials(application.applicantName),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mkopaji',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        application.applicantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _DetailRow(
              label: 'Kiasi cha Mkopo',
              value: 'TSh ${_formatAmount(application.loanDetails.principalAmount)}',
              isBold: true,
            ),
            if (application.loanProduct?.name != null)
              _DetailRow(
                label: 'Bidhaa',
                value: application.loanProduct!.name,
              ),
            _DetailRow(
              label: 'Muda',
              value: '${application.loanDetails.tenure} miezi',
            ),
            _DetailRow(
              label: 'Riba',
              value: '${application.loanDetails.interestRate}%',
            ),
            _DetailRow(
              label: 'Malipo ya Kila Mwezi',
              value: 'TSh ${_formatAmount(application.calculations.monthlyInstallment)}',
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }
}

class _GuaranteeAmountCard extends StatelessWidget {
  final double amount;
  final double totalLoan;

  const _GuaranteeAmountCard({
    required this.amount,
    required this.totalLoan,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalLoan > 0 ? (amount / totalLoan * 100) : 0;

    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Kiasi Unachokidhamini',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'TSh ${_formatAmount(amount)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${percentage.toStringAsFixed(1)}% ya mkopo',
                style: TextStyle(
                  color: Colors.blue.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }
}

class _TermsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Masharti ya Udhamini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...[
              '1. Ukikubali kudhamini, unawajibika kisheria kulipa deni kama mkopaji atashindwa.',
              '2. Mkopaji akishindwa kulipa, akiba yako (Hisa na Akiba) itatumika kulipa deni.',
              '3. Unaweza kuondoka kwenye udhamini KABLA mkopo haujaidhinishwa tu.',
              '4. BAADA ya mkopo kutolewa, huwezi kuondoka mpaka mkopo ulipwe kikamilifu.',
              '5. Utapokea taarifa za malipo ya mkopaji kila mwezi.',
              '6. Unaweza kuwa mdhamini wa mikopo mingi lakini ndani ya kikomo chako.',
            ].map((term) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          term,
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _LiabilityWarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Text(
                  'Onyo Muhimu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Ukikubali kudhamini mkopo huu, unakubali kwamba:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              'Akiba yako ya Hisa na Akiba inaweza kutumika kulipa deni',
              'Utawajibishwa kisheria kama mkopaji akishindwa kulipa',
              'Huwezi kuondoka kwenye udhamini baada ya mkopo kutolewa',
              'Wadhamini wote wana wajibu wa pamoja kulipa deni',
            ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _DefaultConsequencesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dangerous, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Mkopaji Akishindwa Kulipa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...[
              'Utapokea taarifa ya malipo yaliyochelewa',
              'Akiba yako itakatwa kiasi kilichobaki cha deni',
              'Ikiwa akiba haitoshi, utawajibishwa kisheria',
              'Rekodi yako ya udhamini itaathiriwa',
              'Unaweza kuzuiliwa kudhamini mikopo mingine',
            ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right, color: Colors.red.shade700, size: 20),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
