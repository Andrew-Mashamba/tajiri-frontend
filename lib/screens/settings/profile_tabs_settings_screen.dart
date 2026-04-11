import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/profile_tab_config.dart';
import '../../services/local_storage_service.dart';

/// Profile tab configuration screen. Navigation: Home → Profile → Settings → Profile Tabs Settings (STORY-76).
/// Enable/disable and reorder profile tabs; persisted in Hive.
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
  static const double _minTouchTarget = 48.0;

  List<ProfileTabConfig> _tabs = [];
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTabs();
  }

  Future<void> _loadTabs() async {
    final storage = await LocalStorageService.getInstance();
    setState(() {
      _tabs = storage.getProfileTabs();
      _isLoading = false;
    });
  }

  Future<void> _saveTabs() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      await storage.saveProfileTabs(_tabs);
      if (!mounted) return;
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mipangilio imehifadhiwa')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'Imeshindwa kuhifadhi. Jaribu tena.';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejesha Mipangilio'),
        content: const Text('Mipangilio yote ya tabo itarejeshwa kuwa ya awali. Endelea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ndiyo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = await LocalStorageService.getInstance();
      await storage.resetProfileTabs();
      await _loadTabs();
      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mipangilio imerejeshwa')),
        );
      }
    }
  }

  void _toggleTab(int index) {
    final tab = _tabs[index];
    final enabledCount = _tabs.where((t) => t.enabled).length;
    // Require at least one tab enabled so profile always has content
    if (tab.enabled && enabledCount <= 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lazima kuwe na angalau tabo moja iliyowashwa'),
          ),
        );
      }
      return;
    }
    setState(() {
      _tabs[index] = tab.copyWith(enabled: !tab.enabled);
      _hasChanges = true;
    });
  }

  void _reorderTabs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _tabs.removeAt(oldIndex);
      _tabs.insert(newIndex, item);

      // Update order values
      for (int i = 0; i < _tabs.length; i++) {
        _tabs[i] = _tabs[i].copyWith(order: i);
      }
      _hasChanges = true;
    });
  }

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
      // Finance
      case 'account_balance_wallet': return Icons.account_balance_wallet_outlined;
      case 'savings': return Icons.savings_outlined;
      case 'account_balance': return Icons.account_balance_outlined;
      case 'trending_up': return Icons.trending_up_rounded;
      case 'request_quote': return Icons.request_quote_outlined;
      case 'receipt_long': return Icons.receipt_long_outlined;
      // Health
      case 'medical_services': return Icons.medical_services_outlined;
      case 'local_pharmacy': return Icons.local_pharmacy_outlined;
      case 'health_and_safety': return Icons.health_and_safety_outlined;
      case 'fitness_center': return Icons.fitness_center_outlined;
      case 'emergency': return Icons.emergency_outlined;
      // Family
      case 'spa': return Icons.spa_outlined;
      case 'child_care': return Icons.child_care_outlined;
      case 'family_restroom': return Icons.family_restroom_outlined;
      case 'face': return Icons.face_outlined;
      case 'content_cut': return Icons.content_cut_outlined;
      // Business
      case 'business_center': return Icons.business_center_outlined;
      case 'email': return Icons.email_outlined;
      case 'qr_code_2': return Icons.qr_code_2_rounded;
      case 'repeat': return Icons.repeat_rounded;
      case 'verified': return Icons.verified_outlined;
      case 'notifications_active': return Icons.notifications_active_outlined;
      case 'money_off': return Icons.money_off_csred_outlined;
      case 'calculate': return Icons.calculate_outlined;
      case 'credit_score': return Icons.credit_score_outlined;
      case 'badge': return Icons.badge_outlined;
      case 'payments': return Icons.payments_outlined;
      case 'local_shipping': return Icons.local_shipping_outlined;
      case 'shopping_cart': return Icons.shopping_cart_outlined;
      // Daily Life
      case 'restaurant': return Icons.restaurant_outlined;
      case 'directions_car': return Icons.directions_car_outlined;
      case 'home_repair_service': return Icons.home_repair_service_outlined;
      case 'home': return Icons.home_outlined;
      // My Cars
      case 'directions_car_filled': return Icons.directions_car_filled_outlined;
      case 'verified_user': return Icons.verified_user_outlined;
      case 'time_to_leave': return Icons.time_to_leave_outlined;
      case 'local_gas_station': return Icons.local_gas_station_outlined;
      case 'car_repair': return Icons.car_repair_outlined;
      case 'car_rental': return Icons.car_rental_outlined;
      case 'groups': return Icons.groups_outlined;
      case 'handyman': return Icons.handyman_outlined;
      case 'handshake': return Icons.handshake_outlined;
      // Planning
      case 'calendar_month': return Icons.calendar_month_outlined;
      case 'edit_note': return Icons.edit_note_outlined;
      // Government
      case 'assured_workload': return Icons.assured_workload_outlined;
      case 'gavel': return Icons.gavel_outlined;
      case 'person_pin': return Icons.person_pin_outlined;
      case 'location_city': return Icons.location_city_outlined;
      case 'account_balance': return Icons.account_balance_outlined;
      case 'domain': return Icons.domain_outlined;
      case 'description': return Icons.description_outlined;
      case 'business': return Icons.business_outlined;
      case 'card_travel': return Icons.card_travel_outlined;
      case 'credit_card': return Icons.credit_card_outlined;
      case 'landscape': return Icons.landscape_outlined;
      case 'security': return Icons.security_outlined;
      case 'bolt': return Icons.bolt_outlined;
      case 'water_drop': return Icons.water_drop_outlined;
      case 'directions_bus': return Icons.directions_bus_outlined;
      case 'policy': return Icons.policy_outlined;
      case 'gas_meter': return Icons.gas_meter_outlined;
      case 'grading': return Icons.grading_outlined;
      // Community
      case 'mosque': return Icons.mosque_outlined;
      case 'diversity_3': return Icons.diversity_3_outlined;
      case 'nightlife': return Icons.nightlife_outlined;
      case 'event': return Icons.event_outlined;
      case 'flight': return Icons.flight_outlined;
      case 'sports_esports': return Icons.sports_esports_outlined;
      // Faith — shared
      case 'favorite': return Icons.favorite_outlined;
      case 'menu_book': return Icons.menu_book_outlined;
      case 'music_note': return Icons.music_note_outlined;
      // Faith — Christian
      case 'back_hand': return Icons.back_hand_outlined;
      case 'church': return Icons.church_outlined;
      case 'record_voice_over': return Icons.record_voice_over_outlined;
      case 'school': return Icons.school_outlined;
      case 'location_on': return Icons.location_on_outlined;
      // Faith — Islamic
      case 'schedule': return Icons.schedule_outlined;
      case 'explore': return Icons.explore_outlined;
      case 'auto_stories': return Icons.auto_stories_outlined;
      case 'dark_mode': return Icons.dark_mode_outlined;
      case 'self_improvement': return Icons.self_improvement_outlined;
      case 'format_quote': return Icons.format_quote_outlined;
      case 'celebration': return Icons.celebration_outlined;
      // Education
      case 'calendar_today': return Icons.calendar_today_outlined;
      case 'assignment': return Icons.assignment_outlined;
      case 'forum': return Icons.forum_outlined;
      case 'note_alt': return Icons.note_alt_outlined;
      case 'quiz': return Icons.quiz_outlined;
      case 'grade': return Icons.grade_outlined;
      case 'local_library': return Icons.local_library_outlined;
      case 'campaign': return Icons.campaign_outlined;
      case 'work_outline': return Icons.work_outline;
      case 'history_edu': return Icons.history_edu_outlined;
      case 'psychology': return Icons.psychology_outlined;
      // Security
      case 'local_police': return Icons.local_police_outlined;
      case 'traffic': return Icons.traffic_outlined;
      case 'shield': return Icons.shield_outlined;
      default:
        return Icons.tab_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Tabo za Wasifu',
          style: TextStyle(
            color: _primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _cardBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _primaryText),
        actions: [
          Semantics(
            button: true,
            label: 'Rejesha Mipangilio',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetToDefaults,
              tooltip: 'Rejesha Mipangilio',
              style: IconButton.styleFrom(
                minimumSize: const Size(_minTouchTarget, _minTouchTarget),
              ),
            ),
          ),
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _saveTabs,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Hifadhi'),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Instructions (monochrome per DESIGN.md)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: _cardBackground,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: _cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _secondaryText, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Buruta ili kubadilisha mpangilio. Gusa swichi kuwasha au kuzima tabo.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _secondaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab count summary
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          'Tabo zilizowashwa: ${_tabs.where((t) => t.enabled).length}/${_tabs.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: _secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Tabs list
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _tabs.length,
                      onReorder: _reorderTabs,
                      itemBuilder: (context, index) {
                        final tab = _tabs[index];
                        return _buildTabTile(tab, index);
                      },
                    ),
                  ),

                  // Save button at bottom (min 48dp height)
                  if (_hasChanges)
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardBackground,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
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
                              onPressed: _isSaving ? null : _saveTabs,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_isSaving ? 'Inahifadhiwa...' : 'Hifadhi Mabadiliko'),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabTile(ProfileTabConfig tab, int index) {
    return Container(
      key: ValueKey(tab.id),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: tab.enabled ? _cardBackground : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tab.enabled ? _accentGray.withOpacity(0.3) : _accentGray.withOpacity(0.2),
        ),
        boxShadow: tab.enabled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minLeadingWidth: 0,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Semantics(
                button: true,
                label: 'Buruta kubadilisha mpangilio',
                child: Container(
                  width: _minTouchTarget,
                  height: _minTouchTarget,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.drag_handle,
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
                    ? _primaryText.withOpacity(0.1)
                    : _accentGray.withOpacity(0.2),
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
          AppStringsScope.of(context)?.profileTabLabel(tab.id) ?? tab.label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: tab.enabled ? _primaryText : _secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          tab.enabled ? 'Inaonekana' : 'Imefichwa',
          style: const TextStyle(
            fontSize: 12,
            color: _secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Switch(
          value: tab.enabled,
          onChanged: (_) => _toggleTab(index),
          activeTrackColor: _primaryText.withOpacity(0.5),
          activeThumbColor: _primaryText,
        ),
      ),
    );
  }
}
