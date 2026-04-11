// lib/past_papers/pages/paper_viewer_page.dart
import 'package:flutter/material.dart';
import '../models/past_papers_models.dart';
import '../services/past_papers_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PaperViewerPage extends StatelessWidget {
  final PastPaper paper;
  const PaperViewerPage({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0,
        title: Text(paper.subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: Icon(paper.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _kPrimary), onPressed: () => PastPapersService().bookmarkPaper(paper.id)),
          IconButton(icon: const Icon(Icons.share_rounded, color: _kPrimary), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inashiriki... / Sharing...')));
          }),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(paper.subject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 4),
              if (paper.courseCode != null) Text(paper.courseCode!, style: const TextStyle(fontSize: 14, color: _kSecondary)),
              const SizedBox(height: 10),
              _infoRow(Icons.calendar_today_rounded, 'Mwaka: ${paper.year}'),
              _infoRow(Icons.school_rounded, paper.level.displayName),
              _infoRow(Icons.assignment_rounded, paper.examType.displayName),
              if (paper.institution != null) _infoRow(Icons.account_balance_rounded, paper.institution!),
              _infoRow(Icons.file_present_rounded, paper.fileSizeFormatted),
              const SizedBox(height: 10),
              Row(children: [
                _stat(Icons.download_rounded, '${paper.downloadCount}'),
                const SizedBox(width: 16),
                _stat(Icons.visibility_rounded, '${paper.viewCount}'),
                const SizedBox(width: 16),
                _stat(Icons.bar_chart_rounded, paper.difficultyRating.toStringAsFixed(1)),
                const Spacer(),
                if (paper.isVerified) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified_rounded, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text('Imethibitishwa', style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                  ]),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          // Uploader
          Text('Imepakiwa na: ${paper.uploaderName}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 20),
          // PDF placeholder
          Container(
            height: 400,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.picture_as_pdf_rounded, size: 64, color: _kSecondary),
              SizedBox(height: 12),
              Text('PDF Viewer', style: TextStyle(color: _kSecondary, fontSize: 16)),
              Text('Bonyeza Pakua kuona faili', style: TextStyle(color: _kSecondary, fontSize: 12)),
            ])),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inapakua...'))),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Pakua PDF'),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
          ),
          if (paper.markingSchemeUrl != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inapakua majibu... / Downloading marking scheme...')));
              },
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text('Majibu / Marking Scheme'),
              style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: _kSecondary),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: _kSecondary)),
      ]),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: _kSecondary),
      const SizedBox(width: 4),
      Text(value, style: const TextStyle(fontSize: 12, color: _kSecondary)),
    ]);
  }
}
