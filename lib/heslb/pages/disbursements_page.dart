// lib/heslb/pages/disbursements_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/heslb_models.dart';
import '../services/heslb_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DisbursementsPage extends StatefulWidget {
  const DisbursementsPage({super.key});
  @override
  State<DisbursementsPage> createState() => _DisbursementsPageState();
}

class _DisbursementsPageState extends State<DisbursementsPage> {
  List<Disbursement> _items = [];
  bool _isLoading = true;
  bool _isSwahili = true;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await HeslbService.getDisbursements();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _items = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia malipo'
                : 'Failed to load disbursements')),
      ));
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'processed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Malipo ya Mkopo' : 'Disbursements',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: _items.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Text(
                          _isSwahili ? 'Hakuna malipo' : 'No disbursements',
                          style: const TextStyle(
                              fontSize: 14, color: _kSecondary),
                        ),
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final d = _items[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
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
                                  color: _kPrimary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: _kPrimary,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.type[0].toUpperCase() +
                                          d.type.substring(1),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      d.date.toString().substring(0, 10),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: _kSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'TZS ${d.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kPrimary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _statusColor(d.status)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      d.status.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              _statusColor(d.status)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
