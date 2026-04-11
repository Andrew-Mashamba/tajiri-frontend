// lib/brela/pages/name_search_page.dart
import 'package:flutter/material.dart';
import '../models/brela_models.dart';
import '../services/brela_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class NameSearchPage extends StatefulWidget {
  const NameSearchPage({super.key});
  @override
  State<NameSearchPage> createState() => _NameSearchPageState();
}

class _NameSearchPageState extends State<NameSearchPage> {
  final _ctrl = TextEditingController();
  List<NameResult> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    final result = await BrelaService.searchName(q);
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (result.success) _results = result.items;
    });
  }

  Future<void> _reserve(String name) async {
    final result = await BrelaService.reserveName(name);
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jina "$name" limehifadhiwa kwa siku 30')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kuhifadhi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Tafuta Jina la Biashara',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Ingiza jina la biashara',
                hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                filled: true, fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 14, color: _kPrimary),
              onSubmitted: (_) => _search(),
            )),
            const SizedBox(width: 8),
            SizedBox(height: 48, child: ElevatedButton(
              onPressed: _searching ? null : _search,
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _searching
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search_rounded, color: Colors.white),
            )),
          ]),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final nr = _results[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(nr.available ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 24, color: nr.available ? const Color(0xFF4CAF50) : Colors.red),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nr.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(nr.available ? 'Linapatikana / Available' : 'Limeshatumika: ${nr.registeredBy ?? ""}',
                        style: TextStyle(fontSize: 12, color: nr.available ? const Color(0xFF4CAF50) : Colors.red),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  if (nr.available)
                    TextButton(
                      onPressed: () => _reserve(nr.name),
                      child: const Text('Hifadhi', style: TextStyle(color: _kPrimary, fontSize: 12)),
                    ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}
