// lib/campus_news/pages/campus_news_home_page.dart
import 'package:flutter/material.dart';
import '../models/campus_news_models.dart';
import '../services/campus_news_service.dart';
import 'announcement_detail_page.dart';
import 'campus_events_page.dart';
import '../widgets/announcement_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CampusNewsHomePage extends StatefulWidget {
  final int userId;
  const CampusNewsHomePage({super.key, required this.userId});
  @override
  State<CampusNewsHomePage> createState() => _CampusNewsHomePageState();
}

class _CampusNewsHomePageState extends State<CampusNewsHomePage> {
  final CampusNewsService _service = CampusNewsService();
  List<CampusAnnouncement> _announcements = [];
  bool _isLoading = true;
  CampusCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await _service.getAnnouncements(category: _selectedCategory?.name);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _announcements = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _kPrimary,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.newspaper_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Habari za Chuo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CampusEventsPage(userId: widget.userId))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Matukio', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                const Text('Campus News & announcements', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),
            // Category filter
            SizedBox(
              height: 36,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                  label: const Text('Zote', style: TextStyle(fontSize: 12)),
                  selected: _selectedCategory == null,
                  selectedColor: _kPrimary,
                  labelStyle: TextStyle(color: _selectedCategory == null ? Colors.white : _kPrimary),
                  onSelected: (_) { setState(() => _selectedCategory = null); _loadData(); },
                )),
                ...CampusCategory.values.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.displayName, style: const TextStyle(fontSize: 12)),
                    selected: _selectedCategory == c,
                    selectedColor: _kPrimary,
                    labelStyle: TextStyle(color: _selectedCategory == c ? Colors.white : _kPrimary),
                    onSelected: (_) { setState(() => _selectedCategory = c); _loadData(); },
                  ),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
            else if (_announcements.isEmpty)
              Container(padding: const EdgeInsets.all(48), alignment: Alignment.center, child: const Column(children: [
                Icon(Icons.campaign_rounded, size: 48, color: _kSecondary),
                SizedBox(height: 8),
                Text('Hakuna habari kwa sasa / No news right now', style: TextStyle(color: _kSecondary)),
              ]))
            else
              ..._announcements.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnnouncementCard(announcement: a, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementDetailPage(announcement: a)))),
              )),
          ]),
        ),
      ),
    );
  }
}
