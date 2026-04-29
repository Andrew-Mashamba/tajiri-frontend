import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../customer_orders/models/customer_order.dart';
import '../../customer_orders/widgets/rate_partner_cta.dart';
import '../../customer_orders/widgets/lead_expiring_chip.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/service_request.dart';
import '../services/service_request_service.dart';

class ServiceRequestStatusPage extends StatefulWidget {
  final int userId;
  final int requestId;

  const ServiceRequestStatusPage({
    super.key,
    required this.userId,
    required this.requestId,
  });

  @override
  State<ServiceRequestStatusPage> createState() =>
      _ServiceRequestStatusPageState();
}

class _ServiceRequestStatusPageState extends State<ServiceRequestStatusPage> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  ServiceRequest? _request;

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
    final res = await ServiceRequestService.get(
      id: widget.requestId,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.request != null) {
        _request = res.request;
      } else {
        _error = res.message ?? 'Failed to load';
      }
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String? _acceptedPartnerName(ServiceRequest r) {
    for (final q in r.quotes) {
      if (q.status == QuoteStatus.accepted) return q.partnerName;
    }
    return null;
  }

  Future<void> _openMaps(ServiceRequest r) async {
    if (r.lat == null || r.lng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${r.lat},${r.lng}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Imeshindikana kufungua ramani' : 'Could not open maps'),
      ));
    }
  }

  Future<void> _acceptQuote(ServiceRequestQuote q) async {
    final isSw = _isSwahili;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Kubali nukuu?' : 'Accept quote?'),
        content: Text(
          isSw
              ? 'Utalipa TZS ${q.calloutFeeTzs} kwa kuja na hadi TZS ${q.estimatedCostTzs ?? '—'} kwa jumla. Nukuu zingine zitafutwa.'
              : 'You will pay TZS ${q.calloutFeeTzs} callout and up to TZS ${q.estimatedCostTzs ?? '—'} estimate. Other quotes will be auto-rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isSw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isSw ? 'Kubali' : 'Accept'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    final res = await ServiceRequestService.accept(
      id: widget.requestId,
      userId: widget.userId,
      quoteId: q.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.success && res.request != null) {
      setState(() => _request = res.request);
      _toast(isSw ? 'Nukuu imekubaliwa' : 'Quote accepted');
    } else {
      _toast(res.message ??
          (isSw ? 'Imeshindikana' : 'Failed'));
    }
  }

  Future<void> _cancelRequest() async {
    final isSw = _isSwahili;
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Ghairi ombi?' : 'Cancel request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSw
                  ? 'Eleza sababu (hiari).'
                  : 'Reason (optional).',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isSw ? 'Hapana' : 'No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isSw ? 'Ndiyo, ghairi' : 'Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    final res = await ServiceRequestService.cancel(
      id: widget.requestId,
      userId: widget.userId,
      reason: reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.success && res.request != null) {
      setState(() => _request = res.request);
      _toast(isSw ? 'Ombi limeghairiwa' : 'Request cancelled');
    } else {
      _toast(res.message ?? (isSw ? 'Imeshindikana' : 'Failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Hali ya ombi' : 'Request status'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isSw ? 'Onyesha upya' : 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView(_error!, isSw)
                : _request == null
                    ? Center(
                        child: Text(isSw ? 'Hakuna data' : 'No data'),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _summaryCard(_request!, isSw),
                            if (_request!.aiCostLowTzs != null &&
                                _request!.aiCostHighTzs != null) ...[
                              const SizedBox(height: 12),
                              _aiCostAnchorBanner(_request!, isSw),
                            ],
                            const SizedBox(height: 16),
                            _timeline(_request!, isSw),
                            const SizedBox(height: 16),
                            _quotesSection(_request!, isSw),
                            if (_request!.partsLineItems.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _partsSection(_request!, isSw),
                            ],
                            if (_request!.siteSurveyFeeTzs != null) ...[
                              const SizedBox(height: 16),
                              _surveyBanner(_request!, isSw),
                            ],
                            if (_request!.beforePhotos.isNotEmpty ||
                                _request!.afterPhotos.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _beforeAfterSection(_request!, isSw),
                            ],
                            if (_request!.revisedQuoteTzs != null &&
                                _request!.revisedQuoteApprovedAt == null) ...[
                              const SizedBox(height: 16),
                              _revisedQuoteBanner(_request!, isSw),
                            ],
                            if (_request!.status == ServiceRequestStatus.completed) ...[
                              const SizedBox(height: 16),
                              _warrantyBadge(_request!, isSw),
                              const SizedBox(height: 16),
                              RatePartnerCta(
                                reviewerUserId: widget.userId,
                                source: CustomerOrderSource.serviceRequest,
                                sourceId: _request!.id,
                                partnerName: _acceptedPartnerName(_request!),
                                itemTitle: _request!.skillCategory?.labelSwahili
                                    ?? _request!.skillCategoryRaw,
                              ),
                            ],
                            const SizedBox(height: 16),
                            _cancelButton(_request!, isSw),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _errorView(String msg, bool isSw) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 40),
          const SizedBox(height: 12),
          Text(
            msg,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            child: Text(isSw ? 'Jaribu tena' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(ServiceRequest r, bool isSw) {
    final skill = isSw
        ? (r.skillCategory?.labelSwahili ?? r.skillCategoryRaw)
        : (r.skillCategory?.label ?? r.skillCategoryRaw);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(r.skillCategory?.icon ?? Icons.handyman_rounded, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  skill,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Chip(
                label: Text(
                  isSw ? r.status.labelSwahili : r.status.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              LeadExpiringChipFetcher(
                orderId: r.id,
                sourceApiValue: 'service_request',
                isSwahili: isSw,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            r.problemSummary,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (r.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ApiConfig.sanitizeUrl(r.photos[i]) ?? r.photos[i],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 80,
                      height: 80,
                      color:
                          Theme.of(context).colorScheme.surface,
                      child: const Icon(Icons.broken_image_rounded),
                    ),
                  ),
                ),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: r.photos.length,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r.address,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (r.lat != null && r.lng != null)
                TextButton.icon(
                  onPressed: () => _openMaps(r),
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: Text(isSw ? 'Fungua Maps' : 'Open Maps'),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16),
              const SizedBox(width: 6),
              Text(
                isSw ? r.preferredWindow.labelSwahili : r.preferredWindow.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeline(ServiceRequest r, bool isSw) {
    final entries = <_TLEntry>[
      _TLEntry(
        title: isSw ? 'Ombi limewekwa' : 'Request posted',
        time: r.createdAt,
        done: true,
      ),
      _TLEntry(
        title: isSw ? 'Imekubaliwa' : 'Accepted',
        time: r.acceptedAt,
        done: r.acceptedAt != null,
      ),
      _TLEntry(
        title: isSw ? 'Yuko njiani' : 'En route',
        time: r.enRouteAt,
        done: r.enRouteAt != null,
      ),
      _TLEntry(
        title: isSw ? 'Yuko site' : 'On site',
        time: r.onSiteAt,
        done: r.onSiteAt != null,
      ),
      _TLEntry(
        title: isSw ? 'Imekamilika' : 'Completed',
        time: r.completedAt,
        done: r.completedAt != null,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSw ? 'Ratiba' : 'Timeline',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...entries.map((e) => _timelineRow(e)),
      ],
    );
  }

  Widget _timelineRow(_TLEntry e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            e.done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: e.done
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              e.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: e.done ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ),
          if (e.time != null)
            Text(
              _shortTime(e.time!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  String _shortTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  Widget _quotesSection(ServiceRequest r, bool isSw) {
    if (r.quotes.isEmpty) {
      if (r.status == ServiceRequestStatus.pending) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSw
                      ? 'Inasubiri majibu ya mafundi.'
                      : 'Waiting for pros to respond.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSw ? 'Bei zilizotolewa' : 'Quotes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...r.quotes.map((q) => _quoteCard(r, q, isSw)),
      ],
    );
  }

  Widget _quoteCard(ServiceRequest r, ServiceRequestQuote q, bool isSw) {
    final isAccepted = q.status == QuoteStatus.accepted;
    final isAutoRejected = q.status == QuoteStatus.autoRejected;
    final canAccept = r.status == ServiceRequestStatus.pending ||
        r.status == ServiceRequestStatus.quoted;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: const Icon(Icons.person_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    q.partnerName ??
                        (isSw ? 'Fundi' : 'Pro'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAccepted)
                  const Chip(
                    label: Text('OK'),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _kvRow(isSw ? 'Bei ya kuja' : 'Callout',
                'TZS ${q.calloutFeeTzs}'),
            if (q.estimatedCostTzs != null)
              _kvRow(isSw ? 'Makadirio' : 'Estimate',
                  'TZS ${q.estimatedCostTzs}'),
            _kvRow(isSw ? 'Atafika' : 'ETA',
                isSw ? q.eta.labelSwahili : q.eta.label),
            if (q.notes != null && q.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                q.notes!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isAutoRejected)
                  Text(
                    isSw ? 'Imeghairiwa' : 'Auto-rejected',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else if (canAccept && !isAccepted)
                  FilledButton(
                    onPressed:
                        _busy ? null : () => _acceptQuote(q),
                    child: Text(isSw ? 'Kubali' : 'Accept'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiCostAnchorBanner(ServiceRequest r, bool isSw) {
    String fmt(int? v) {
      if (v == null) return '—';
      final s = v.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        border: Border.all(color: const Color(0xFF0D47A1).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_rounded,
              size: 18, color: Color(0xFF0D47A1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSw
                      ? 'Wastani wa kazi kama hii (AI):'
                      : 'AI cost estimate range:',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                Text(
                  'TZS ${fmt(r.aiCostLowTzs)} – ${fmt(r.aiCostHighTzs)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                Text(
                  isSw
                      ? 'Hii ni wastani; bei halisi inategemea kazi.'
                      : 'Anchor only — final price depends on actual work.',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _beforeAfterSection(ServiceRequest r, bool isSw) {
    Widget gallery(List<String> urls, String title) {
      if (urls.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  ApiConfig.sanitizeUrl(urls[i]) ?? urls[i],
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFEEEEEE),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSw ? 'Picha za kazi' : 'Job photos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        gallery(r.beforePhotos, isSw ? 'Kabla' : 'Before'),
        if (r.beforePhotos.isNotEmpty && r.afterPhotos.isNotEmpty)
          const SizedBox(height: 8),
        gallery(r.afterPhotos, isSw ? 'Baada' : 'After'),
      ],
    );
  }

  Widget _revisedQuoteBanner(ServiceRequest r, bool isSw) {
    final v = r.revisedQuoteTzs ?? 0;
    String fmt(int v) {
      final s = v.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.update_rounded, size: 18, color: Color(0xFFE65100)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSw
                      ? 'Bei iliyorudiwa baada ya ukaguzi: TZS ${fmt(v)}'
                      : 'Revised post-diagnosis quote: TZS ${fmt(v)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE65100),
                  ),
                ),
                Text(
                  isSw
                      ? 'Kazi haitaanza hadi ukubali bei mpya.'
                      : 'Work pauses until you approve.',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _warrantyBadge(ServiceRequest r, bool isSw) {
    final expires = r.warrantyExpiresAt;
    if (expires == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final active = now.isBefore(expires);
    final daysLeft = expires.difference(now).inDays;
    final color = active ? const Color(0xFF1B5E20) : const Color(0xFF666666);
    final label = active
        ? (isSw
            ? 'Dhamana hai · siku $daysLeft zilizobaki'
            : 'Warranty active · $daysLeft days left')
        : (isSw ? 'Dhamana imeisha' : 'Warranty expired');
    String two(int n) => n.toString().padLeft(2, '0');
    final dateStr =
        '${two(expires.day)}/${two(expires.month)}/${expires.year}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            active
                ? Icons.verified_user_rounded
                : Icons.shield_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isSw ? 'Inaisha tarehe $dateStr' : 'Expires $dateStr',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _partsSection(ServiceRequest r, bool isSw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSw ? 'Vifaa' : 'Parts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...r.partsLineItems.map((p) {
          final markup = p.markupPct ?? r.partsMarkupPct;
          final markupText = markup != null ? ' (markup $markup%)' : '';
          return Text(
            '${p.name} TZS ${p.costTzs}$markupText',
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
      ],
    );
  }

  Widget _surveyBanner(ServiceRequest r, bool isSw) {
    final fee = r.siteSurveyFeeTzs ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        border: Border.all(color: const Color(0xFF0D47A1).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF0D47A1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSw
                      ? 'Ada ya ukaguzi: TZS $fee'
                      : 'Site survey fee: TZS $fee',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                if (r.parentRequestId != null)
                  Text(
                    isSw
                        ? 'Hili ni ukaguzi wa ombi #${r.parentRequestId}'
                        : 'This is a survey for request #${r.parentRequestId}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancelButton(ServiceRequest r, bool isSw) {
    if (r.hasFinalised) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: _busy ? null : _cancelRequest,
      icon: const Icon(Icons.cancel_outlined),
      label: Text(isSw ? 'Ghairi ombi' : 'Cancel request'),
    );
  }
}

class _TLEntry {
  final String title;
  final DateTime? time;
  final bool done;
  _TLEntry({required this.title, required this.time, required this.done});
}
