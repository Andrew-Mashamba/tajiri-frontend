import 'package:flutter/material.dart';
import '../../models/contribution_models.dart';
import '../../screens/campaigns/campaign_withdraw_screen.dart';
import '../../screens/campaigns/donate_to_campaign_screen.dart';
import '../../services/contribution_service.dart';
import '../../services/local_storage_service.dart';
import '../cached_media_image.dart';

/// Creator-focused Michango (Contributions/Fundraising) gallery for profile page
/// Features for campaign organizers:
/// - Create new campaign
/// - View all campaigns (active, completed, draft)
/// - Campaign analytics (raised amount, donors, withdrawals)
/// - Campaign management (edit, pause, complete, delete)
/// - Withdrawal management
/// - Post campaign updates
class MichangoGalleryWidget extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;
  final VoidCallback? onCreateCampaign;

  const MichangoGalleryWidget({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.onCreateCampaign,
  });

  @override
  State<MichangoGalleryWidget> createState() => _MichangoGalleryWidgetState();
}

class _MichangoGalleryWidgetState extends State<MichangoGalleryWidget>
    with SingleTickerProviderStateMixin {
  final ContributionService _contributionService = ContributionService();
  late TabController _tabController;

  List<Campaign> _allCampaigns = [];
  CampaignStats? _stats;
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;

  // Filtered lists
  List<Campaign> get _activeCampaigns =>
      _allCampaigns.where((c) => c.status == CampaignStatus.active).toList();
  List<Campaign> get _completedCampaigns =>
      _allCampaigns.where((c) => c.status == CampaignStatus.completed).toList();
  List<Campaign> get _draftCampaigns =>
      _allCampaigns.where((c) => c.status == CampaignStatus.draft || c.status == CampaignStatus.pending).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
    _loadData();
  }

  Future<void> _loadCurrentUser() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    if (mounted && user?.userId != null) {
      setState(() {
        _currentUserId = user!.userId;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final results = await Future.wait([
      _contributionService.getUserCampaigns(widget.userId),
      if (widget.isOwnProfile) _contributionService.getUserCampaignStats(widget.userId),
    ]);

    if (mounted) {
      final campaignsResult = results[0] as CampaignsResult;

      setState(() {
        _isLoading = false;
        if (campaignsResult.success) {
          _allCampaigns = campaignsResult.campaigns;
          if (widget.isOwnProfile && results.length > 1) {
            final statsResult = results[1] as StatsResult;
            _stats = statsResult.stats;
          }
        } else {
          _error = campaignsResult.message;
        }
      });
    }
  }

  void _navigateToCreateCampaign() {
    if (widget.onCreateCampaign != null) {
      widget.onCreateCampaign!();
    } else {
      Navigator.pushNamed(context, '/create-campaign').then((_) => _loadData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Creator action buttons
        if (widget.isOwnProfile) _buildCreatorHeader(),

        // Stats summary (only for own profile with data)
        if (widget.isOwnProfile && _stats != null) _buildStatsSummary(),

        // Tab bar
        _buildTabBar(),

        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const Color _background = Color(0xFFFAFAFA);

  Widget _buildCreatorHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Create Campaign button (DESIGN.md: white bg, 48dp min height)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                child: InkWell(
                  onTap: _navigateToCreateCampaign,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Anza Mchango',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Withdrawals button (min 48dp)
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _showWithdrawalsSheet,
              icon: const Icon(Icons.account_balance_wallet, size: 24),
              label: const Text('Toa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.volunteer_activism,
                value: _stats!.totalCampaigns.toString(),
                label: 'Michango',
              ),
              _buildStatItem(
                icon: Icons.people,
                value: _formatNumber(_stats!.totalDonors),
                label: 'Wafadhili',
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                value: 'TSh ${_formatCurrency(_stats!.totalRaised)}',
                label: 'Imekusanywa',
              ),
            ],
          ),
          if (_stats!.availableBalance > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Salio Linapatikana',
                            style: TextStyle(fontSize: 12, color: _secondary),
                          ),
                          Text(
                            'TSh ${_formatCurrency(_stats!.availableBalance)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Material(
                    color: _primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _showWithdrawalsSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text('Toa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: _primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _primary,
        unselectedLabelColor: _secondary,
        indicatorColor: _primary,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Inaendelea'),
                if (_activeCampaigns.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _buildBadge(_activeCampaigns.length, isActive: true),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Imekamilika'),
                if (_completedCampaigns.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _buildBadge(_completedCampaigns.length),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rasimu'),
                if (_draftCampaigns.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _buildBadge(_draftCampaigns.length),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? _primary : _accent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : _primary,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _secondary),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: _secondary)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadData,
              child: const Text('Jaribu tena'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Active campaigns
        _activeCampaigns.isEmpty
            ? _buildEmptyState(
                icon: Icons.campaign,
                title: 'Hakuna Michango Inayoendelea',
                message: 'Anza mchango wako wa kwanza kusaidia jamii au kupata msaada.',
              )
            : _buildCampaignsList(_activeCampaigns),
        // Completed campaigns
        _completedCampaigns.isEmpty
            ? _buildEmptyState(
                icon: Icons.check_circle_outline,
                title: 'Hakuna Michango Iliyokamilika',
                message: 'Michango iliyofanikiwa itaonekana hapa.',
              )
            : _buildCampaignsList(_completedCampaigns),
        // Draft campaigns
        _draftCampaigns.isEmpty
            ? _buildEmptyState(
                icon: Icons.edit_note,
                title: 'Hakuna Rasimu',
                message: 'Michango unayoiandaa itahifadhiwa hapa.',
              )
            : _buildCampaignsList(_draftCampaigns, isDraft: true),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: _secondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(fontSize: 14, color: _secondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.isOwnProfile) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _navigateToCreateCampaign,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Anza Mchango'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignsList(List<Campaign> campaigns, {bool isDraft = false}) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          return _buildCampaignCard(campaigns[index], isDraft: isDraft);
        },
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign, {bool isDraft = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _showCampaignDetails(campaign),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with overlay
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image
                  if (campaign.coverImageUrl != null && campaign.coverImageUrl!.isNotEmpty)
                    CachedMediaImage(
                      imageUrl: campaign.coverImageUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: _getCategoryColor(campaign.category).withValues(alpha: 0.2),
                      child: Icon(
                        _getCategoryIcon(campaign.category),
                        size: 64,
                        color: _getCategoryColor(campaign.category).withValues(alpha: 0.5),
                      ),
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),

                  // Status badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(campaign.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        campaign.status.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Verified badge
                  if (campaign.isVerified)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Imethibitishwa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Title and category at bottom
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(campaign.category),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            campaign.category.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          campaign.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: campaign.progressPercent / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TSh ${_formatCurrency(campaign.raisedAmount)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                            'ya TSh ${_formatCurrency(campaign.goalAmount)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _secondary,
                            ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${campaign.progressPercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primary,
                            ),
                          ),
                          Text(
                            '${campaign.donorsCount} wafadhili',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Deadline warning
                  if (campaign.hasDeadline && campaign.isActive && campaign.daysLeft >= 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: _primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            campaign.daysLeft == 0
                                ? 'Inaisha leo!'
                                : 'Siku ${campaign.daysLeft} zimebaki',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action buttons for own profile
                  if (widget.isOwnProfile) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (isDraft) ...[
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => _editCampaign(campaign),
                                icon: const Icon(Icons.edit, size: 20),
                                label: const Text('Hariri'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primary,
                                  side: const BorderSide(color: _primary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => _publishCampaign(campaign),
                                icon: const Icon(Icons.publish, size: 20),
                                label: const Text('Chapisha'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => _postUpdate(campaign),
                                icon: const Icon(Icons.edit_note, size: 20),
                                label: const Text('Habari'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primary,
                                  side: const BorderSide(color: _primary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => _showCampaignActions(campaign),
                                icon: const Icon(Icons.more_horiz, size: 20),
                                label: const Text('Zaidi'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primary,
                                  side: const BorderSide(color: _primary),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCampaignDetails(Campaign campaign) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Cover image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: campaign.coverImageUrl != null
                            ? CachedMediaImage(
                                imageUrl: campaign.coverImageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: _getCategoryColor(campaign.category).withValues(alpha: 0.2),
                                child: Icon(
                                  _getCategoryIcon(campaign.category),
                                  size: 64,
                                  color: _getCategoryColor(campaign.category),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            campaign.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(campaign.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            campaign.status.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress
                    _buildDetailedProgress(campaign),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Analytics grid
                    const Text(
                      'Takwimu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildAnalyticsGrid(campaign),

                    const SizedBox(height: 24),

                    // Donate button (Campaign detail → Donate – Story 82)
                    if (campaign.isActive) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 72,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          child: InkWell(
                            onTap: () {
                              if (_currentUserId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingia kwenye akaunti yako kuchangia'),
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(context);
                              Navigator.push<bool>(
                                context,
                                MaterialPageRoute<bool>(
                                  builder: (_) => DonateToCampaignScreen(
                                    campaign: campaign,
                                    currentUserId: _currentUserId!,
                                  ),
                                ),
                              ).then((donated) {
                                if (donated == true) _loadData();
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.volunteer_activism, color: _primary, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Changia Mchango',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Actions (organizer only)
                    if (widget.isOwnProfile) ...[
                      const Text(
                        'Vitendo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildActionsList(campaign),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedProgress(Campaign campaign) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TSh ${_formatCurrency(campaign.raisedAmount)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
              Text(
                '${campaign.progressPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: campaign.progressPercent / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lengo: TSh ${_formatCurrency(campaign.goalAmount)}',
                style: const TextStyle(fontSize: 13, color: _secondary),
              ),
              Text(
                '${campaign.donorsCount} wafadhili',
                style: const TextStyle(fontSize: 13, color: _secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid(Campaign campaign) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildAnalyticsTile(
          icon: Icons.people,
          value: campaign.donorsCount.toString(),
          label: 'Wafadhili',
        ),
        _buildAnalyticsTile(
          icon: Icons.visibility,
          value: _formatNumber(campaign.viewsCount),
          label: 'Watazamaji',
        ),
        _buildAnalyticsTile(
          icon: Icons.share,
          value: _formatNumber(campaign.sharesCount),
          label: 'Shiriki',
        ),
      ],
    );
  }

  Widget _buildAnalyticsTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _primary, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList(Campaign campaign) {
    return Column(
      children: [
        if (campaign.isActive) ...[
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Chapisha Habari'),
            subtitle: const Text('Arifu wafadhili kuhusu maendeleo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _postUpdate(campaign);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Omba Kutoa Fedha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _requestWithdrawal(campaign);
            },
          ),
          ListTile(
            leading: const Icon(Icons.pause_circle_outline),
            title: const Text('Simamisha Mchango'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _pauseCampaign(campaign);
            },
          ),
        ],
        if (campaign.status == CampaignStatus.paused)
          ListTile(
            leading: const Icon(Icons.play_circle_outline, color: _primary),
            title: const Text('Endelea na Mchango', style: TextStyle(color: _primary)),
            trailing: const Icon(Icons.chevron_right, color: _primary),
            onTap: () {
              Navigator.pop(context);
              _resumeCampaign(campaign);
            },
          ),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Hariri Mchango'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pop(context);
            _editCampaign(campaign);
          },
        ),
        ListTile(
          leading: const Icon(Icons.share),
          title: const Text('Shiriki'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pop(context);
            _shareCampaign(campaign);
          },
        ),
        if (campaign.status == CampaignStatus.draft)
          ListTile(
            leading: const Icon(Icons.delete, color: _primary),
            title: const Text('Futa Rasimu', style: TextStyle(color: _primary)),
            trailing: const Icon(Icons.chevron_right, color: _primary),
            onTap: () {
              Navigator.pop(context);
              _deleteCampaign(campaign);
            },
          ),
      ],
    );
  }

  void _showCampaignActions(Campaign campaign) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Chapisha Habari'),
              onTap: () {
                Navigator.pop(context);
                _postUpdate(campaign);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Omba Kutoa Fedha'),
              onTap: () {
                Navigator.pop(context);
                _requestWithdrawal(campaign);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Hariri'),
              onTap: () {
                Navigator.pop(context);
                _editCampaign(campaign);
              },
            ),
            if (campaign.isActive)
              ListTile(
                leading: const Icon(Icons.pause_circle_outline),
                title: const Text('Simamisha'),
                onTap: () {
                  Navigator.pop(context);
                  _pauseCampaign(campaign);
                },
              ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Maliza Mchango'),
              onTap: () {
                Navigator.pop(context);
                _completeCampaign(campaign);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawalsSheet() {
    // TODO: Show withdrawals management sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usimamizi wa Kutoa Fedha - Inakuja karibuni')),
    );
  }

  void _editCampaign(Campaign campaign) {
    // TODO: Navigate to edit campaign screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kuhariri mchango - Inakuja karibuni')),
    );
  }

  Future<void> _publishCampaign(Campaign campaign) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chapisha Mchango'),
        content: Text('Una uhakika unataka kuchapisha "${campaign.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ndiyo, Chapisha'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _contributionService.publishCampaign(campaign.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Mchango umechapishwa!' : (result.message ?? 'Imeshindwa')),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) _loadData();
      }
    }
  }

  Future<void> _pauseCampaign(Campaign campaign) async {
    final result = await _contributionService.pauseCampaign(campaign.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? 'Mchango umesimamishwa' : (result.message ?? 'Imeshindwa')),
          backgroundColor: result.success ? Colors.orange : Colors.red,
        ),
      );
      if (result.success) _loadData();
    }
  }

  Future<void> _resumeCampaign(Campaign campaign) async {
    final result = await _contributionService.resumeCampaign(campaign.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? 'Mchango unaendelea!' : (result.message ?? 'Imeshindwa')),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
      if (result.success) _loadData();
    }
  }

  Future<void> _completeCampaign(Campaign campaign) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maliza Mchango'),
        content: Text(
          'Una uhakika unataka kumaliza "${campaign.title}"?\n\nHautaweza kupokea michango zaidi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Ndiyo, Maliza'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _contributionService.completeCampaign(campaign.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Mchango umekamilika!' : (result.message ?? 'Imeshindwa')),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) _loadData();
      }
    }
  }

  Future<void> _deleteCampaign(Campaign campaign) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Rasimu'),
        content: Text('Una uhakika unataka kufuta "${campaign.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ndiyo, Futa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _contributionService.deleteCampaign(campaign.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Rasimu imefutwa' : (result.message ?? 'Imeshindwa')),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) _loadData();
      }
    }
  }

  void _postUpdate(Campaign campaign) {
    // TODO: Show post update dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kuchapisha habari - Inakuja karibuni')),
    );
  }

  void _requestWithdrawal(Campaign campaign) {
    if (_currentUserId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CampaignWithdrawScreen(
          campaign: campaign,
          userId: _currentUserId!,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _shareCampaign(Campaign campaign) {
    // TODO: Implement share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kushiriki - Inakuja karibuni')),
    );
  }

  Color _getStatusColor(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.draft:
        return _accent;
      case CampaignStatus.pending:
        return _secondary;
      case CampaignStatus.active:
        return _primary;
      case CampaignStatus.paused:
        return _secondary;
      case CampaignStatus.completed:
        return _primary;
      case CampaignStatus.cancelled:
        return _secondary;
      case CampaignStatus.rejected:
        return _primary;
    }
  }

  Color _getCategoryColor(CampaignCategory category) {
    // DESIGN.md monochrome: use grey scale
    switch (category) {
      case CampaignCategory.medical:
      case CampaignCategory.education:
      case CampaignCategory.emergency:
      case CampaignCategory.funeral:
      case CampaignCategory.wedding:
      case CampaignCategory.business:
      case CampaignCategory.community:
      case CampaignCategory.religious:
      case CampaignCategory.sports:
      case CampaignCategory.arts:
      case CampaignCategory.environment:
      case CampaignCategory.other:
        return _primary;
    }
  }

  IconData _getCategoryIcon(CampaignCategory category) {
    switch (category) {
      case CampaignCategory.medical:
        return Icons.medical_services;
      case CampaignCategory.education:
        return Icons.school;
      case CampaignCategory.emergency:
        return Icons.warning;
      case CampaignCategory.funeral:
        return Icons.sentiment_very_dissatisfied;
      case CampaignCategory.wedding:
        return Icons.favorite;
      case CampaignCategory.business:
        return Icons.business;
      case CampaignCategory.community:
        return Icons.groups;
      case CampaignCategory.religious:
        return Icons.church;
      case CampaignCategory.sports:
        return Icons.sports_soccer;
      case CampaignCategory.arts:
        return Icons.palette;
      case CampaignCategory.environment:
        return Icons.eco;
      case CampaignCategory.other:
        return Icons.category;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
