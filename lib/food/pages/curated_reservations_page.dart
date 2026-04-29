import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kDanger = Color(0xFFD32F2F);

class CuratedReservationsPage extends StatefulWidget {
  final int listingId;
  final String listingTitle;
  final int partnerUserId;

  const CuratedReservationsPage({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.partnerUserId,
  });

  @override
  State<CuratedReservationsPage> createState() => _CuratedReservationsPageState();
}

class _CuratedReservationsPageState extends State<CuratedReservationsPage> {
  final FoodService _service = FoodService();
  List<Map<String, dynamic>> _rows = const [];
  bool _loading = true;
  String? _error;
  int? _busyId;

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
    final res = await _service.listCuratedReservations(
      listingId: widget.listingId,
      partnerUserId: widget.partnerUserId,
    );
    if (!mounted) return;
    if (res.success) {
      setState(() {
        _rows = res.items;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Imeshindwa';
        _loading = false;
      });
    }
  }

  Future<void> _accept(Map<String, dynamic> r) async {
    final id = (r['id'] as num).toInt();
    if (_busyId != null) return;
    setState(() => _busyId = id);
    final messenger = ScaffoldMessenger.of(context);
    final res = await _service.acceptCuratedReservation(
      reservationId: id,
      partnerUserId: widget.partnerUserId,
    );
    if (!mounted) return;
    setState(() => _busyId = null);
    if (res.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Umekubali. Tumemjulisha jirani.')),
      );
      _load();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
    }
  }

  Future<void> _reject(Map<String, dynamic> r) async {
    final id = (r['id'] as num).toInt();
    if (_busyId != null) return;
    setState(() => _busyId = id);
    final messenger = ScaffoldMessenger.of(context);
    final res = await _service.rejectCuratedReservation(
      reservationId: id,
      partnerUserId: widget.partnerUserId,
    );
    if (!mounted) return;
    setState(() => _busyId = null);
    if (res.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Umekataa ombi.')),
      );
      _load();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maombi ya Chakula',
                style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary, fontSize: 15)),
            Text(widget.listingTitle,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: _kSecondary)))
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: _rows.isEmpty ? _empty() : _list(),
                ),
    );
  }

  Widget _empty() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.inbox_outlined, size: 48, color: _kSecondary),
        SizedBox(height: 12),
        Center(
          child: Text('Bado hakuna aliyeomba',
              style: TextStyle(color: _kSecondary, fontSize: 14)),
        ),
        SizedBox(height: 4),
        Center(
          child: Text('Subiri kidogo — maombi yatatokea hapa',
              style: TextStyle(color: _kSecondary, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _list() {
    final pending = _rows.where((r) => (r['curated_status'] ?? '') == 'pending').toList();
    final decided = _rows.where((r) => (r['curated_status'] ?? '') != 'pending').toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          _section('Maombi Mapya (${pending.length})'),
          const SizedBox(height: 8),
          ...pending.map(_row),
        ],
        if (decided.isNotEmpty) ...[
          const SizedBox(height: 16),
          _section('Yaliyoamuliwa'),
          const SizedBox(height: 8),
          ...decided.map(_row),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _section(String s) => Text(s,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _kSecondary,
        letterSpacing: 0.6,
      ));

  Widget _row(Map<String, dynamic> r) {
    final name = (r['user_name'] ?? 'Mtumiaji') as String;
    final photo = (r['user_photo'] ?? '') as String? ?? '';
    final whyMe = (r['why_me'] ?? '') as String? ?? '';
    final portions = (r['portions'] as num?)?.toInt() ?? 1;
    final status = (r['curated_status'] ?? '') as String;
    final id = (r['id'] as num).toInt();
    final busy = _busyId == id;

    final resolvedPhoto = photo.isEmpty
        ? ''
        : (photo.startsWith('http')
            ? photo
            : '${ApiConfig.storageUrl}/$photo');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _kPrimary.withValues(alpha: 0.1),
                child: resolvedPhoto.isEmpty
                    ? const Icon(Icons.person_rounded, color: _kSecondary, size: 20)
                    : ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: resolvedPhoto,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const Icon(
                              Icons.person_rounded, color: _kSecondary, size: 20),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('$portions milo',
                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          if (whyMe.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(whyMe,
                  style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _reject(r),
                    icon: const Icon(Icons.close_rounded, size: 16, color: _kDanger),
                    label: const Text('Kataa',
                        style: TextStyle(color: _kDanger, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _kDanger.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : () => _accept(r),
                    icon: busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    label: const Text('Chagua',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'accepted':
        bg = _kAccent.withValues(alpha: 0.15);
        fg = _kAccent;
        label = 'Umekubaliwa';
        break;
      case 'rejected':
        bg = _kDanger.withValues(alpha: 0.15);
        fg = _kDanger;
        label = 'Umekataliwa';
        break;
      default:
        bg = _kPrimary.withValues(alpha: 0.1);
        fg = _kPrimary;
        label = 'Inasubiri';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
