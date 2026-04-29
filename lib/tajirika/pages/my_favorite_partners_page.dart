import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/customer_partner_favorite.dart';
import '../services/customer_partner_favorite_service.dart';
import 'partner_profile_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 1276 — saved-partners directory. Customer's bookmarked
/// partners across all skill personas. Tap to open partner_profile_page.
class MyFavoritePartnersPage extends StatefulWidget {
  final int userId;
  const MyFavoritePartnersPage({super.key, required this.userId});

  @override
  State<MyFavoritePartnersPage> createState() => _MyFavoritePartnersPageState();
}

class _MyFavoritePartnersPageState extends State<MyFavoritePartnersPage> {
  bool _loading = true;
  List<CustomerPartnerFavorite> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await CustomerPartnerFavoriteService.listForCustomer(widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res;
    });
  }

  Future<void> _remove(CustomerPartnerFavorite f) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await CustomerPartnerFavoriteService.remove(f.id);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(
        ok
            ? (_isSwahili ? 'Imefutwa' : 'Removed')
            : (_isSwahili ? 'Imeshindikana' : 'Failed'),
      ),
    ));
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Washirika Niliohifadhi' : 'Saved Partners'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_outline_rounded,
                            size: 56, color: _kSecondary),
                        const SizedBox(height: 12),
                        Text(
                          isSw
                              ? 'Bado hujahifadhi mshirika'
                              : 'No saved partners yet',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSw
                              ? 'Bonyeza ikoni ya bookmark kwenye wasifu wa mshirika.'
                              : 'Tap the bookmark icon on any partner profile to save them.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _row(_items[i]),
                  ),
                ),
    );
  }

  Widget _row(CustomerPartnerFavorite f) {
    final photoUrl = f.partnerPhotoUrl == null || f.partnerPhotoUrl!.isEmpty
        ? null
        : ApiConfig.sanitizeUrl(f.partnerPhotoUrl);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _kBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: _kPrimary.withValues(alpha: 0.06),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? const Icon(Icons.person_rounded, color: _kPrimary)
              : null,
        ),
        title: Text(
          f.partnerName ?? '—',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: f.skillCategory == null || f.skillCategory!.isEmpty
            ? null
            : Text(
                f.skillCategory!,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark_remove_rounded,
              color: Color(0xFFB71C1C)),
          tooltip: _isSwahili ? 'Toa' : 'Remove',
          onPressed: () => _remove(f),
        ),
        onTap: () {
          // partnerId not stored on favorites table; fall back to userId match.
          // Most partners have id == userId for direct viewing.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PartnerProfilePage(partnerId: f.partnerUserId),
            ),
          );
        },
      ),
    );
  }
}
