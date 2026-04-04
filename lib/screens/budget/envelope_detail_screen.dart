// lib/screens/budget/envelope_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';
import 'add_transaction_screen.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kError = Color(0xFFE53935);
const Color _kWarning = Color(0xFFFF9800);

class EnvelopeDetailScreen extends StatefulWidget {
  final BudgetEnvelope envelope;

  const EnvelopeDetailScreen({super.key, required this.envelope});

  @override
  State<EnvelopeDetailScreen> createState() => _EnvelopeDetailScreenState();
}

class _EnvelopeDetailScreenState extends State<EnvelopeDetailScreen> {
  final BudgetService _service = BudgetService();
  List<BudgetTransaction> _transactions = [];
  BudgetEnvelope? _envelope;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _envelope = widget.envelope;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final txns = await _service.getTransactions(
      envelopeId: widget.envelope.id,
      from: monthStart,
      to: monthEnd,
      limit: 100,
    );

    // Refresh envelope data
    final envelopes = await _service.getEnvelopes();
    final updated = envelopes.firstWhere(
      (e) => e.id == widget.envelope.id,
      orElse: () => widget.envelope,
    );

    if (mounted) {
      setState(() {
        _transactions = txns;
        _envelope = updated;
        _isLoading = false;
      });
    }
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(preselectedEnvelopeId: widget.envelope.id),
      ),
    );
    if (result == true) _loadTransactions();
  }

  Future<void> _editAllocation() async {
    final controller = TextEditingController(
      text: _envelope!.allocatedAmount.toStringAsFixed(0),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Badilisha Kiasi'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: 'TZS ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            child: const Text('Hifadhi'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null && result >= 0) {
      await _service.updateEnvelope(_envelope!.copyWith(allocatedAmount: result));
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final env = _envelope ?? widget.envelope;
    final pct = env.percentUsed.clamp(0, 100) / 100;
    final isOver = env.isOverBudget;
    final barColor = isOver ? _kError : (pct > 0.8 ? _kWarning : _kPrimary);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(env.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Badilisha kiasi',
            onPressed: _editAllocation,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Text(
                    isOver
                        ? '-TZS ${(env.spentAmount - env.allocatedAmount).toStringAsFixed(0)}'
                        : 'TZS ${env.remainingAmount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isOver ? _kError : _kPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOver ? 'Umezidi bajeti' : 'Imebaki',
                    style: TextStyle(fontSize: 13, color: isOver ? _kError : _kTertiary),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: _kDivider,
                      valueColor: AlwaysStoppedAnimation(barColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Imetumika: TZS ${env.spentAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      Text('Bajeti: TZS ${env.allocatedAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Transactions header
            Row(
              children: [
                const Text('MIAMALA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8)),
                const Spacer(),
                Text('${_transactions.length}', style: const TextStyle(fontSize: 12, color: _kTertiary)),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Hakuna miamala bado', style: TextStyle(color: _kTertiary))),
              )
            else
              ..._transactions.map((txn) => _buildTransactionTile(txn)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionTile(BudgetTransaction txn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kDivider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.description, style: const TextStyle(fontSize: 13, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${txn.date.day}/${txn.date.month} • ${txn.source.label}',
                  style: const TextStyle(fontSize: 11, color: _kTertiary),
                ),
              ],
            ),
          ),
          Text(
            'TZS ${txn.amount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
        ],
      ),
    );
  }
}
