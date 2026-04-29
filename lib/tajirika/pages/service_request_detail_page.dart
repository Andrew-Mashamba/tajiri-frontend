import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../mafundi/models/service_request.dart';
import '../../mafundi/services/service_request_service.dart';
import '../../mafundi/widgets/parts_line_editor.dart';
import '../../mafundi/widgets/site_survey_booking_sheet.dart';

class ServiceRequestDetailPage extends StatefulWidget {
  final int userId;
  final int requestId;

  const ServiceRequestDetailPage({
    super.key,
    required this.userId,
    required this.requestId,
  });

  @override
  State<ServiceRequestDetailPage> createState() =>
      _ServiceRequestDetailPageState();
}

class _ServiceRequestDetailPageState extends State<ServiceRequestDetailPage> {
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

  ServiceRequestQuote? _myQuote() {
    if (_request == null) return null;
    final mine = _request!.quotes
        .where((q) => q.partnerUserId == widget.userId)
        .toList();
    return mine.isEmpty ? null : mine.first;
  }

  Future<void> _openQuoteDialog() async {
    final isSw = _isSwahili;
    final calloutCtrl = TextEditingController(
      text: _myQuote()?.calloutFeeTzs.toString() ?? '',
    );
    final estimateCtrl = TextEditingController(
      text: _myQuote()?.estimatedCostTzs?.toString() ?? '',
    );
    final notesCtrl = TextEditingController(text: _myQuote()?.notes ?? '');
    QuoteEta eta = _myQuote()?.eta ?? QuoteEta.oneHour;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(isSw ? 'Toa nukuu' : 'Submit quote'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: calloutCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isSw ? 'Bei ya kuja (TZS)' : 'Callout fee (TZS)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: estimateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isSw
                        ? 'Makadirio ya jumla (hiari)'
                        : 'Estimate (optional)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: QuoteEta.values.map((e) {
                    return ChoiceChip(
                      label: Text(isSw ? e.labelSwahili : e.label),
                      selected: eta == e,
                      onSelected: (_) => setSt(() => eta = e),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isSw ? 'Maelezo (hiari)' : 'Notes (optional)',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(isSw ? 'Ghairi' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final callout = int.tryParse(calloutCtrl.text.trim());
                if (callout == null || callout <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(isSw
                        ? 'Andika bei sahihi'
                        : 'Enter a valid callout fee'),
                  ));
                  return;
                }
                final estimate = int.tryParse(estimateCtrl.text.trim());
                Navigator.of(ctx).pop(true);
                setState(() => _busy = true);
                final res = await ServiceRequestService.quote(
                  id: widget.requestId,
                  userId: widget.userId,
                  calloutFeeTzs: callout,
                  estimatedCostTzs: estimate,
                  eta: eta,
                  notes: notesCtrl.text.trim(),
                );
                if (!mounted) return;
                setState(() => _busy = false);
                if (res.success && res.request != null) {
                  setState(() => _request = res.request);
                  _toast(isSw ? 'Nukuu imewasilishwa' : 'Quote sent');
                } else {
                  _toast(res.message ??
                      (isSw ? 'Imeshindikana' : 'Failed'));
                }
              },
              child: Text(isSw ? 'Tuma' : 'Send'),
            ),
          ],
        ),
      ),
    );
    if (result == null) {
      // dismissed
    }
  }

  Future<void> _doAction(Future<ServiceRequestResult> Function() fn,
      String okMsgSw, String okMsgEn) async {
    setState(() => _busy = true);
    final res = await fn();
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.success && res.request != null) {
      setState(() => _request = res.request);
      _toast(_isSwahili ? okMsgSw : okMsgEn);
    } else {
      _toast(res.message ??
          (_isSwahili ? 'Imeshindikana' : 'Failed'));
    }
  }

  Future<void> _enRoute() => _doAction(
        () => ServiceRequestService.enRoute(
            id: widget.requestId, userId: widget.userId),
        'Hali: yuko njiani',
        'Status: en route',
      );

  Future<void> _onSite() => _doAction(
        () => ServiceRequestService.onSite(
            id: widget.requestId, userId: widget.userId),
        'Hali: yuko site',
        'Status: on site',
      );

  Future<void> _complete() async {
    final isSw = _isSwahili;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Imekamilika?' : 'Mark complete?'),
        content: Text(isSw
            ? 'Hii itamtaarifu mteja na kuanzisha malipo.'
            : 'This will notify the customer and trigger payment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isSw ? 'Hapana' : 'No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isSw ? 'Ndiyo' : 'Yes'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _doAction(
      () => ServiceRequestService.complete(
          id: widget.requestId, userId: widget.userId),
      'Imekamilika',
      'Completed',
    );
  }

  Future<void> _reject() async {
    final isSw = _isSwahili;
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Kataa ombi?' : 'Reject request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: isSw ? 'Sababu (hiari)' : 'Reason (optional)',
                border: const OutlineInputBorder(),
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
            child: Text(isSw ? 'Kataa' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _doAction(
      () => ServiceRequestService.cancel(
          id: widget.requestId,
          userId: widget.userId,
          reason: reasonCtrl.text.trim()),
      'Umekataa ombi',
      'Rejected',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Ombi la huduma' : 'Service request'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 40),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(isSw ? 'Jaribu tena' : 'Retry'),
                        ),
                      ],
                    ),
                  )
                : _request == null
                    ? Center(child: Text(isSw ? 'Hakuna data' : 'No data'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          children: [
                            _photoCarousel(_request!),
                            const SizedBox(height: 12),
                            _customerCard(_request!, isSw),
                            const SizedBox(height: 12),
                            _problemCard(_request!, isSw),
                            const SizedBox(height: 12),
                            _addressCard(_request!, isSw),
                            const SizedBox(height: 12),
                            _myQuoteCard(isSw),
                            if (_request!.partsLineItems.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _partsCard(_request!, isSw),
                            ],
                          ],
                        ),
                      ),
      ),
      bottomNavigationBar: _request == null ? null : _actionBar(_request!, isSw),
    );
  }

  Widget _photoCarousel(ServiceRequest r) {
    if (r.photos.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.image_not_supported_rounded)),
      );
    }
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: r.photos.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              ApiConfig.sanitizeUrl(r.photos[i]) ?? r.photos[i],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_rounded),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _customerCard(ServiceRequest r, bool isSw) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.surface,
            backgroundImage:
                (r.customerPhotoUrl != null && r.customerPhotoUrl!.isNotEmpty)
                    ? NetworkImage(
                        ApiConfig.sanitizeUrl(r.customerPhotoUrl!) ??
                            r.customerPhotoUrl!,
                      )
                    : null,
            child: (r.customerPhotoUrl == null || r.customerPhotoUrl!.isEmpty)
                ? const Icon(Icons.person_rounded)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.customerName ?? (isSw ? 'Mteja' : 'Customer'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (r.customerPhone != null && r.customerPhone!.isNotEmpty)
                  Text(
                    r.customerPhone!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
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
        ],
      ),
    );
  }

  Widget _problemCard(ServiceRequest r, bool isSw) {
    final skill = isSw
        ? (r.skillCategory?.labelSwahili ?? r.skillCategoryRaw)
        : (r.skillCategory?.label ?? r.skillCategoryRaw);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(r.skillCategory?.icon ?? Icons.handyman_rounded, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skill,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isSw ? r.preferredWindow.labelSwahili : r.preferredWindow.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.problemSummary,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _addressCard(ServiceRequest r, bool isSw) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              r.address,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _myQuoteCard(bool isSw) {
    final mine = _myQuote();
    if (mine == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Nukuu yangu' : 'My quote',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(isSw
              ? 'Bei ya kuja: TZS ${mine.calloutFeeTzs}'
              : 'Callout: TZS ${mine.calloutFeeTzs}'),
          if (mine.estimatedCostTzs != null)
            Text(isSw
                ? 'Makadirio: TZS ${mine.estimatedCostTzs}'
                : 'Estimate: TZS ${mine.estimatedCostTzs}'),
          Text(isSw
              ? 'Atafika: ${mine.eta.labelSwahili}'
              : 'ETA: ${mine.eta.label}'),
          if (mine.notes != null && mine.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(mine.notes!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _partsCard(ServiceRequest r, bool isSw) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Vifaa' : 'Parts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
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
      ),
    );
  }

  void _openPartsEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PartsLineEditor(
          requestId: widget.requestId,
          userId: widget.userId,
          initialItems: _request?.partsLineItems ?? [],
          initialMarkupPct: _request?.partsMarkupPct,
          onSaved: () {
            if (mounted) _load();
          },
        ),
      ),
    );
  }

  void _openSurveySheet() {
    final isSw = _isSwahili;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SiteSurveyBookingSheet(
        requestId: widget.requestId,
        userId: widget.userId,
      ),
    ).then((value) {
      if (value is ServiceRequest && mounted) {
        _toast(isSw ? 'Ukaguzi umeanzishwa' : 'Survey created');
        _load();
      }
    });
  }

  Widget _actionBar(ServiceRequest r, bool isSw) {
    final isAssignedPartner = r.acceptedPartnerUserId == widget.userId;
    final mine = _myQuote();

    final secondary = <Widget>[];
    if (isAssignedPartner &&
        (r.status == ServiceRequestStatus.accepted ||
            r.status == ServiceRequestStatus.enRoute ||
            r.status == ServiceRequestStatus.onSite)) {
      secondary.add(
        TextButton.icon(
          onPressed: _busy ? null : _openPartsEditor,
          icon: const Icon(Icons.handyman_rounded, size: 18),
          label: Text(isSw ? 'Hariri vifaa' : 'Edit parts'),
        ),
      );
      if (r.siteSurveyFeeTzs == null && r.parentRequestId == null) {
        secondary.add(
          TextButton.icon(
            onPressed: _busy ? null : _openSurveySheet,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: Text(isSw ? 'Endesha ukaguzi' : 'Run survey'),
          ),
        );
      }
    }

    final buttons = <Widget>[];
    switch (r.status) {
      case ServiceRequestStatus.pending:
      case ServiceRequestStatus.quoted:
        buttons.add(
          Expanded(
            child: FilledButton.icon(
              onPressed: _busy ? null : _openQuoteDialog,
              icon: const Icon(Icons.request_quote_rounded),
              label: Text(mine == null
                  ? (isSw ? 'Nukuu' : 'Quote')
                  : (isSw ? 'Sasisha nukuu' : 'Update quote')),
            ),
          ),
        );
        buttons.add(const SizedBox(width: 8));
        buttons.add(
          OutlinedButton(
            onPressed: _busy ? null : _reject,
            child: Text(isSw ? 'Kataa' : 'Reject'),
          ),
        );
        break;
      case ServiceRequestStatus.accepted:
        if (isAssignedPartner) {
          buttons.add(
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _enRoute,
                icon: const Icon(Icons.directions_car_rounded),
                label: Text(isSw ? 'Niko Njiani' : 'En route'),
              ),
            ),
          );
          buttons.add(const SizedBox(width: 8));
          buttons.add(
            OutlinedButton(
              onPressed: _busy ? null : _reject,
              child: Text(isSw ? 'Ghairi' : 'Cancel'),
            ),
          );
        }
        break;
      case ServiceRequestStatus.enRoute:
        if (isAssignedPartner) {
          buttons.add(
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _onSite,
                icon: const Icon(Icons.place_rounded),
                label: Text(isSw ? 'Nimefika' : 'On site'),
              ),
            ),
          );
        }
        break;
      case ServiceRequestStatus.onSite:
        if (isAssignedPartner) {
          buttons.add(
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _complete,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(isSw ? 'Imekamilika' : 'Complete'),
              ),
            ),
          );
        }
        break;
      case ServiceRequestStatus.completed:
      case ServiceRequestStatus.cancelled:
      case ServiceRequestStatus.rejected:
        return const SizedBox.shrink();
    }

    if (buttons.isEmpty && secondary.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (secondary.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: secondary,
              ),
            if (secondary.isNotEmpty && buttons.isNotEmpty)
              const SizedBox(height: 8),
            if (buttons.isNotEmpty) Row(children: buttons),
          ],
        ),
      ),
    );
  }
}
