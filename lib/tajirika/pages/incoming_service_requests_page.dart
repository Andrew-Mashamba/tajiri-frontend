import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../mafundi/models/service_request.dart';
import '../../mafundi/services/service_request_service.dart';
import 'service_request_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kSuccess = Color(0xFF1B5E20);
const Color _kWarning = Color(0xFFE65100);
const Color _kError = Color(0xFFB71C1C);
const Color _kInfo = Color(0xFF0D47A1);

/// Partner-facing service-request inbox (spec line 391).
///
/// Lists all service requests directed at or accepted by the partner,
/// with skill icon, customer info, status pill, and quick-quote action.
class IncomingServiceRequestsPage extends StatefulWidget {
  final int userId;
  const IncomingServiceRequestsPage({super.key, required this.userId});

  @override
  State<IncomingServiceRequestsPage> createState() =>
      _IncomingServiceRequestsPageState();
}

class _IncomingServiceRequestsPageState
    extends State<IncomingServiceRequestsPage> {
  bool _loading = true;
  String? _error;
  List<ServiceRequest> _items = const [];

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

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
    final res = await ServiceRequestService.list(
      userId: widget.userId,
      role: 'partner',
      limit: 50,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.requests;
      _error = res.success ? null : (res.message ?? 'Failed');
    });
  }

  Future<void> _open(ServiceRequest r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceRequestDetailPage(
          userId: widget.userId,
          requestId: r.id,
        ),
      ),
    );
    if (mounted) _load();
  }

  Color _statusColor(ServiceRequestStatus s) {
    switch (s) {
      case ServiceRequestStatus.pending:
      case ServiceRequestStatus.quoted:
        return _kWarning;
      case ServiceRequestStatus.accepted:
      case ServiceRequestStatus.enRoute:
      case ServiceRequestStatus.onSite:
        return _kInfo;
      case ServiceRequestStatus.completed:
        return _kSuccess;
      case ServiceRequestStatus.cancelled:
      case ServiceRequestStatus.rejected:
        return _kError;
    }
  }

  String _statusText(ServiceRequestStatus s) {
    return _isSwahili ? s.labelSwahili : s.label;
  }

  Color _statusBg(ServiceRequestStatus s) {
    switch (s) {
      case ServiceRequestStatus.pending:
      case ServiceRequestStatus.quoted:
        return const Color(0xFFFFF8E1);
      case ServiceRequestStatus.accepted:
      case ServiceRequestStatus.enRoute:
      case ServiceRequestStatus.onSite:
        return const Color(0xFFE3F2FD);
      case ServiceRequestStatus.completed:
        return const Color(0xFFE8F5E9);
      case ServiceRequestStatus.cancelled:
      case ServiceRequestStatus.rejected:
        return const Color(0xFFFFEBEE);
    }
  }

  String _skillLabel(String raw) {
    // Simple prettification — backend sends snake_case or camelCase keys.
    return raw
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => ' ${m.group(0)}',
        )
        .replaceAll('_', ' ')
        .trim()
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  IconData _skillIcon(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('plumb')) return Icons.water_drop_outlined;
    if (r.contains('electr')) return Icons.electrical_services_outlined;
    if (r.contains('paint')) return Icons.format_paint_outlined;
    if (r.contains('roof')) return Icons.roofing_outlined;
    if (r.contains('solar')) return Icons.wb_sunny_outlined;
    if (r.contains('carpent')) return Icons.handyman_outlined;
    if (r.contains('mason')) return Icons.foundation_outlined;
    if (r.contains('til')) return Icons.grid_on_outlined;
    if (r.contains('weld')) return Icons.local_fire_department_outlined;
    return Icons.build_outlined;
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
          _isSwahili ? 'Maombi ya Huduma' : 'Service Requests',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(_error!,
                        style: const TextStyle(color: _kMuted)),
                  ),
                )
              : _items.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _buildList(),
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
            const Icon(Icons.handyman_outlined, size: 56, color: _kMuted),
            const SizedBox(height: 12),
            Text(
              _isSwahili
                  ? 'Hakuna maombi bado'
                  : 'No service requests yet',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isSwahili
                  ? 'Wateja watakapokuwa na matatizo ya nyumbani, wataonekana hapa'
                  : 'When customers have home issues, they\'ll appear here',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final r = _items[index];
        return _card(r);
      },
    );
  }

  Widget _card(ServiceRequest r) {
    final statusColor = _statusColor(r.status);
    final statusBg = _statusBg(r.status);
    final canQuote = r.status == ServiceRequestStatus.pending &&
        r.quotes.every((q) => q.partnerUserId != widget.userId);

    return InkWell(
      onTap: () => _open(r),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: skill icon + name, status pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _skillIcon(r.skillCategoryRaw),
                    size: 18,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _skillLabel(r.skillCategoryRaw),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusText(r.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Customer row
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFEEEEEE),
                  backgroundImage: r.customerPhotoUrl != null &&
                          r.customerPhotoUrl!.isNotEmpty
                      ? NetworkImage(
                          ApiConfig.sanitizeUrl(r.customerPhotoUrl!)!)
                      : null,
                  child: r.customerPhotoUrl == null ||
                          r.customerPhotoUrl!.isEmpty
                      ? const Icon(Icons.person_outline,
                          size: 14, color: _kMuted)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.customerName ??
                        (_isSwahili ? 'Mteja' : 'Customer'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary,
                    ),
                  ),
                ),
                if (r.createdAt != null)
                  Text(
                    _timeAgo(r.createdAt!),
                    style: const TextStyle(fontSize: 11, color: _kMuted),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Problem summary
            Text(
              r.problemSummary,
              style: const TextStyle(fontSize: 13, color: _kPrimary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Address + photo count
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: _kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    r.address,
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (r.photos.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.photo_outlined,
                      size: 14, color: _kMuted),
                  const SizedBox(width: 2),
                  Text(
                    '${r.photos.length}',
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ] else ...[
                  const SizedBox.shrink(),
                ],
              ],
            ),
            // Quote CTA for pending unquoted
            if (canQuote) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: _kBorder),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _open(r),
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: Text(
                    _isSwahili ? 'Toa nukuu' : 'Send quote',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) {
      return _isSwahili ? 'Sasa' : 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ${_isSwahili ? '' : 'ago'}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ${_isSwahili ? '' : 'ago'}';
    }
    return '${diff.inDays}d ${_isSwahili ? '' : 'ago'}';
  }
}
