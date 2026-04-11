// lib/fungu_la_kumi/pages/giving_history_page.dart
import 'package:flutter/material.dart';
import '../models/fungu_la_kumi_models.dart';
import '../services/fungu_la_kumi_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class GivingHistoryPage extends StatefulWidget {
  const GivingHistoryPage({super.key});
  @override
  State<GivingHistoryPage> createState() => _GivingHistoryPageState();
}

class _GivingHistoryPageState extends State<GivingHistoryPage> {
  List<GivingRecord> _records = [];
  bool _isLoading = true;
  String? _filterType;
  int _page = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool append = false}) async {
    if (!append) setState(() => _isLoading = true);
    final r = await FunguLaKumiService.getHistory(
        type: _filterType, page: _page);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) {
          if (append) {
            _records.addAll(r.items);
          } else {
            _records = r.items;
          }
          _hasMore = r.hasMore;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historia ya Kutoa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Giving History',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: Column(
        children: [
          // Filters
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                    label: 'Zote / All',
                    selected: _filterType == null,
                    onTap: () { _filterType = null; _page = 1; _load(); }),
                ...GivingType.values.map((t) => _FilterChip(
                      label: t.label.split(' / ').first,
                      selected: _filterType == t.name,
                      onTap: () { _filterType = t.name; _page = 1; _load(); },
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Hakuna rekodi / No records',
                                style: TextStyle(color: _kSecondary, fontSize: 14)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () { _page = 1; return _load(); },
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            if (i == _records.length) {
                              return Center(
                                child: TextButton(
                                  onPressed: () { _page++; _load(append: true); },
                                  child: const Text('Pakia zaidi / Load more',
                                      style: TextStyle(color: _kPrimary)),
                                ),
                              );
                            }
                            final rec = _records[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(rec.type.label,
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text(rec.date,
                                            style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                        if (rec.mpesaRef != null)
                                          Text('Ref: ${rec.mpesaRef}',
                                              style: const TextStyle(fontSize: 11, color: _kSecondary)),
                                      ],
                                    ),
                                  ),
                                  Text('TSh ${rec.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : _kSecondary,
              )),
        ),
      ),
    );
  }
}
