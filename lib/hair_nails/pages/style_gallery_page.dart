// lib/hair_nails/pages/style_gallery_page.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';
import '../services/hair_nails_service.dart';
import '../widgets/style_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
class StyleGalleryPage extends StatefulWidget {
  final int userId;
  final StyleCategory? initialCategory;
  const StyleGalleryPage({super.key, required this.userId, this.initialCategory});
  @override
  State<StyleGalleryPage> createState() => _StyleGalleryPageState();
}

class _StyleGalleryPageState extends State<StyleGalleryPage> with SingleTickerProviderStateMixin {
  final HairNailsService _service = HairNailsService();
  late TabController _tabCtrl;

  final Map<String, List<StyleInspiration>> _stylesCache = {};
  final Map<String, bool> _loadingMap = {};

  static const _tabs = StyleCategory.values;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialCategory != null ? _tabs.indexOf(widget.initialCategory!) : 0;
    _tabCtrl = TabController(length: _tabs.length, vsync: this, initialIndex: initialIndex >= 0 ? initialIndex : 0);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _loadCategory(_tabs[_tabCtrl.index]);
    });
    _loadCategory(_tabs[_tabCtrl.index]);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategory(StyleCategory cat) async {
    if (_stylesCache.containsKey(cat.name)) return;
    setState(() => _loadingMap[cat.name] = true);
    final result = await _service.getStyleGallery(category: cat.name);
    if (mounted) {
      setState(() {
        _loadingMap[cat.name] = false;
        if (result.success) _stylesCache[cat.name] = result.items;
      });
    }
  }

  void _toggleSave(StyleInspiration style) async {
    await _service.saveStyle(userId: widget.userId, styleId: style.id);
    // Refresh current tab
    final cat = _tabs[_tabCtrl.index];
    _stylesCache.remove(cat.name);
    _loadCategory(cat);
  }

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Mitindo ya Nywele na Kucha', style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t.displayName)).toList(),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabCtrl,
          children: _tabs.map((cat) {
            final loading = _loadingMap[cat.name] ?? false;
            final styles = _stylesCache[cat.name] ?? [];

            if (loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
            if (styles.isEmpty) return const Center(child: Text('Hakuna mitindo bado', style: TextStyle(color: _kSecondary)));

            return RefreshIndicator(
              onRefresh: () async {
                _stylesCache.remove(cat.name);
                await _loadCategory(cat);
              },
              color: _kPrimary,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: styles.length,
                itemBuilder: (context, i) {
                  final style = styles[i];
                  return StyleCard(
                    style: style,
                    onTap: () => _showDetail(style),
                    onSave: () => _toggleSave(style),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDetail(StyleInspiration style) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _kSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Image
            if (style.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(style.imageUrl!, height: 280, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 200)),
              ),
            const SizedBox(height: 14),

            // Title
            Text(style.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 4),
            Text(style.category.displayName, style: const TextStyle(fontSize: 13, color: _kSecondary)),
            const SizedBox(height: 12),

            // Price + Duration
            Row(
              children: [
                if (style.estimatedPrice != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 16, color: _kPrimary),
                        const SizedBox(width: 4),
                        Text('TZS ${_fmtPrice(style.estimatedPrice!)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (style.estimatedDurationMinutes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: _kPrimary),
                        const SizedBox(width: 4),
                        Text(style.durationLabel, style: const TextStyle(fontSize: 13, color: _kPrimary)),
                      ],
                    ),
                  ),
              ],
            ),

            // Description
            if (style.description != null) ...[
              const SizedBox(height: 14),
              Text(style.description!, style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.5)),
            ],

            // Recommended hair types
            if (style.hairTypeRecommended.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Inafaa kwa Aina ya Nywele:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: style.hairTypeRecommended.map((h) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                      child: Text('${h.shortLabel} — ${h.displayName}', style: const TextStyle(fontSize: 11, color: _kPrimary)),
                    )).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // Save + Find salon buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleSave(style),
                    icon: Icon(style.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 18),
                    label: Text(style.isSaved ? 'Imeokoka' : 'Hifadhi'),
                    style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, side: const BorderSide(color: _kPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(0, 48)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context); // Back to home, then navigate to salon browse
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(0, 48)),
                    child: const Text('Pata Saluni', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
