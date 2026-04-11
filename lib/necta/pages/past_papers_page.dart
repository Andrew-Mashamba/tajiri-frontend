// lib/necta/pages/past_papers_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/necta_models.dart';
import '../services/necta_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PastPapersPage extends StatefulWidget {
  const PastPapersPage({super.key});
  @override
  State<PastPapersPage> createState() => _PastPapersPageState();
}

class _PastPapersPageState extends State<PastPapersPage> {
  List<PastPaper> _papers = [];
  bool _isLoading = true;
  bool _isSwahili = true;
  String _examType = 'csee';

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await NectaService.getPastPapers(examType: _examType);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _papers = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia mitihani'
                : 'Failed to load past papers')),
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
        title: Text(_isSwahili ? 'Mitihani ya Zamani' : 'Past Papers',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children:
                  ['csee', 'acsee', 'ftna', 'psle'].map((t) {
                final sel = t == _examType;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _examType = t);
                      _load();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sel ? _kPrimary : Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          t.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : _kPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: _kPrimary,
                    child: _papers.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                _isSwahili ? 'Hakuna' : 'No papers found',
                                style: const TextStyle(
                                    fontSize: 14, color: _kSecondary),
                              ),
                            ),
                          ])
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _papers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final p = _papers[i];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            _kPrimary.withValues(alpha: 0.06),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                          Icons.description_rounded,
                                          color: _kPrimary,
                                          size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(p.subject,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: _kPrimary),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                          Text(
                                            '${p.examType.toUpperCase()} ${p.year}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: _kSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (p.fileUrl != null)
                                      IconButton(
                                        icon: const Icon(
                                            Icons.download_rounded,
                                            color: _kPrimary,
                                            size: 20),
                                        onPressed: () async {
                                          final uri = Uri.parse(p.fileUrl!);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          }
                                        },
                                      ),
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
