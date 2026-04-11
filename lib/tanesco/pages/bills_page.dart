// lib/tanesco/pages/bills_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/budget_context_banner.dart';
import '../models/tanesco_models.dart';
import '../services/tanesco_service.dart';
import '../widgets/bill_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BillsPage extends StatefulWidget {
  final Meter meter;
  const BillsPage({super.key, required this.meter});
  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  List<Bill> _bills = [];
  bool _loading = true;
  String _filter = 'all'; // all, unpaid, paid, overdue

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await TanescoService.getBills(widget.meter.meterNumber);
    if (!mounted) return;
    setState(() { _loading = false; if (result.success) _bills = result.items; });
  }

  List<Bill> get _filtered {
    switch (_filter) {
      case 'unpaid': return _bills.where((b) => !b.isPaid && !b.isOverdue).toList();
      case 'paid': return _bills.where((b) => b.isPaid).toList();
      case 'overdue': return _bills.where((b) => b.isOverdue).toList();
      default: return _bills;
    }
  }

  void _showPayDialog(Bill bill) {
    String method = 'mpesa';
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Lipa Bill / Pay Bill',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 4),
              Text('${bill.billingPeriod} - TZS ${bill.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, color: _kSecondary)),
              const SizedBox(height: 16),
              const Text('Njia ya Malipo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              ...['mpesa', 'tigopesa', 'airtelmoney'].map((m) {
                final labels = {'mpesa': 'M-Pesa', 'tigopesa': 'Tigo Pesa', 'airtelmoney': 'Airtel Money'};
                return RadioListTile<String>(
                  title: Text(labels[m]!, style: const TextStyle(fontSize: 13, color: _kPrimary)),
                  value: m, groupValue: method,
                  onChanged: (v) => setSheetState(() => method = v!),
                  activeColor: _kPrimary, contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '0712 345 678',
                  hintStyle: const TextStyle(color: _kSecondary),
                  labelText: 'Nambari ya Simu',
                  labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                  filled: true, fillColor: _kBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 14, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              BudgetContextBanner(
                category: 'umeme_maji',
                paymentAmount: bill.amount,
                isSwahili: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48, width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await TanescoService.payBill(bill.id, {
                      'method': method, 'phone': phoneCtrl.text.trim(),
                    });
                    if (result.success) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Ombi la malipo limetumwa / Payment request sent')));
                      _load();
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text(result.message ?? 'Imeshindwa kulipa')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Lipa Sasa / Pay Now',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisputeDialog(Bill bill) {
    final descCtrl = TextEditingController();
    String? photoPath;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Ping\'amisha Bill / Dispute Bill',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 4),
              Text('${bill.billingPeriod} - TZS ${bill.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, color: _kSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Eleza tatizo / Describe the issue...',
                  hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                  filled: true, fillColor: _kBg,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 14, color: _kPrimary),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setSheetState(() => photoPath = picked.path);
                  }
                },
                icon: Icon(photoPath != null ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
                    size: 18, color: photoPath != null ? const Color(0xFF4CAF50) : _kPrimary),
                label: Text(
                  photoPath != null ? 'Picha imeambatishwa / Photo attached' : 'Ambatisha picha ya mita / Attach meter photo',
                  style: TextStyle(fontSize: 12, color: photoPath != null ? const Color(0xFF4CAF50) : _kPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: photoPath != null ? const Color(0xFF4CAF50) : Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48, width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (descCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await TanescoService.submitBillDispute(
                        bill.id, descCtrl.text.trim(), photoPath);
                    if (result.success) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Malalamiko yametumwa / Dispute submitted')));
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text(result.message ?? 'Imeshindwa kutuma')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tuma / Submit', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Bili za Umeme' : 'Electricity Bills',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Filter tabs
                  Builder(builder: (_) {
                    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(label: isSwahili ? 'Zote' : 'All', active: _filter == 'all',
                              onTap: () => setState(() => _filter = 'all')),
                          const SizedBox(width: 8),
                          _FilterChip(label: isSwahili ? 'Haijalipwa' : 'Unpaid', active: _filter == 'unpaid',
                              onTap: () => setState(() => _filter = 'unpaid')),
                          const SizedBox(width: 8),
                          _FilterChip(label: isSwahili ? 'Imelipwa' : 'Paid', active: _filter == 'paid',
                              onTap: () => setState(() => _filter = 'paid')),
                          const SizedBox(width: 8),
                          _FilterChip(label: isSwahili ? 'Imechelewa' : 'Overdue', active: _filter == 'overdue',
                              onTap: () => setState(() => _filter = 'overdue')),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 40, color: _kSecondary),
                          const SizedBox(height: 8),
                          Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Hakuna bili' : 'No bills',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BillCard(
                        bill: b,
                        onPay: () => _showPayDialog(b),
                        onDispute: () => _showDisputeDialog(b),
                      ),
                    )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? _kPrimary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? _kPrimary : Colors.grey.shade300),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: active ? Colors.white : _kSecondary)),
    ),
  );
}
