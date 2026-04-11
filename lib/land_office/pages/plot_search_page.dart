// lib/land_office/pages/plot_search_page.dart
import 'package:flutter/material.dart';
import '../models/land_office_models.dart';
import '../services/land_office_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PlotSearchPage extends StatefulWidget {
  const PlotSearchPage({super.key});
  @override
  State<PlotSearchPage> createState() => _PlotSearchPageState();
}

class _PlotSearchPageState extends State<PlotSearchPage> {
  final _ctrl = TextEditingController();
  List<Plot> _results = [];
  bool _searching = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    final result = await LandOfficeService.searchPlot(plotNumber: q);
    if (!mounted) return;
    setState(() { _searching = false; if (result.success) _results = result.items; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(title: const Text('Tafuta Kiwanja',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary)),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl, onSubmitted: (_) => _search(),
              decoration: InputDecoration(hintText: 'Nambari ya kiwanja / Plot number',
                hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                filled: true, fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              style: const TextStyle(fontSize: 14, color: _kPrimary))),
            const SizedBox(width: 8),
            SizedBox(height: 48, child: ElevatedButton(onPressed: _searching ? null : _search,
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _searching ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search_rounded, color: Colors.white))),
          ])),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.all(16), itemCount: _results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final p = _results[i];
            return Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: _kPrimary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Kiwanja #${p.plotNumber}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                if (p.registeredOwner != null) ...[
                  const SizedBox(height: 6),
                  Text('Mmiliki: ${p.registeredOwner}',
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (p.location != null)
                  Text('Eneo: ${p.location}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                Row(children: [
                  if (p.area != null) Text('${p.area} sqm', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                    child: Text(p.titleType.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary))),
                ]),
              ]));
          })),
      ]),
    );
  }
}
