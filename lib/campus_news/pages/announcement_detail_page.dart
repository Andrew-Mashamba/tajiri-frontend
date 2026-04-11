// lib/campus_news/pages/announcement_detail_page.dart
import 'package:flutter/material.dart';
import '../models/campus_news_models.dart';
import '../services/campus_news_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AnnouncementDetailPage extends StatelessWidget {
  final CampusAnnouncement announcement;
  const AnnouncementDetailPage({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0,
        actions: [
          IconButton(icon: Icon(announcement.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded), onPressed: () {
            CampusNewsService().saveAnnouncement(announcement.id);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imehifadhiwa / Saved')));
          }),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inashiriki... / Sharing...')));
          }),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (announcement.isEmergency) Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.warning_rounded, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('DHARURA / EMERGENCY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
            ]),
          ),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
              child: Text(announcement.category.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
            ),
            const SizedBox(width: 8),
            if (announcement.isVerified) Icon(Icons.verified_rounded, size: 16, color: Colors.blue.shade600),
          ]),
          const SizedBox(height: 10),
          Text(announcement.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kPrimary, height: 1.3)),
          const SizedBox(height: 8),
          Row(children: [
            if (announcement.sourceAvatar != null) CircleAvatar(radius: 12, backgroundImage: NetworkImage(announcement.sourceAvatar!))
            else CircleAvatar(radius: 12, backgroundColor: _kPrimary.withValues(alpha: 0.1), child: Text(announcement.source.isNotEmpty ? announcement.source[0] : '?', style: const TextStyle(fontSize: 10, color: _kPrimary))),
            const SizedBox(width: 8),
            Text(announcement.source, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary)),
            const Spacer(),
            Text('${announcement.publishedAt.day}/${announcement.publishedAt.month}/${announcement.publishedAt.year}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ]),
          if (announcement.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(announcement.imageUrl!, fit: BoxFit.cover, height: 200, width: double.infinity),
            ),
          ],
          const SizedBox(height: 16),
          Text(announcement.body, style: const TextStyle(fontSize: 15, color: _kPrimary, height: 1.6)),
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.comment_rounded, size: 16, color: _kSecondary),
            const SizedBox(width: 6),
            Text('${announcement.commentCount} maoni', style: const TextStyle(fontSize: 13, color: _kSecondary)),
          ]),
        ]),
      ),
    );
  }
}
