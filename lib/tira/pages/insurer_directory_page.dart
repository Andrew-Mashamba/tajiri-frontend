// lib/tira/pages/insurer_directory_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/tira_models.dart';
import '../services/tira_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class InsurerDirectoryPage extends StatefulWidget {
  const InsurerDirectoryPage({super.key});
  @override
  State<InsurerDirectoryPage> createState() => _InsurerDirectoryPageState();
}

class _InsurerDirectoryPageState extends State<InsurerDirectoryPage> {
  List<Insurer> _insurers = [];
  bool _isLoading = true;
  bool _isSwahili = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String? query]) async {
    setState(() => _isLoading = true);
    final r = await TiraService.getInsurers(search: query);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _insurers = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia kampuni'
                : 'Failed to load insurers')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Kampuni za Bima' : 'Insurers',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (q) => _load(q.isNotEmpty ? q : null),
              decoration: InputDecoration(
                hintText: _isSwahili ? 'Tafuta...' : 'Search...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _kSecondary, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : RefreshIndicator(
                    onRefresh: () => _load(),
                    color: _kPrimary,
                    child: _insurers.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                  _isSwahili ? 'Hakuna' : 'No insurers found',
                                  style: const TextStyle(
                                      fontSize: 14, color: _kSecondary)),
                            ),
                          ])
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _insurers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final ins = _insurers[i];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(ins.name,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _kPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      const Icon(Icons.star_rounded,
                                          size: 14, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(ins.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _kPrimary)),
                                    ]),
                                    if (ins.address != null) ...[
                                      const SizedBox(height: 4),
                                      Text(ins.address!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _kSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                    if (ins.products.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: ins.products
                                            .take(4)
                                            .map((p) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _kPrimary
                                                        .withValues(
                                                            alpha: 0.06),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(p,
                                                      style:
                                                          const TextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  _kPrimary)),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                    if (ins.phone != null) ...[
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () async {
                                          final uri = Uri(
                                              scheme: 'tel',
                                              path: ins.phone);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          }
                                        },
                                        child: Row(children: [
                                          const Icon(Icons.phone_rounded,
                                              size: 14, color: _kPrimary),
                                          const SizedBox(width: 4),
                                          Text(ins.phone!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _kPrimary)),
                                        ]),
                                      ),
                                    ],
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
