// lib/dawasco/pages/bill_history_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';
import '../widgets/bill_card.dart';
import 'pay_bill_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BillHistoryPage extends StatefulWidget {
  const BillHistoryPage({super.key});
  @override
  State<BillHistoryPage> createState() => _BillHistoryPageState();
}

class _BillHistoryPageState extends State<BillHistoryPage> {
  List<WaterBill> _bills = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await DawascoService.getBills();
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.success) {
          _bills = result.items;
        } else {
          _error = result.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  void _showDisputeDialog(WaterBill bill) {
    final sw = _sw;
    final descCtrl = TextEditingController();
    String? photoPath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(sw ? 'Pingamizi la Bili' : 'Bill Dispute',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${sw ? 'Kipindi' : 'Period'}: ${bill.billingPeriod}',
                    style: const TextStyle(fontSize: 13, color: _kSecondary)),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: sw ? 'Eleza sababu ya pingamizi...' : 'Explain dispute reason...',
                    hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                    filled: true, fillColor: _kBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(fontSize: 14, color: _kPrimary),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    try {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setDialogState(() => photoPath = picked.path);
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(sw ? 'Imeshindwa kuchagua picha: $e' : 'Failed to pick image: $e'),
                      ));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kPrimary.withValues(alpha: 0.12)),
                    ),
                    child: Row(children: [
                      Icon(photoPath != null ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
                          size: 20, color: photoPath != null ? const Color(0xFF4CAF50) : _kSecondary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        photoPath != null
                            ? (sw ? 'Picha imechaguliwa' : 'Photo attached')
                            : (sw ? 'Ambatanisha picha' : 'Attach photo'),
                        style: TextStyle(fontSize: 13,
                            color: photoPath != null ? _kPrimary : _kSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      )),
                      if (photoPath != null)
                        GestureDetector(
                          onTap: () => setDialogState(() => photoPath = null),
                          child: const Icon(Icons.close_rounded, size: 18, color: _kSecondary),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(sw ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final result = await DawascoService.submitBillDispute(
                    bill.id, descCtrl.text.trim(), photoPath: photoPath,
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text(
                    result.success
                        ? (sw ? 'Pingamizi limewasilishwa' : 'Dispute submitted')
                        : (result.message ?? (sw ? 'Imeshindwa' : 'Failed')),
                  )));
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text(sw ? 'Hitilafu: $e' : 'Error: $e'),
                  ));
                }
              },
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: Text(sw ? 'Wasilisha' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Historia ya Bili' : 'Bill History',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: _kSecondary, fontSize: 13),
                      maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: Text(sw ? 'Jaribu tena' : 'Retry',
                      style: const TextStyle(color: _kPrimary))),
                ]))
              : _bills.isEmpty
                  ? Center(child: Text(sw ? 'Hakuna bili' : 'No bills',
                      style: const TextStyle(color: _kSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: _kPrimary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bills.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final b = _bills[i];
                          return Column(children: [
                            BillCardWidget(
                              bill: b,
                              isSwahili: sw,
                              onTap: !b.isPaid
                                  ? () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => PayBillPage(bill: b)))
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                if (!b.isPaid)
                                  SizedBox(
                                    height: 32,
                                    child: TextButton(
                                      onPressed: () => Navigator.push(context,
                                          MaterialPageRoute(builder: (_) => PayBillPage(bill: b))),
                                      child: Text(sw ? 'Lipa' : 'Pay',
                                          style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                if (!b.isPaid) const SizedBox(width: 8),
                                SizedBox(
                                  height: 32,
                                  child: TextButton(
                                    onPressed: () => _showDisputeDialog(b),
                                    child: Text(sw ? 'Pingamizi' : 'Dispute',
                                        style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                  ),
                                ),
                              ]),
                            ),
                          ]);
                        },
                      ),
                    ),
    );
  }
}
