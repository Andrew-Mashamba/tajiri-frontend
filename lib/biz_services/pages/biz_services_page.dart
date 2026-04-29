import 'package:flutter/material.dart';
import '../../business/models/business_models.dart';
import '../../business/pages/business_profile_page.dart';
import '../../products/pages/products_page.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/biz_service_models.dart';
import '../services/biz_service_service.dart';
import 'biz_service_form_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BizServicesPage extends StatefulWidget {
  final int businessId;
  final Business business;
  final bool showAppBar;
  const BizServicesPage({super.key, required this.businessId, required this.business, this.showAppBar = true});

  @override
  State<BizServicesPage> createState() => _BizServicesPageState();
}

class _BizServicesPageState extends State<BizServicesPage> {
  bool _loading = true;
  List<BusinessService> _services = [];
  String? _token;
  int _userId = 0;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _userId = storage.getUser()?.userId ?? 0;
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    final services = await BizServiceService.getServices(_token!, widget.businessId);
    if (mounted) setState(() { _loading = false; _services = services; });
  }

  void _openForm({BusinessService? service}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BizServiceFormPage(
        businessId: widget.businessId,
        token: _token ?? '',
        service: service,
      )),
    );
    if (saved == true && mounted) _load();
  }

  void _showDetail(BusinessService s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ServiceDetailSheet(
        service: s,
        isSwahili: _isSwahili,
        token: _token ?? '',
        businessId: widget.businessId,
        onAvailabilityChanged: _load,
        onEdit: () { Navigator.pop(ctx); _openForm(service: s); },
        onDelete: () async {
          Navigator.pop(ctx);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dCtx) => AlertDialog(
              title: Text(_isSwahili ? 'Futa "${s.name}"?' : 'Delete "${s.name}"?'),
              content: Text(_isSwahili ? 'Haiwezi kurudishwa' : 'This cannot be undone'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, false),
                  child: Text(_isSwahili ? 'Hapana' : 'Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, true),
                  child: Text(_isSwahili ? 'Futa' : 'Delete',
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirmed != true || !mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          final ok = await BizServiceService.deleteService(_token!, widget.businessId, s.id);
          if (!mounted) return;
          messenger.showSnackBar(SnackBar(
            content: Text(ok
                ? (_isSwahili ? 'Huduma imefutwa' : 'Service deleted')
                : (_isSwahili ? 'Imeshindikana' : 'Failed')),
            backgroundColor: ok ? null : Colors.red,
          ));
          if (ok) _load();
        },
      ),
    );
  }

  Widget _pricingBadge(BusinessService s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(s.priceBadge(_isSwahili),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
    );
  }

  Widget _availabilityChip(ServiceAvailability a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: a.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(a.label(_isSwahili),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: a.color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(_isSwahili ? 'Huduma' : 'Services',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: _kCardBg,
              foregroundColor: _kPrimary,
              elevation: 0,
            )
          : null,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              color: _kPrimary,
              onRefresh: _load,
              child: _services.isEmpty
                  ? CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.miscellaneous_services_outlined, size: 72,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(_isSwahili ? 'Bado hakuna huduma' : 'No services yet',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                        color: _kPrimary)),
                                const SizedBox(height: 8),
                                Text(
                                  _isSwahili
                                      ? 'Ongeza huduma ili wateja wakupate'
                                      : 'Add services so clients can find your business',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: _kSecondary, fontSize: 14),
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: () => _openForm(),
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text(_isSwahili ? 'Ongeza Huduma' : 'Add Service'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _kPrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).pushNamed('/tea'),
                                  icon: const Icon(Icons.support_agent_rounded, color: _kPrimary, size: 18),
                                  label: Text(
                                    _isSwahili ? 'Uliza Shangazi' : 'Ask Shangazi',
                                    style: const TextStyle(color: _kPrimary, fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: _kPrimary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: _buildDiscoverabilityBanner(),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                final s = _services[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Material(
                                    color: _kCardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => _showDetail(s),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: s.photoUrl != null
                                                  ? Image.network(s.photoUrl!, width: 56, height: 56,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => _iconPlaceholder())
                                                  : _iconPlaceholder(),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontWeight: FontWeight.w600,
                                                          color: _kPrimary)),
                                                  const SizedBox(height: 4),
                                                  Row(children: [
                                                    _pricingBadge(s),
                                                    const SizedBox(width: 6),
                                                    _availabilityChip(s.availability),
                                                  ]),
                                                  if (s.inquiryCount > 0) ...[
                                                    const SizedBox(height: 4),
                                                    Row(children: [
                                                      const Icon(Icons.chat_bubble_outline_rounded,
                                                          size: 12, color: _kSecondary),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _isSwahili
                                                            ? '${s.inquiryCount} maombi'
                                                            : '${s.inquiryCount} ${s.inquiryCount == 1 ? "inquiry" : "inquiries"}',
                                                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                                                      ),
                                                    ]),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right, color: _kSecondary, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _services.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pushNamed('/tea'),
                              icon: const Icon(Icons.support_agent_rounded, color: _kPrimary, size: 18),
                              label: Text(
                                _isSwahili
                                    ? 'Uliza Shangazi kuhusu Bei za Huduma'
                                    : 'Ask Shangazi about Service Pricing',
                                style: const TextStyle(color: _kPrimary, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _kPrimary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
    );
  }

  Widget _buildDiscoverabilityBanner() {
    int score = 0;
    final List<({IconData icon, String label, VoidCallback onTap})> actions = [];

    void goToProfile() => Navigator.push(context, MaterialPageRoute(
        builder: (_) => BusinessProfilePage(userId: _userId, business: widget.business)));

    void goToProducts() => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProductsPage(businessId: widget.businessId, isDefaultShop: false, business: widget.business)));

    if (widget.business.logoUrl != null && widget.business.logoUrl!.isNotEmpty) {
      score += 20;
    } else {
      actions.add((
        icon: Icons.account_circle_outlined,
        label: _isSwahili ? 'Ongeza nembo ya biashara (+20)' : 'Add business logo (+20)',
        onTap: goToProfile,
      ));
    }

    actions.add((
      icon: Icons.inventory_2_outlined,
      label: _isSwahili ? 'Ongeza bidhaa 3+ kwenye biashara (+20)' : 'Add 3+ products to your business (+20)',
      onTap: goToProducts,
    ));

    actions.add((
      icon: Icons.description_outlined,
      label: _isSwahili ? 'Ongeza maelezo kwenye bidhaa (+15)' : 'Add descriptions to your products (+15)',
      onTap: goToProducts,
    ));

    if (_services.isNotEmpty) {
      score += 20;
    } else {
      actions.add((
        icon: Icons.miscellaneous_services_outlined,
        label: _isSwahili ? 'Ongeza huduma (+20)' : 'Add services (+20)',
        onTap: _openForm,
      ));
    }

    if (widget.business.sector != null && widget.business.sector!.isNotEmpty) {
      score += 15;
    } else {
      actions.add((
        icon: Icons.category_outlined,
        label: _isSwahili ? 'Weka sekta ya biashara (+15)' : 'Fill in your business sector (+15)',
        onTap: goToProfile,
      ));
    }

    if (widget.business.phone != null && widget.business.phone!.isNotEmpty) {
      score += 10;
    } else {
      actions.add((
        icon: Icons.phone_outlined,
        label: _isSwahili ? 'Ongeza nambari ya simu (+10)' : 'Add business phone number (+10)',
        onTap: goToProfile,
      ));
    }

    if (_services.isEmpty) return const SizedBox.shrink();

    final displayActions = actions.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFFF57F17)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _isSwahili ? 'Uonekano: $score/100' : 'Discoverability score: $score/100',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFF57F17)),
            )),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: const Color(0xFFFFE082),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF57F17)),
              minHeight: 6,
            ),
          ),
          if (displayActions.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...displayActions.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: a.onTap,
                behavior: HitTestBehavior.opaque,
                child: Row(children: [
                  Icon(a.icon, size: 13, color: const Color(0xFFF57F17)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(a.label,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFF57F17)))),
                  const Icon(Icons.chevron_right, size: 13, color: Color(0xFFF57F17)),
                ]),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _iconPlaceholder() => Container(
    width: 56, height: 56,
    color: Colors.grey.shade100,
    child: const Icon(Icons.miscellaneous_services_outlined, color: Colors.grey),
  );
}

class _ServiceDetailSheet extends StatefulWidget {
  final BusinessService service;
  final bool isSwahili;
  final String token;
  final int businessId;
  final VoidCallback onAvailabilityChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ServiceDetailSheet({
    required this.service,
    required this.isSwahili,
    required this.token,
    required this.businessId,
    required this.onAvailabilityChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ServiceDetailSheet> createState() => _ServiceDetailSheetState();
}

class _ServiceDetailSheetState extends State<_ServiceDetailSheet> {
  late ServiceAvailability _availability;
  bool _patching = false;

  @override
  void initState() {
    super.initState();
    _availability = widget.service.availability;
  }

  Future<void> _setAvailability(ServiceAvailability a) async {
    if (a == _availability || _patching) return;
    setState(() { _availability = a; _patching = true; });
    final ok = await BizServiceService.patchServiceAvailability(
      widget.token, widget.businessId, widget.service.id, a);
    if (!mounted) return;
    setState(() => _patching = false);
    if (!ok) {
      setState(() => _availability = widget.service.availability);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isSwahili ? 'Imeshindikana' : 'Failed to update'),
        backgroundColor: Colors.red,
      ));
    } else {
      final String msg;
      switch (a) {
        case ServiceAvailability.available:
          msg = widget.isSwahili ? 'Sasa inaonekana kuwa Inapatikana' : 'Now showing as Available';
        case ServiceAvailability.unavailable:
          msg = widget.isSwahili ? 'Sasa inaonekana kuwa Haipatikani' : 'Now showing as Unavailable';
        case ServiceAvailability.byRequest:
          msg = widget.isSwahili ? 'Sasa inaonekana kuwa Kwa Ombi' : 'Now showing as By Request';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      widget.onAvailabilityChanged();
      if (a == ServiceAvailability.unavailable && mounted) {
        final goToCalendar = await showDialog<bool>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text(widget.isSwahili ? 'Zuia Tarehe kwenye Kalenda?' : 'Block these dates on Calendar?'),
            content: Text(widget.isSwahili
                ? 'Ungependa kuzuia tarehe kwenye kalenda yako?'
                : 'Would you like to block off dates on your calendar?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx, false),
                  child: Text(widget.isSwahili ? 'Hapana' : 'No')),
              TextButton(onPressed: () => Navigator.pop(dCtx, true),
                  child: Text(widget.isSwahili ? 'Ndio' : 'Yes',
                      style: const TextStyle(color: _kPrimary))),
            ],
          ),
        );
        if (goToCalendar == true && mounted) {
          Navigator.of(context).pushNamed('/calendar');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + viewInsets),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          if (s.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(s.photoUrl!, height: 160, width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          const SizedBox(height: 12),
          Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: _kPrimary)),
          const SizedBox(height: 4),
          Wrap(spacing: 8, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(s.priceBadge(widget.isSwahili),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
            ),
            if (s.durationMinutes != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_outlined, size: 13, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(_formatDuration(s.durationMinutes!),
                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ]),
              ),
            if (s.category != null && s.category!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(s.category!,
                    style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ),
          ]),
          if (s.inquiryCount > 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              Text(
                widget.isSwahili ? 'Maswali Mwezi Huu' : 'Inquiries This Month',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                s.inquiryCount.toString(),
                style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600),
              ),
            ]),
          ],
          if (s.lastInquiryAt != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Text(
                widget.isSwahili ? 'Swali la Mwisho' : 'Last Inquiry',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                _formatLastInquiry(s.lastInquiryAt!),
                style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600),
              ),
            ]),
          ],
          if (s.description != null) ...[
            const SizedBox(height: 12),
            Text(s.description!, style: const TextStyle(color: _kSecondary)),
          ],
          const SizedBox(height: 16),
          Text(
            widget.isSwahili ? 'Upatikanaji' : 'Availability',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ServiceAvailability.values.map((a) => ChoiceChip(
              label: _patching && a == _availability
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                  : Text(a.label(widget.isSwahili)),
              selected: _availability == a,
              selectedColor: a.color.withValues(alpha: 0.15),
              onSelected: _patching ? null : (_) => _setAvailability(a),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _availability == a ? a.color : _kSecondary,
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/appointments'),
              icon: const Icon(Icons.calendar_today_outlined, size: 16, color: _kPrimary),
              label: Text(
                widget.isSwahili ? 'Tazama Miadi ya Huduma Hii' : 'View Bookings for this Service',
                style: const TextStyle(color: _kPrimary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                label: Text(widget.isSwahili ? 'Futa' : 'Delete',
                    style: const TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: Text(widget.isSwahili ? 'Hariri' : 'Edit'),
                style: FilledButton.styleFrom(backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ]),
          ],
        ),
      ),
    );
  }

  String _formatLastInquiry(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days == 0) return widget.isSwahili ? 'Leo' : 'Today';
    if (days == 1) return widget.isSwahili ? 'Jana' : 'Yesterday';
    return widget.isSwahili ? '$days siku zilizopita' : '$days days ago';
  }

  String _formatDuration(int minutes) {
    if (minutes >= 1440) {
      final days = minutes ~/ 1440;
      return widget.isSwahili ? '$days siku' : '$days ${days == 1 ? "day" : "days"}';
    }
    if (minutes >= 60) {
      final hrs = minutes ~/ 60;
      final rem = minutes % 60;
      if (rem == 0) return widget.isSwahili ? '$hrs saa' : '$hrs ${hrs == 1 ? "hr" : "hrs"}';
      return widget.isSwahili ? '$hrs saa $rem dak' : '${hrs}h ${rem}m';
    }
    return widget.isSwahili ? '$minutes dak' : '$minutes min';
  }
}
