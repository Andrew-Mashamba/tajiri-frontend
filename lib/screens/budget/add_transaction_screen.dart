// lib/screens/budget/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSuccess = Color(0xFF4CAF50);

class AddTransactionScreen extends StatefulWidget {
  final int? preselectedEnvelopeId;

  const AddTransactionScreen({super.key, this.preselectedEnvelopeId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final BudgetService _service = BudgetService();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  BudgetTransactionType _type = BudgetTransactionType.expense;
  BudgetSource _source = BudgetSource.manual;
  int? _selectedEnvelopeId;
  List<BudgetEnvelope> _envelopes = [];
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEnvelopeId = widget.preselectedEnvelopeId;
    _loadEnvelopes();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEnvelopes() async {
    final envelopes = await _service.getEnvelopes();
    if (mounted) setState(() => _envelopes = envelopes);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weka kiasi sahihi')),
      );
      return;
    }

    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weka maelezo')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await _service.addTransaction(
      envelopeId: _type == BudgetTransactionType.expense ? _selectedEnvelopeId : null,
      amount: amount,
      type: _type,
      source: _source,
      description: desc,
      date: _date,
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: const Text('Ongeza Muamala', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Type toggle
          _buildTypeToggle(),
          const SizedBox(height: 20),

          // Amount
          const Text('Kiasi (TZS)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kPrimary),
            decoration: InputDecoration(
              prefixText: 'TZS ',
              prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kTertiary),
              filled: true,
              fillColor: _kSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          const Text('Maelezo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Mfano: Grocery za wiki',
              hintStyle: const TextStyle(color: _kTertiary),
              filled: true,
              fillColor: _kSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // Envelope (expenses only)
          if (_type == BudgetTransactionType.expense && _envelopes.isNotEmpty) ...[
            const Text('Bahasha', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedEnvelopeId,
                  isExpanded: true,
                  hint: const Text('Chagua bahasha'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Hakuna bahasha')),
                    ..._envelopes.map((e) => DropdownMenuItem<int?>(
                      value: e.id,
                      child: Text(e.name),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedEnvelopeId = v),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Source (income)
          if (_type == BudgetTransactionType.income) ...[
            const Text('Chanzo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [BudgetSource.manual, BudgetSource.salary, BudgetSource.shop, BudgetSource.michango]
                  .map((s) => ChoiceChip(
                        label: Text(s.label),
                        selected: _source == s,
                        onSelected: (_) => setState(() => _source = s),
                        selectedColor: _kPrimary,
                        labelStyle: TextStyle(color: _source == s ? Colors.white : _kPrimary, fontSize: 12),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Date
          const Text('Tarehe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 20, color: _kSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${_date.day}/${_date.month}/${_date.year}',
                    style: const TextStyle(fontSize: 14, color: _kPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Hifadhi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = BudgetTransactionType.expense),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _type == BudgetTransactionType.expense ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Matumizi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _type == BudgetTransactionType.expense ? Colors.white : _kSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = BudgetTransactionType.income),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _type == BudgetTransactionType.income ? _kSuccess : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Mapato',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _type == BudgetTransactionType.income ? Colors.white : _kSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
