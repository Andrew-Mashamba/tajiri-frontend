import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/profile_tab_config.dart';
import '../../services/local_storage_service.dart';

/// Profile tab configuration screen. Navigation: Home → Profile → Settings → Profile Tabs Settings (STORY-76).
/// Enable/disable, reorder within categories, move tabs between categories,
/// and manage categories (add, rename, delete empty); persisted in Hive.
class ProfileTabsSettingsScreen extends StatefulWidget {
  const ProfileTabsSettingsScreen({super.key});

  @override
  State<ProfileTabsSettingsScreen> createState() => _ProfileTabsSettingsScreenState();
}

class _ProfileTabsSettingsScreenState extends State<ProfileTabsSettingsScreen> {
  static const Color _backgroundLight = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _cardBackground = Color(0xFFFFFFFF);
  static const Color _accentGray = Color(0xFF999999);
  static const Color _dividerColor = Color(0xFFE0E0E0);
  static const double _minTouchTarget = 48.0;

  /// Tab IDs that are protected from editing so the user cannot lock themselves out.
  static const Set<String> _protectedTabIds = {'settings'};

  List<ProfileTabConfig> _tabs = [];
  List<String> _userCategoryIds = [];
  Map<String, String> _customLabels = {};
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final storage = await LocalStorageService.getInstance();
    if (!mounted) return;
    final cats = storage.getUserCategories();
    setState(() {
      _tabs = storage.getProfileTabs();
      _userCategoryIds = cats.ids;
      _customLabels = cats.labels;
      _isLoading = false;
      _isSaving = false;
      _error = null;
      _hasChanges = false;
    });
  }

  Future<void> _saveAll() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      await storage.saveProfileTabs(_tabs);
      await storage.saveUserCategories(_userCategoryIds, _customLabels);
      if (!mounted) return;
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.profileTabsSaved ?? 'Settings saved')),
      );
    } catch (e) {
      if (mounted) {
        final s = AppStringsScope.of(context);
        setState(() {
          _isSaving = false;
          _error = s?.profileTabsSaveFailed ?? 'Failed to save settings';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final s = AppStringsScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.resetSettingsConfirmTitle ?? 'Reset settings'),
        content: Text(s?.resetSettingsConfirmMessage ?? 'All tab settings will be reset to default. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s?.no ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s?.yes ?? 'Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        final storage = await LocalStorageService.getInstance();
        await storage.resetProfileTabs();
        await _loadAll();
        if (!mounted) return;
        setState(() => _hasChanges = false);
        final s = AppStringsScope.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s?.profileTabsReset ?? 'Settings reset')),
        );
      } catch (e) {
        if (!mounted) return;
        final s = AppStringsScope.of(context);
        setState(() {
          _isSaving = false;
          _error = s?.profileTabsSaveFailed ?? 'Failed to save settings';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Tabs that can be edited (excludes protected system tabs).
  List<ProfileTabConfig> get _editableTabs {
    return _tabs.where((t) => !_protectedTabIds.contains(t.id)).toList();
  }

  /// Resolve category ID for a tab, falling back to static defaults.
  String _categoryIdFor(ProfileTabConfig tab) {
    return tab.categoryId ?? ProfileTabDefaults.getDefaultCategoryId(tab.id);
  }

  /// All category IDs in order: defaults first, then user-created.
  List<String> get _allCategoryIds {
    final defaultIds = ProfileTabDefaults.categories.map((c) => c.id).toList();
    final userIds = _userCategoryIds.where((id) => !defaultIds.contains(id)).toList();
    return [...defaultIds, ...userIds];
  }

  /// Categories that have at least one editable tab, or are user-created (even if empty).
  List<String> get _visibleCategoryIds {
    final groups = _tabsByCategory();
    return _allCategoryIds.where((id) {
      if (groups.containsKey(id) && groups[id]!.isNotEmpty) return true;
      if (_userCategoryIds.contains(id)) return true;
      return false;
    }).toList();
  }

  /// Resolve label for a category: custom override → AppStrings → uppercase ID.
  String _categoryLabel(String catId, AppStrings? s) {
    if (_customLabels.containsKey(catId)) return _customLabels[catId]!;
    return s?.profileTabCategoryLabel(catId) ?? catId.toUpperCase();
  }

  /// Group editable tabs by their category ID.
  Map<String, List<ProfileTabConfig>> _tabsByCategory() {
    final groups = <String, List<ProfileTabConfig>>{};
    for (final tab in _editableTabs) {
      final catId = _categoryIdFor(tab);
      groups.putIfAbsent(catId, () => []).add(tab);
    }
    for (final list in groups.values) {
      list.sort((a, b) {
        final cmp = a.order.compareTo(b.order);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });
    }
    return groups;
  }

  bool _isCategoryEmpty(String catId) {
    return !_tabsByCategory().containsKey(catId);
  }

  // ── Category CRUD ─────────────────────────────────────────────────────────

  void _showCategoryDialog({String? existingId}) {
    final s = AppStringsScope.of(context);
    final isEditing = existingId != null;
    final controller = TextEditingController(
      text: isEditing ? _categoryLabel(existingId, s) : '',
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing
            ? (s?.editCategory ?? 'Edit Category')
            : (s?.addCategory ?? 'Add Category')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: s?.categoryName ?? 'Category Name',
            hintText: s?.categoryNameHint ?? 'Enter category name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s?.categoryCannotBeEmpty ?? 'Category name cannot be empty')),
                );
                return;
              }
              if (isEditing) {
                _editCategory(existingId, name);
              } else {
                _addCategory(name);
              }
              Navigator.pop(context);
            },
            child: Text(s?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  void _addCategory(String name) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _userCategoryIds.add(id);
      _customLabels[id] = name;
      _hasChanges = true;
    });
  }

  void _editCategory(String catId, String newName) {
    setState(() {
      _customLabels[catId] = newName;
      _hasChanges = true;
    });
  }

  void _deleteCategory(String catId) {
    final s = AppStringsScope.of(context);
    if (!_isCategoryEmpty(catId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.categoryNotEmpty ?? 'Category is not empty — cannot delete')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.deleteCategory ?? 'Delete Category'),
        content: Text(s?.categoryDeleteConfirm ?? 'This category will be deleted. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s?.no ?? 'No'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _userCategoryIds.remove(catId);
                _customLabels.remove(catId);
                _hasChanges = true;
              });
              Navigator.pop(context);
            },
            child: Text(s?.yes ?? 'Yes'),
          ),
        ],
      ),
    );
  }

  // ── Tab actions ───────────────────────────────────────────────────────────

  void _toggleTab(String tabId) {
    final idx = _tabs.indexWhere((t) => t.id == tabId);
    if (idx < 0) return;
    final tab = _tabs[idx];
    final enabledCount = _editableTabs.where((t) => t.enabled).length;
    if (tab.enabled && enabledCount <= 1) {
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.minOneTab ?? 'At least one tab must be enabled')),
      );
      return;
    }
    setState(() {
      _tabs[idx] = tab.copyWith(enabled: !tab.enabled);
      _hasChanges = true;
    });
  }

  void _reorderCategoryTabs(String categoryId, int oldIndex, int newIndex) {
    final categoryTabs = _editableTabs
        .where((t) => _categoryIdFor(t) == categoryId)
        .toList()
      ..sort((a, b) {
        final cmp = a.order.compareTo(b.order);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

    // Capture original order values before reordering.
    final originalOrders = categoryTabs.map((t) => t.order).toList();

    if (newIndex > oldIndex) newIndex -= 1;
    final movedTab = categoryTabs.removeAt(oldIndex);
    categoryTabs.insert(newIndex, movedTab);

    setState(() {
      for (int i = 0; i < categoryTabs.length; i++) {
        final tabId = categoryTabs[i].id;
        final tabIdx = _tabs.indexWhere((t) => t.id == tabId);
        if (tabIdx >= 0) {
          _tabs[tabIdx] = _tabs[tabIdx].copyWith(order: originalOrders[i]);
        }
      }
      _hasChanges = true;
    });
  }

  void _moveTabToCategory(String tabId, String newCategoryId) {
    setState(() {
      final idx = _tabs.indexWhere((t) => t.id == tabId);
      if (idx < 0) return;

      final destTabs = _editableTabs
          .where((t) => _categoryIdFor(t) == newCategoryId)
          .toList();
      final maxOrder = destTabs.isEmpty
          ? 0
          : destTabs.map((t) => t.order).reduce((a, b) => a > b ? a : b);

      _tabs[idx] = _tabs[idx].copyWith(
        categoryId: newCategoryId,
        order: maxOrder + 1,
      );
      _hasChanges = true;
    });
  }

  // ── Icon mapping ──────────────────────────────────────────────────────────

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'article':
        return Icons.article_outlined;
      case 'photo_library':
        return Icons.photo_library_outlined;
      case 'video_library':
        return Icons.video_library_outlined;
      case 'music_note':
        return Icons.music_note_outlined;
      case 'live_tv':
        return Icons.live_tv_outlined;
      case 'volunteer_activism':
        return Icons.volunteer_activism_outlined;
      case 'group':
        return Icons.group_outlined;
      case 'folder':
        return Icons.folder_outlined;
      case 'storefront':
        return Icons.storefront_outlined;
      case 'people':
        return Icons.people_outlined;
      case 'info':
        return Icons.info_outlined;
      case 'bookmark':
        return Icons.bookmark_outlined;
      case 'auto_awesome':
        return Icons.auto_awesome_outlined;
      // Finance
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_outlined;
      case 'savings':
        return Icons.savings_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'request_quote':
        return Icons.request_quote_outlined;
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      // Health
      case 'medical_services':
        return Icons.medical_services_outlined;
      case 'local_pharmacy':
        return Icons.local_pharmacy_outlined;
      case 'health_and_safety':
        return Icons.health_and_safety_outlined;
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'emergency':
        return Icons.emergency_outlined;
      // Family
      case 'spa':
        return Icons.spa_outlined;
      case 'child_care':
        return Icons.child_care_outlined;
      case 'family_restroom':
        return Icons.family_restroom_outlined;
      case 'face':
        return Icons.face_outlined;
      case 'content_cut':
        return Icons.content_cut_outlined;
      case 'elderly':
        return Icons.elderly_outlined;
      case 'pregnant_woman':
        return Icons.pregnant_woman_outlined;
      // Business
      case 'business_center':
        return Icons.business_center_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'qr_code_2':
        return Icons.qr_code_2_rounded;
      case 'repeat':
        return Icons.repeat_rounded;
      case 'verified':
        return Icons.verified_outlined;
      case 'notifications_active':
        return Icons.notifications_active_outlined;
      case 'money_off':
        return Icons.money_off_csred_outlined;
      case 'calculate':
        return Icons.calculate_outlined;
      case 'credit_score':
        return Icons.credit_score_outlined;
      case 'badge':
        return Icons.badge_outlined;
      case 'payments':
        return Icons.payments_outlined;
      case 'local_shipping':
        return Icons.local_shipping_outlined;
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      case 'auto_graph':
        return Icons.auto_graph_outlined;
      // Daily Life
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'home_repair_service':
        return Icons.home_repair_service_outlined;
      case 'home':
        return Icons.home_outlined;
      // My Cars
      case 'directions_car_filled':
        return Icons.directions_car_filled_outlined;
      case 'verified_user':
        return Icons.verified_user_outlined;
      case 'time_to_leave':
        return Icons.time_to_leave_outlined;
      case 'local_gas_station':
        return Icons.local_gas_station_outlined;
      case 'car_repair':
        return Icons.car_repair_outlined;
      case 'car_rental':
        return Icons.car_rental_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'handyman':
        return Icons.handyman_outlined;
      case 'handshake':
        return Icons.handshake_outlined;
      // Planning
      case 'calendar_month':
        return Icons.calendar_month_outlined;
      case 'edit_note':
        return Icons.edit_note_outlined;
      // Government
      case 'assured_workload':
        return Icons.assured_workload_outlined;
      case 'gavel':
        return Icons.gavel_outlined;
      case 'person_pin':
        return Icons.person_pin_outlined;
      case 'location_city':
        return Icons.location_city_outlined;
      case 'domain':
        return Icons.domain_outlined;
      case 'description':
        return Icons.description_outlined;
      case 'business':
        return Icons.business_outlined;
      case 'card_travel':
        return Icons.card_travel_outlined;
      case 'credit_card':
        return Icons.credit_card_outlined;
      case 'landscape':
        return Icons.landscape_outlined;
      case 'security':
        return Icons.security_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'directions_bus':
        return Icons.directions_bus_outlined;
      case 'policy':
        return Icons.policy_outlined;
      case 'gas_meter':
        return Icons.gas_meter_outlined;
      case 'grading':
        return Icons.grading_outlined;
      // Community
      case 'mosque':
        return Icons.mosque_outlined;
      case 'diversity_3':
        return Icons.diversity_3_outlined;
      case 'nightlife':
        return Icons.nightlife_outlined;
      case 'event':
        return Icons.event_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'sports_esports':
        return Icons.sports_esports_outlined;
      case 'newspaper':
        return Icons.newspaper_outlined;
      case 'alarm':
        return Icons.alarm_outlined;
      // Faith — shared
      case 'favorite':
        return Icons.favorite_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      // Faith — Christian
      case 'back_hand':
        return Icons.back_hand_outlined;
      case 'church':
        return Icons.church_outlined;
      case 'record_voice_over':
        return Icons.record_voice_over_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'location_on':
        return Icons.location_on_outlined;
      // Faith — Islamic
      case 'schedule':
        return Icons.schedule_outlined;
      case 'explore':
        return Icons.explore_outlined;
      case 'auto_stories':
        return Icons.auto_stories_outlined;
      case 'dark_mode':
        return Icons.dark_mode_outlined;
      case 'self_improvement':
        return Icons.self_improvement_outlined;
      case 'format_quote':
        return Icons.format_quote_outlined;
      case 'celebration':
        return Icons.celebration_outlined;
      // Education
      case 'calendar_today':
        return Icons.calendar_today_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'forum':
        return Icons.forum_outlined;
      case 'note_alt':
        return Icons.note_alt_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'grade':
        return Icons.grade_outlined;
      case 'local_library':
        return Icons.local_library_outlined;
      case 'campaign':
        return Icons.campaign_outlined;
      case 'work_outline':
        return Icons.work_outline;
      case 'history_edu':
        return Icons.history_edu_outlined;
      case 'psychology':
        return Icons.psychology_outlined;
      // Security
      case 'local_police':
        return Icons.local_police_outlined;
      case 'traffic':
        return Icons.traffic_outlined;
      case 'shield':
        return Icons.shield_outlined;
      // Additional modules
      case 'call':
        return Icons.call_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'attach_money':
        return Icons.attach_money_outlined;
      case 'swap_horiz':
        return Icons.swap_horiz_outlined;
      case 'folder_open':
        return Icons.folder_open_outlined;
      case 'notifications':
        return Icons.notifications_outlined;
      default:
        return Icons.tab_outlined;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        title: Text(
          s?.profileTabsTitle ?? 'Profile tabs',
          style: const TextStyle(
            color: _primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _cardBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: _primaryText),
        actions: [
          // Add Category pill button — top right per playbook
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: FilledButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: Text(s?.addCategory ?? 'Add Category'),
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryText,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: s?.resetSettings ?? 'Reset settings',
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _resetToDefaults,
              tooltip: s?.resetSettings ?? 'Reset settings',
              style: IconButton.styleFrom(
                minimumSize: const Size(_minTouchTarget, _minTouchTarget),
              ),
            ),
          ),
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _saveAll,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s?.save ?? 'Save'),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryText,
                ),
              )
            : RefreshIndicator(
                color: _primaryText,
                onRefresh: _loadAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Instructions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_rounded, color: _secondaryText, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s?.profileTabsInstructions ?? 'Drag to reorder. Toggle switch to show or hide tabs.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _secondaryText,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tab count summary
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            '${s?.tabsEnabled ?? 'Tabs enabled'}: ${_editableTabs.where((t) => t.enabled).length}/${_editableTabs.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: _secondaryText,
                            ),
                          ),
                        ),

                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        // Category sections
                        ..._buildCategorySections(s),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _hasChanges
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: _minTouchTarget),
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveAll,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSaving
                            ? (s?.savingEllipsis ?? 'Saving...')
                            : (s?.saveChanges ?? 'Save changes'),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  /// Build the list of category sections with reorderable tab lists.
  List<Widget> _buildCategorySections(AppStrings? s) {
    final groups = _tabsByCategory();
    final categoryIds = _visibleCategoryIds;

    final widgets = <Widget>[];

    for (int i = 0; i < categoryIds.length; i++) {
      final catId = categoryIds[i];
      final categoryTabs = groups[catId] ?? [];
      final isFirst = i == 0;
      final isSocial = catId == 'social';
      final isUserCategory = _userCategoryIds.contains(catId);

      // Category header with hairline divider (skip for first/social section)
      if (!isFirst && !isSocial) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, thickness: 0.5, color: _dividerColor),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _categoryLabel(catId, s),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _accentGray,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    _buildCategoryMenu(catId, s),
                  ],
                ),
              ],
            ),
          ),
        );
      } else if (isSocial) {
        // Social section shows a subtle header without divider
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _categoryLabel(catId, s),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _accentGray,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _buildCategoryMenu(catId, s),
              ],
            ),
          ),
        );
      }

      // Empty state for user-created categories
      if (categoryTabs.isEmpty && isUserCategory) {
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _dividerColor),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_open_outlined, color: _accentGray.withValues(alpha: 0.6), size: 20),
                const SizedBox(width: 12),
                Text(
                  s?.noData ?? 'No tabs yet — move tabs here',
                  style: TextStyle(
                    fontSize: 13,
                    color: _accentGray.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Reorderable list for this category
      if (categoryTabs.isNotEmpty) {
        widgets.add(
          ReorderableList(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryTabs.length,
            onReorder: (oldIndex, newIndex) => _reorderCategoryTabs(catId, oldIndex, newIndex),
            onReorderStart: (_) => HapticFeedback.selectionClick(), // lift
            onReorderEnd: (_) => HapticFeedback.heavyImpact(),     // drop
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final elevation = Tween<double>(begin: 0, end: 6).animate(animation).value;
                  return Material(
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final tab = categoryTabs[index];
              return _buildTabTile(tab, s);
            },
          ),
        );
      }
    }

    return widgets;
  }

  /// Popup menu for category actions (rename / delete).
  Widget _buildCategoryMenu(String catId, AppStrings? s) {
    final isUserCategory = _userCategoryIds.contains(catId);
    final canDelete = isUserCategory || _isCategoryEmpty(catId);

    return PopupMenuButton<String>(
      tooltip: s?.more ?? 'More',
      icon: Icon(Icons.more_horiz_rounded, color: _accentGray, size: 18),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Icons.edit_rounded, size: 18),
              const SizedBox(width: 8),
              Text(s?.rename ?? 'Rename'),
            ],
          ),
        ),
        if (canDelete)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Text(s?.deleteCategory ?? 'Delete', style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'rename') {
          _showCategoryDialog(existingId: catId);
        } else if (value == 'delete') {
          _deleteCategory(catId);
        }
      },
    );
  }

  Widget _buildTabTile(ProfileTabConfig tab, AppStrings? s) {
    return Container(
      key: ValueKey(tab.id),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: tab.enabled ? _cardBackground : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tab.enabled
              ? _accentGray.withValues(alpha: 0.3)
              : _accentGray.withValues(alpha: 0.2),
        ),
        boxShadow: tab.enabled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        minLeadingWidth: 0,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: _tabIndexInCategory(tab),
              child: Semantics(
                button: true,
                label: s?.dragToReorder ?? 'Drag to reorder',
                child: Container(
                  width: _minTouchTarget,
                  height: _minTouchTarget,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: _secondaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tab.enabled
                    ? _primaryText.withValues(alpha: 0.1)
                    : _accentGray.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconData(tab.icon),
                color: tab.enabled ? _primaryText : _secondaryText,
              ),
            ),
          ],
        ),
        title: Text(
          s?.profileTabLabel(tab.id) ?? tab.label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: tab.enabled ? _primaryText : _secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          tab.enabled ? (s?.tabVisible ?? 'Visible') : (s?.tabHidden ?? 'Hidden'),
          style: const TextStyle(
            fontSize: 12,
            color: _secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: tab.enabled,
              onChanged: (_) => _toggleTab(tab.id),
              activeTrackColor: _primaryText.withValues(alpha: 0.5),
              activeThumbColor: _primaryText,
            ),
            _buildMoveMenu(tab, s),
          ],
        ),
      ),
    );
  }

  /// Compute the index of [tab] within its category for the drag listener.
  int _tabIndexInCategory(ProfileTabConfig tab) {
    final catId = _categoryIdFor(tab);
    final categoryTabs = _editableTabs
        .where((t) => _categoryIdFor(t) == catId)
        .toList()
      ..sort((a, b) {
        final cmp = a.order.compareTo(b.order);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });
    return categoryTabs.indexWhere((t) => t.id == tab.id);
  }

  /// Popup menu to move a tab to another category.
  Widget _buildMoveMenu(ProfileTabConfig tab, AppStrings? s) {
    final currentCatId = _categoryIdFor(tab);
    final destCategories = _allCategoryIds
        .where((id) => id != currentCatId)
        .toList();

    if (destCategories.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: s?.moveToCategory ?? 'Move to category',
      icon: Icon(
        Icons.more_vert_rounded,
        color: _secondaryText,
        size: 20,
      ),
      itemBuilder: (context) {
        return destCategories.map((catId) {
          return PopupMenuItem<String>(
            value: catId,
            child: Text(_categoryLabel(catId, s)),
          );
        }).toList();
      },
      onSelected: (newCatId) => _moveTabToCategory(tab.id, newCatId),
    );
  }
}
