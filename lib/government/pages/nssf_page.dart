// lib/government/pages/nssf_page.dart
import 'package:flutter/material.dart';
import '../models/government_models.dart';
import '../services/government_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class NssfPage extends StatefulWidget {
  final int userId;
  const NssfPage({super.key, required this.userId});
  @override
  State<NssfPage> createState() => _NssfPageState();
}

class _NssfPageState extends State<NssfPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GovernmentService _service = GovernmentService();
  final _memberController = TextEditingController();
  final _salaryController = TextEditingController();
  final _yearsController = TextEditingController();

  NssfInfo? _memberInfo;
  bool _isSearching = false;
  String? _error;

  // Calculator
  bool _isCalculating = false;
  Map<String, dynamic>? _calcResult;
  String? _calcError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memberController.dispose();
    _salaryController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final number = _memberController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza nambari ya mwanachama')),
      );
      return;
    }

    setState(() { _isSearching = true; _error = null; _memberInfo = null; });

    final result = await _service.lookupNssf(
      userId: widget.userId,
      memberNumber: number,
    );

    if (mounted) {
      setState(() {
        _isSearching = false;
        if (result.success && result.data != null) {
          _memberInfo = result.data;
        } else {
          _error = result.message ?? 'Imeshindwa kutafuta';
        }
      });
    }
  }

  Future<void> _calculate() async {
    final salary = double.tryParse(_salaryController.text.trim());
    final years = int.tryParse(_yearsController.text.trim());

    if (salary == null || salary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza mshahara halali')),
      );
      return;
    }
    if (years == null || years <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza miaka halali')),
      );
      return;
    }

    setState(() { _isCalculating = true; _calcError = null; _calcResult = null; });

    final result = await _service.calculateNssfContribution(
      monthlySalary: salary,
      years: years,
    );

    if (mounted) {
      setState(() {
        _isCalculating = false;
        if (result.success && result.data != null) {
          _calcResult = result.data;
        } else {
          _calcError = result.message ?? 'Imeshindwa kuhesabu';
        }
      });
    }
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('NSSF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: const [
            Tab(text: 'Hali ya Michango'),
            Tab(text: 'Kihesabu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLookupTab(),
          _buildCalculatorTab(),
        ],
      ),
    );
  }

  Widget _buildLookupTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mfuko wa Taifa wa Hifadhi ya Jamii', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('National Social Security Fund', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Nambari ya Mwanachama', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _memberController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: 'NSSF Member Number',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: _kSecondary),
            filled: true, fillColor: _kCardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _isSearching ? null : _lookup,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSearching
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Angalia Hali', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),

        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: TextStyle(fontSize: 13, color: Colors.red.shade700))),
              ],
            ),
          ),

        if (_memberInfo != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _memberInfo!.isActive
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _memberInfo!.isActive ? Icons.check_circle_rounded : Icons.pending_rounded,
                      color: _memberInfo!.isActive ? const Color(0xFF4CAF50) : Colors.orange,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _memberInfo!.isActive ? 'Mwanachama Hai' : 'Hali: ${_memberInfo!.status}',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: _memberInfo!.isActive ? const Color(0xFF4CAF50) : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (_memberInfo!.memberName != null) _InfoRow(label: 'Jina', value: _memberInfo!.memberName!),
                _InfoRow(label: 'Nambari', value: _memberInfo!.memberNumber),
                _InfoRow(label: 'Michango', value: 'TZS ${_fmt(_memberInfo!.totalContributions)}'),
                _InfoRow(label: 'Miezi', value: '${_memberInfo!.monthsContributed}'),
                if (_memberInfo!.employer != null) _InfoRow(label: 'Mwajiri', value: _memberInfo!.employer!),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCalculatorTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.calculate_rounded, size: 22, color: _kPrimary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hesabu michango yako ya NSSF kulingana na mshahara na miaka ya kazi.',
                  style: TextStyle(fontSize: 13, color: _kSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Mshahara wa Mwezi (TZS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _salaryController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Mfano: 500000',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.payments_outlined, color: _kSecondary),
            filled: true, fillColor: _kCardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
          ),
        ),
        const SizedBox(height: 14),

        const Text('Miaka ya Kazi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _yearsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Mfano: 10',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.work_outline, color: _kSecondary),
            filled: true, fillColor: _kCardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _isCalculating ? null : _calculate,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isCalculating
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Hesabu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),

        if (_calcError != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_calcError!, style: TextStyle(fontSize: 13, color: Colors.red.shade700))),
              ],
            ),
          ),

        if (_calcResult != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Matokeo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                const Divider(height: 20),
                if (_calcResult!['employee_contribution'] != null)
                  _InfoRow(label: 'Mchango wa Mfanyakazi', value: 'TZS ${_fmt((_calcResult!['employee_contribution'] as num).toDouble())}/mwezi'),
                if (_calcResult!['employer_contribution'] != null)
                  _InfoRow(label: 'Mchango wa Mwajiri', value: 'TZS ${_fmt((_calcResult!['employer_contribution'] as num).toDouble())}/mwezi'),
                if (_calcResult!['total_monthly'] != null)
                  _InfoRow(label: 'Jumla/Mwezi', value: 'TZS ${_fmt((_calcResult!['total_monthly'] as num).toDouble())}'),
                if (_calcResult!['total_projected'] != null) ...[
                  const Divider(height: 20),
                  _InfoRow(label: 'Jumla Baada ya Miaka', value: 'TZS ${_fmt((_calcResult!['total_projected'] as num).toDouble())}'),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary))),
        ],
      ),
    );
  }
}
