import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../tajirika/models/tajirika_models.dart' show SkillCategory, PartnerProduct;
import '../../tajirika/widgets/my_partner_c2b_activity_card.dart';
import '../../tajirika/widgets/partner_product_rail.dart';
import '../models/service_request.dart';
import '../services/service_request_service.dart';
import 'partner_product_detail_page.dart';
import 'request_service_page.dart';
import 'service_request_status_page.dart';

class MafundiHomePage extends StatefulWidget {
  final int userId;
  const MafundiHomePage({super.key, required this.userId});

  @override
  State<MafundiHomePage> createState() => _MafundiHomePageState();
}

class _MafundiHomePageState extends State<MafundiHomePage> {
  static const List<SkillCategory> _skills = [
    SkillCategory.plumbing,
    SkillCategory.electrical,
    SkillCategory.painting,
    SkillCategory.roofing,
    SkillCategory.solarInstallation,
  ];

  bool _loading = true;
  List<ServiceRequest> _myRequests = const [];
  String? _loadError;

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
      _loadError = null;
    });
    final res = await ServiceRequestService.list(
      userId: widget.userId,
      role: 'customer',
      limit: 20,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _myRequests = res.requests;
      } else {
        _loadError = res.message;
      }
    });
  }

  void _openPartnerProduct(PartnerProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PartnerProductDetailPage(
          productId: product.id,
          initial: product,
        ),
      ),
    );
  }

  Future<void> _openRequestForm({SkillCategory? preselect}) async {
    final created = await Navigator.of(context).push<ServiceRequest>(
      MaterialPageRoute(
        builder: (_) => RequestServicePage(
          userId: widget.userId,
          preselectedSkill: preselect,
        ),
      ),
    );
    if (!mounted) return;
    if (created != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ServiceRequestStatusPage(
            userId: widget.userId,
            requestId: created.id,
          ),
        ),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Mafundi' : 'Tradespeople'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const MyPartnerC2BActivityCard(
                sourceType: 'service_request',
                role: 'customer',
              ),
              _heroCard(isSw),
              const SizedBox(height: 24),
              Text(
                isSw ? 'Chagua aina ya kazi' : 'Pick a service',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _skillsGrid(isSw),
              const SizedBox(height: 24),
              PartnerProductRail(
                titleSwahili: isSw ? 'Huduma za Mafundi' : 'Pro Services',
                domain: 'mafundi',
                onTapProduct: _openPartnerProduct,
              ),
              const SizedBox(height: 8),
              Text(
                isSw ? 'Maombi yangu' : 'My requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                _errorTile(_loadError!, isSw)
              else if (_myRequests.isEmpty)
                _emptyMyRequests(isSw)
              else
                ..._myRequests.map((r) => _requestTile(r, isSw)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRequestForm(),
        icon: const Icon(Icons.handyman_rounded),
        label: Text(isSw ? 'Ita Fundi' : 'Request a Pro'),
      ),
    );
  }

  Widget _heroCard(bool isSw) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.engineering_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSw
                      ? 'Mafundi waaminifu, karibu nawe'
                      : 'Trusted pros, near you',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isSw
                      ? 'Tuma picha ya tatizo, pokea bei kabla wengine kuja.'
                      : 'Send a photo, get quotes before anyone shows up.',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillsGrid(bool isSw) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: _skills.map((s) => _skillCard(s, isSw)).toList(),
    );
  }

  Widget _skillCard(SkillCategory skill, bool isSw) {
    return InkWell(
      onTap: () => _openRequestForm(preselect: skill),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              skill.icon,
              size: 28,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSw ? skill.labelSwahili : skill.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorTile(String msg, bool isSw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _load,
            child: Text(isSw ? 'Jaribu tena' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _emptyMyRequests(bool isSw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSw
                  ? 'Bado huja tuma ombi lolote. Tap "Ita Fundi" hapo chini.'
                  : 'No requests yet. Tap "Request a Pro" below.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestTile(ServiceRequest r, bool isSw) {
    final skillLabel = isSw
        ? (r.skillCategory?.labelSwahili ?? r.skillCategoryRaw)
        : (r.skillCategory?.label ?? r.skillCategoryRaw);
    final statusLabel = isSw ? r.status.labelSwahili : r.status.label;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            r.skillCategory?.icon ?? Icons.handyman_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        title: Text(
          skillLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.problemSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                if (r.partsLineItems.isNotEmpty)
                  Chip(
                    label: Text(isSw ? 'Vifaa' : 'Parts'),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                if (r.siteSurveyFeeTzs != null || r.parentRequestId != null)
                  Chip(
                    label: Text(isSw ? 'Ukaguzi' : 'Survey'),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            statusLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ServiceRequestStatusPage(
                userId: widget.userId,
                requestId: r.id,
              ),
            ),
          );
          if (mounted) _load();
        },
      ),
    );
  }
}
