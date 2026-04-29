import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../housing/models/property_listing.dart';
import '../../housing/pages/property_listing_detail_page.dart';
import '../../housing/services/property_listing_service.dart';
import '../../l10n/app_strings_scope.dart';
import 'post_property_listing_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Partner-side "Mali Zangu / My Listings" page (spec line 883).
class MyListingsPage extends StatefulWidget {
  final int userId;
  final int? partnerId;

  const MyListingsPage({super.key, required this.userId, this.partnerId});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  bool _loading = true;
  String? _error;
  List<PropertyListing> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await PropertyListingService.list(
      ownerUserId: widget.userId,
      includeInactive: true,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.items;
      _error = res.success ? null : (res.message ?? 'Failed');
    });
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _create() async {
    final created = await Navigator.push<PropertyListing?>(
      context,
      MaterialPageRoute(
        builder: (_) => PostPropertyListingPage(userId: widget.userId, partnerId: widget.partnerId),
      ),
    );
    if (!mounted) return;
    if (created != null) _load();
  }

  Future<void> _edit(PropertyListing l) async {
    final saved = await Navigator.push<PropertyListing?>(
      context,
      MaterialPageRoute(
        builder: (_) => PostPropertyListingPage(
          userId: widget.userId,
          partnerId: widget.partnerId,
          existing: l,
        ),
      ),
    );
    if (!mounted) return;
    if (saved != null) _load();
  }

  Future<void> _toggleActive(PropertyListing l) async {
    final res = await PropertyListingService.toggleActive(id: l.id, userId: widget.userId);
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      _toast(res.message ?? 'Failed');
    }
  }

  Future<void> _delete(PropertyListing l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa tangazo?' : 'Delete listing?'),
        content: Text(_isSwahili
            ? 'Maswali yaliyopo yatabaki, tangazo halitaonekana.'
            : 'Existing inquiries are kept; the listing is hidden.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
            child: Text(_isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await PropertyListingService.delete(id: l.id, userId: widget.userId);
    if (!mounted) return;
    if (success) {
      _load();
    } else {
      _toast(_isSwahili ? 'Imeshindikana' : 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _isSwahili ? 'Mali Zangu' : 'My Listings',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, style: const TextStyle(color: _kMuted))),
                )
              : _items.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _row(_items[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_isSwahili ? 'Tangaza Mali' : 'Post Listing'),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_work_outlined, size: 56, color: _kMuted),
            const SizedBox(height: 12),
            Text(
              _isSwahili ? 'Hakuna matangazo bado' : 'No listings yet',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _isSwahili
                  ? 'Tangaza mali yako wa kwanza.'
                  : 'Post your first property to get started.',
              style: const TextStyle(fontSize: 12, color: _kMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(PropertyListing l) {
    final cover = l.coverPhoto;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyListingDetailPage(listingId: l.id, initial: l),
                ),
              );
              if (mounted) _load();
            },
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  color: _kPrimary.withValues(alpha: 0.06),
                  child: cover.isEmpty
                      ? Icon(l.propertyType.icon, color: _kMuted, size: 28)
                      : Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(l.propertyType.icon, color: _kMuted, size: 28),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: l.isActive
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l.isActive
                                    ? (_isSwahili ? 'Hai' : 'Active')
                                    : (_isSwahili ? 'Imezimwa' : 'Inactive'),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: l.isActive
                                      ? const Color(0xFF1B5E20)
                                      : const Color(0xFFB71C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_isSwahili ? l.listingKind.labelSwahili : l.listingKind.label} • ${_isSwahili ? l.propertyType.labelSwahili : l.propertyType.label}',
                          style: const TextStyle(fontSize: 11, color: _kMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TZS ${NumberFormat('#,##0', 'en_US').format(l.priceTzs)}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.visibility_outlined, size: 11, color: _kMuted),
                            const SizedBox(width: 3),
                            Text('${l.viewsCount}',
                                style: const TextStyle(fontSize: 10, color: _kMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _edit(l),
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: Text(_isSwahili ? 'Hariri' : 'Edit'),
                  style: TextButton.styleFrom(foregroundColor: _kPrimary),
                ),
              ),
              const VerticalDivider(width: 1, color: _kBorder),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _toggleActive(l),
                  icon: Icon(
                    l.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 14,
                  ),
                  label: Text(l.isActive
                      ? (_isSwahili ? 'Zima' : 'Pause')
                      : (_isSwahili ? 'Washa' : 'Activate')),
                  style: TextButton.styleFrom(foregroundColor: _kPrimary),
                ),
              ),
              const VerticalDivider(width: 1, color: _kBorder),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _delete(l),
                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                  label: Text(_isSwahili ? 'Futa' : 'Delete'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFB71C1C)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
