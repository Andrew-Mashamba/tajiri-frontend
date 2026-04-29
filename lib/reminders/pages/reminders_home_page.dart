// lib/reminders/pages/reminders_home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/reminder_models.dart';
import '../services/reminder_detail_prefs.dart';
import '../services/reminders_dismissed_store.dart';
import '../services/reminders_snooze_override_store.dart';
import '../services/reminders_aggregator.dart';
import '../services/reminders_notification_service.dart';
import '../services/reminders_service.dart';
import '../widgets/reminder_card.dart';
import 'add_reminder_page.dart';
import 'reminder_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class RemindersHomePage extends StatefulWidget {
  final int userId;

  /// When `true`, no [AppBar] — parent (e.g. profile tab) already shows title + back.
  final bool embedInProfileTab;

  const RemindersHomePage({
    super.key,
    required this.userId,
    this.embedInProfileTab = false,
  });

  @override
  State<RemindersHomePage> createState() => _RemindersHomePageState();
}

class _RemindersHomePageState extends State<RemindersHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _token;
  bool _loading = true;
  String? _error;
  List<ReminderItem> _all = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final s = await LocalStorageService.getInstance();
    _token = s.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = _token;
    final strings = AppStringsScope.of(context);
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            strings?.remindersSignInRequired ?? 'Sign in to view reminders';
      });
      return;
    }
    try {
      final items = await RemindersAggregator.getAllStrictWithRetries(
        token: token,
        userId: widget.userId,
      );
      final dismissed = await RemindersDismissedStore.getAll();
      final validIds = items.map((e) => e.id).toSet();
      final prunedDismissed = dismissed.where(validIds.contains).toSet();
      if (prunedDismissed.length != dismissed.length) {
        await RemindersDismissedStore.replaceAll(prunedDismissed);
      }
      final overrides = await RemindersSnoozeOverrideStore.getAll();
      final prunedOverrides = Map<String, DateTime>.fromEntries(
        overrides.entries.where((e) => validIds.contains(e.key)),
      );
      if (prunedOverrides.length != overrides.length) {
        await RemindersSnoozeOverrideStore.replaceAll(prunedOverrides);
      }
      final merged = items.map((i) {
        ReminderItem x = i;
        if (!i.isStandalone && prunedDismissed.contains(i.id)) {
          x = x.copyWith(isDone: true);
        }
        final o = prunedOverrides[i.id];
        if (o != null) {
          x = x.copyWith(dueAt: o);
        }
        return x;
      }).toList();
      if (!mounted) return;
      setState(() {
        _all = merged;
        _loading = false;
      });
      await RemindersNotificationService.scheduleAll(items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = strings?.remindersLoadFailed ?? 'Failed to load reminders';
        _loading = false;
      });
    }
  }

  List<ReminderItem> get _today {
    final today = DateTime.now();
    final list = _all
        .where((i) =>
            !i.isDone &&
            i.dueAt.year == today.year &&
            i.dueAt.month == today.month &&
            i.dueAt.day == today.day)
        .toList();
    list.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return list;
  }

  List<ReminderItem> get _upcoming {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    return _all.where((i) {
      if (i.isDone) return false;
      final day = DateTime(i.dueAt.year, i.dueAt.month, i.dueAt.day);
      return day.isAtSameMomentAs(tomorrowStart) || day.isAfter(tomorrowStart);
    }).toList();
  }

  List<ReminderItem> get _done => _all.where((i) => i.isDone).toList();

  Future<void> _markDone(ReminderItem item) async {
    if (_token == null) return;
    await RemindersSnoozeOverrideStore.remove(item.id);
    if (item.isStandalone) {
      await RemindersService.markDone(item.id, token: _token!);
    } else {
      await RemindersDismissedStore.add(item.id);
    }
    if (!mounted) return;
    setState(() {
      _all = _all
          .map((i) => i.id == item.id ? i.copyWith(isDone: true) : i)
          .toList();
    });
    await RemindersNotificationService.scheduleAll(
      _all.where((i) => !i.isDone).toList(),
    );
  }

  Future<void> _undoDone(ReminderItem item) async {
    if (_token == null) return;
    final updated = item.copyWith(isDone: false);
    if (item.isStandalone) {
      await RemindersService.update(updated, token: _token!);
    } else {
      await RemindersDismissedStore.remove(item.id);
    }
    if (!mounted) return;
    setState(() {
      _all = _all.map((i) => i.id == item.id ? updated : i).toList();
    });
    await RemindersNotificationService.scheduleAll(
      _all.where((i) => !i.isDone).toList(),
    );
  }

  Future<void> _snooze(ReminderItem item, Duration by) async {
    if (_token == null) return;
    final snoozed = item.copyWith(dueAt: DateTime.now().add(by));
    if (item.isStandalone) {
      await RemindersService.update(snoozed, token: _token!);
    } else {
      await RemindersSnoozeOverrideStore.put(item.id, snoozed.dueAt);
    }
    if (!mounted) return;
    setState(() {
      _all = _all.map((i) => i.id == item.id ? snoozed : i).toList();
    });
    await RemindersNotificationService.scheduleAll(
      _all.where((i) => !i.isDone).toList(),
    );
  }

  Future<void> _delete(ReminderItem item) async {
    if (_token == null) return;
    final s = AppStringsScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.remindersDeleteTitle ?? 'Delete reminder?'),
        content: Text(s?.remindersDeleteMessage ?? 'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await RemindersService.delete(item.id, token: _token!);
    if (!mounted) return;
    await ReminderDetailPrefsStore.remove(item.id);
    await RemindersDismissedStore.remove(item.id);
    await RemindersSnoozeOverrideStore.remove(item.id);
    await RemindersNotificationService.cancel(item.id);
    if (!mounted) return;
    setState(() => _all.removeWhere((i) => i.id == item.id));
  }

  void _openItem(ReminderItem item) {
    if (_token == null) {
      final str = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            str?.remindersSignInRequired ?? 'Sign in to view reminders',
          ),
        ),
      );
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ReminderDetailPage(
          userId: widget.userId,
          item: item,
          token: _token,
          onSnooze: (i, d) => _snooze(i, d),
        ),
      ),
    ).then((_) => _load());
  }

  TabBar _buildTabBar(AppStrings? s) {
    return TabBar(
      controller: _tabs,
      labelColor: _kPrimary,
      unselectedLabelColor: _kSecondary,
      indicatorColor: _kPrimary,
      indicatorWeight: 2,
      isScrollable: widget.embedInProfileTab,
      tabAlignment:
          widget.embedInProfileTab ? TabAlignment.start : TabAlignment.fill,
      tabs: [
        Tab(
            text: s?.remindersTabToday(_today.length) ??
                'Today (${_today.length})'),
        Tab(
            text: s?.remindersTabUpcoming(_upcoming.length) ??
                'Upcoming (${_upcoming.length})'),
        Tab(
            text: s?.remindersTabDone(_done.length) ??
                'Completed (${_done.length})'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final tabBar = _buildTabBar(s);

    final bodyContent = _loading
        ? const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary),
          )
        : _error != null
            ? _buildError(s)
            : TabBarView(
                controller: _tabs,
                children: [
                  _buildList(
                    _today,
                    s,
                    emptyTitle: s?.remindersEmpty ?? 'No reminders',
                  ),
                  _buildGroupedList(context, _upcoming, s),
                  _buildList(
                    _done,
                    s,
                    emptyTitle: s?.remindersEmptyCompleted ??
                        'No completed reminders yet',
                  ),
                ],
              );

    return Scaffold(
      backgroundColor: _kBg,
      appBar: widget.embedInProfileTab
          ? null
          : AppBar(
              backgroundColor: _kBg,
              elevation: 0,
              scrolledUnderElevation: 1,
              title: Text(
                s?.remindersTitle ?? 'Reminders',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              actions: [
                Tooltip(
                  message: s?.remindersRefresh ?? 'Refresh',
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: _kPrimary),
                    onPressed: _load,
                  ),
                ),
              ],
              bottom: tabBar,
            ),
      floatingActionButton: _token != null
          ? FloatingActionButton(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              tooltip: s?.remindersFabAdd ?? 'Add reminder',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AddReminderPage(userId: widget.userId),
                ),
              ).then((_) => _load()),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: widget.embedInProfileTab
          ? Column(
              children: [
                Material(
                  color: _kBg,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: tabBar),
                      Tooltip(
                        message: s?.remindersRefresh ?? 'Refresh',
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: _kPrimary),
                          onPressed: _load,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: bodyContent,
                  ),
                ),
              ],
            )
          : SafeArea(child: bodyContent),
    );
  }

  Widget _buildError(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: _kSecondary),
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: Text(s?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings? s, {required String title}) {
    final hint = s?.remindersEmptyHint ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<ReminderItem> items,
    AppStrings? s, {
    required String emptyTitle,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        color: _kPrimary,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: _buildEmptyState(s, title: emptyTitle),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    List<ReminderItem> items,
    AppStrings? s,
  ) {
    if (items.isEmpty) {
      return RefreshIndicator(
        color: _kPrimary,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: _buildEmptyState(
              s,
              title: s?.remindersEmptyUpcoming ?? 'No upcoming reminders',
            ),
          ),
        ),
      );
    }
    final locale = Localizations.localeOf(context).toString();
    final Map<String, List<ReminderItem>> grouped = {};
    for (final item in items) {
      final key = DateFormat('EEEE, d MMMM yyyy', locale).format(item.dueAt);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    }
    final sections = grouped.entries.toList();
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sections.length,
        itemBuilder: (_, i) {
          final section = sections[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  section.key,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kSecondary,
                  ),
                ),
              ),
              ...section.value.map(_buildCard),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(ReminderItem item) {
    return ReminderCard(
      item: item,
      onTap: () => _openItem(item),
      onDone: () => _markDone(item),
      onUndoDone: () => _undoDone(item),
      onSnooze: (d) => _snooze(item, d),
      onDelete: item.isStandalone ? () => _delete(item) : null,
    );
  }
}
