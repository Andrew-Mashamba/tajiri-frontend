// lib/dua/pages/dua_category_page.dart
import 'package:flutter/material.dart';
import '../models/dua_models.dart';
import '../services/dua_service.dart';
import 'dua_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DuaCategoryPage extends StatefulWidget {
  final DuaCategory category;
  const DuaCategoryPage({super.key, required this.category});

  @override
  State<DuaCategoryPage> createState() => _DuaCategoryPageState();
}

class _DuaCategoryPageState extends State<DuaCategoryPage> {
  final _service = DuaService();
  List<Dua> _duas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getDuasByCategory(
      categoryId: widget.category.id,
    );
    if (mounted) {
      setState(() {
        _duas = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context)),
        title: Text(
          cat.nameSwahili.isNotEmpty ? cat.nameSwahili : cat.name,
          style: const TextStyle(color: _kPrimary, fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary))
            : _duas.isEmpty
                ? const Center(child: Text('Hakuna dua katika kundi hili',
                    style: TextStyle(color: _kSecondary, fontSize: 14)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _duas.length,
                    itemBuilder: (context, i) {
                      final dua = _duas[i];
                      return InkWell(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                                DuaDetailPage(dua: dua))),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dua.titleSwahili.isNotEmpty
                                    ? dua.titleSwahili
                                    : dua.titleEnglish,
                                style: const TextStyle(color: _kPrimary,
                                    fontSize: 15, fontWeight: FontWeight.w500),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dua.textArabic,
                                style: const TextStyle(color: _kPrimary,
                                    fontSize: 16, height: 1.6),
                                textDirection: TextDirection.rtl,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dua.source,
                                style: const TextStyle(color: _kSecondary,
                                    fontSize: 11),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
