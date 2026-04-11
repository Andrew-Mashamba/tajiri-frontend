// lib/past_papers/pages/past_papers_home_page.dart
import 'package:flutter/material.dart';
import '../models/past_papers_models.dart';
import '../services/past_papers_service.dart';
import 'paper_viewer_page.dart';
import 'upload_paper_page.dart';
import '../widgets/paper_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PastPapersHomePage extends StatefulWidget {
  final int userId;
  const PastPapersHomePage({super.key, required this.userId});
  @override
  State<PastPapersHomePage> createState() => _PastPapersHomePageState();
}

class _PastPapersHomePageState extends State<PastPapersHomePage> {
  final PastPapersService _service = PastPapersService();
  List<PastPaper> _papers = [];
  bool _isLoading = true;
  EducationLevel? _selectedLevel;
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadPapers() async {
    setState(() => _isLoading = true);
    final result = await _service.getPapers(
      level: _selectedLevel?.name,
      search: _searchC.text.trim().isEmpty ? null : _searchC.text.trim(),
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _papers = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPapers,
          color: _kPrimary,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.history_edu_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text('Mitihani ya Zamani', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
                SizedBox(height: 6),
                Text('Past Papers — NECTA, university exams & marking schemes', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),
            // Search
            TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: 'Tafuta somo, chuo...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
              onSubmitted: (_) => _loadPapers(),
            ),
            const SizedBox(height: 12),
            // Level filter
            SizedBox(
              height: 36,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: const Text('Zote', style: TextStyle(fontSize: 12)), selected: _selectedLevel == null, selectedColor: _kPrimary,
                    labelStyle: TextStyle(color: _selectedLevel == null ? Colors.white : _kPrimary),
                    onSelected: (_) { setState(() => _selectedLevel = null); _loadPapers(); }),
                ),
                ...EducationLevel.values.map((l) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(l.displayName, style: const TextStyle(fontSize: 12)), selected: _selectedLevel == l, selectedColor: _kPrimary,
                    labelStyle: TextStyle(color: _selectedLevel == l ? Colors.white : _kPrimary),
                    onSelected: (_) { setState(() => _selectedLevel = l); _loadPapers(); }),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
            else if (_papers.isEmpty)
              Container(padding: const EdgeInsets.all(48), alignment: Alignment.center, child: const Column(children: [
                Icon(Icons.folder_open_rounded, size: 48, color: _kSecondary),
                SizedBox(height: 8),
                Text('Hakuna mitihani', style: TextStyle(color: _kSecondary, fontSize: 14)),
                Text('No past papers found', style: TextStyle(color: _kSecondary, fontSize: 12)),
              ]))
            else
              ..._papers.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PaperCard(paper: p, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaperViewerPage(paper: p)))),
              )),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UploadPaperPage(userId: widget.userId))).then((_) => _loadPapers()),
        child: const Icon(Icons.upload_rounded, color: Colors.white),
      ),
    );
  }
}
