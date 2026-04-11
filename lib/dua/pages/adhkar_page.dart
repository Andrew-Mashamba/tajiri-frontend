// lib/dua/pages/adhkar_page.dart
import 'package:flutter/material.dart';
import '../models/dua_models.dart';
import '../services/dua_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AdhkarPage extends StatefulWidget {
  final String type; // morning, evening
  const AdhkarPage({super.key, required this.type});

  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  final _service = DuaService();
  List<AdhkarItem> _items = [];
  bool _loading = true;
  final Map<int, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getAdhkar(type: widget.type);
    if (mounted) {
      setState(() {
        _items = result.items;
        for (final item in _items) {
          _counts[item.id] = 0;
        }
        _loading = false;
      });
    }
  }

  void _increment(int id, int target) {
    setState(() {
      final current = _counts[id] ?? 0;
      if (current < target) {
        _counts[id] = current + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMorning = widget.type == 'morning';
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context)),
        title: Text(
          isMorning ? 'Adhkari za Asubuhi' : 'Adhkari za Jioni',
          style: const TextStyle(color: _kPrimary, fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary))
            : _items.isEmpty
                ? const Center(child: Text('Hakuna adhkari',
                    style: TextStyle(color: _kSecondary, fontSize: 14)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      final count = _counts[item.id] ?? 0;
                      final done = count >= item.repeatTarget;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: done
                              ? Colors.green.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: done
                                ? Colors.green.shade200
                                : Colors.grey.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item.textArabic,
                              style: const TextStyle(
                                color: _kPrimary, fontSize: 18, height: 1.8),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              maxLines: 5, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.translationSwahili,
                                style: const TextStyle(
                                  color: _kSecondary, fontSize: 13, height: 1.5),
                                maxLines: 4, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '$count / ${item.repeatTarget}',
                                  style: TextStyle(
                                    color: done ? Colors.green : _kSecondary,
                                    fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 40, width: 40,
                                  child: IconButton(
                                    onPressed: done
                                        ? null
                                        : () => _increment(
                                            item.id, item.repeatTarget),
                                    icon: Icon(
                                      done
                                          ? Icons.check_circle_rounded
                                          : Icons.add_circle_rounded,
                                      color: done
                                          ? Colors.green
                                          : _kPrimary,
                                      size: 28),
                                    padding: EdgeInsets.zero,
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
