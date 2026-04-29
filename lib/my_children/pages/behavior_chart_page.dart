// lib/my_children/pages/behavior_chart_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_children_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kGold = Color(0xFFB8860B);

class BehaviorChartPage extends StatefulWidget {
  final Child child;
  final int userId;

  const BehaviorChartPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<BehaviorChartPage> createState() => _BehaviorChartPageState();
}

class _BehaviorChartPageState extends State<BehaviorChartPage> {
  bool _isLoading = true;
  Map<String, int> _stickerCounts = {};
  List<_StickerEntry> _history = [];
  int _rewardThreshold = 10;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  String get _prefsKey => 'behavior_${widget.child.id}';

  static const _categories = [
    _BehaviorCategory(
      key: 'sharing',
      en: 'Sharing',
      sw: 'Kushiriki',
      icon: Icons.handshake_rounded,
    ),
    _BehaviorCategory(
      key: 'listening',
      en: 'Listening',
      sw: 'Kusikiliza',
      icon: Icons.hearing_rounded,
    ),
    _BehaviorCategory(
      key: 'helping',
      en: 'Helping',
      sw: 'Kusaidia',
      icon: Icons.volunteer_activism_rounded,
    ),
    _BehaviorCategory(
      key: 'kindness',
      en: 'Kindness',
      sw: 'Huruma',
      icon: Icons.favorite_rounded,
    ),
    _BehaviorCategory(
      key: 'patience',
      en: 'Patience',
      sw: 'Subira',
      icon: Icons.hourglass_bottom_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _prefsKey;

      // Load sticker counts
      final counts = <String, int>{};
      for (final cat in _categories) {
        counts[cat.key] = prefs.getInt('${key}_${cat.key}') ?? 0;
      }

      // Load history
      final historyStr = prefs.getStringList('${key}_history') ?? [];
      final history = <_StickerEntry>[];
      for (final s in historyStr) {
        final parts = s.split('|');
        if (parts.length >= 2) {
          history.add(_StickerEntry(
            category: parts[0],
            date: DateTime.tryParse(parts[1]) ?? DateTime.now(),
          ));
        }
      }

      // Load reward threshold
      final threshold = prefs.getInt('${key}_reward_threshold') ?? 10;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _stickerCounts = counts;
          _history = history;
          _rewardThreshold = threshold;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _awardSticker(String categoryKey) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _prefsKey;
      final current = prefs.getInt('${key}_$categoryKey') ?? 0;
      await prefs.setInt('${key}_$categoryKey', current + 1);

      // Add to history
      final historyStr = prefs.getStringList('${key}_history') ?? [];
      historyStr.insert(0, '$categoryKey|${DateTime.now().toIso8601String()}');
      // Keep only last 200 entries
      if (historyStr.length > 200) {
        historyStr.removeRange(200, historyStr.length);
      }
      await prefs.setStringList('${key}_history', historyStr);

      final newTotal = _totalStickers + 1;
      if (mounted) {
        if (newTotal > 0 && newTotal % _rewardThreshold == 0) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(_sw
                  ? 'Hongera! Stika $_rewardThreshold! Chagua tuzo!'
                  : 'Congratulations! $_rewardThreshold stickers! Choose a reward!'),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(_sw ? 'Stika imeongezwa!' : 'Sticker awarded!'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
        _loadFromPrefs();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(_sw ? 'Hitilafu imetokea' : 'An error occurred'),
          ),
        );
      }
    }
  }

  int get _totalStickers =>
      _stickerCounts.values.fold(0, (sum, v) => sum + v);

  int get _weeklyStickers {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _history.where((h) => h.date.isAfter(weekAgo)).length;
  }

  int get _stickersToReward {
    final remaining = _rewardThreshold - (_totalStickers % _rewardThreshold);
    return remaining == _rewardThreshold ? 0 : remaining;
  }

  void _showRewardSettingsDialog() {
    final controller =
        TextEditingController(text: '$_rewardThreshold');
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sw ? 'Mipangilio ya Tuzo' : 'Reward Settings',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: sw
                      ? 'Stika kwa tuzo'
                      : 'Stickers per reward',
                  labelStyle:
                      const TextStyle(fontSize: 13, color: _kSecondary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    final val = int.tryParse(controller.text.trim());
                    if (val == null || val < 1) return;
                    Navigator.pop(ctx);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt(
                        '${_prefsKey}_reward_threshold', val);
                    if (mounted) {
                      setState(() => _rewardThreshold = val);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    sw ? 'Hifadhi' : 'Save',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Chati ya Tabia' : 'Behavior Chart',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showRewardSettingsDialog,
            icon: const Icon(Icons.settings_rounded, size: 22),
            tooltip: sw ? 'Mipangilio' : 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
            : ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                children: [
                  // ─── Summary ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 28, color: _kGold),
                              const SizedBox(height: 4),
                              Text(
                                '$_totalStickers',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                ),
                              ),
                              Text(
                                sw ? 'Jumla' : 'Total',
                                style: const TextStyle(
                                    fontSize: 12, color: _kSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: _kPrimary.withValues(alpha: 0.1),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 28, color: _kPrimary),
                              const SizedBox(height: 4),
                              Text(
                                '$_weeklyStickers',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                ),
                              ),
                              Text(
                                sw ? 'Wiki Hii' : 'This Week',
                                style: const TextStyle(
                                    fontSize: 12, color: _kSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: _kPrimary.withValues(alpha: 0.1),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.emoji_events_rounded,
                                  size: 28, color: _kGold),
                              const SizedBox(height: 4),
                              Text(
                                _stickersToReward == 0
                                    ? '🎉'
                                    : '$_stickersToReward',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                ),
                              ),
                              Text(
                                sw ? 'Hadi Tuzo' : 'To Reward',
                                style: const TextStyle(
                                    fontSize: 12, color: _kSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Award Sticker ──────────────────────
                  _buildSectionTitle(
                      sw ? 'Toa Stika' : 'Award Sticker'),
                  const SizedBox(height: 8),
                  Text(
                    sw
                        ? 'Bonyeza tabia ili kutoa stika'
                        : 'Tap a behavior to award a sticker',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  ..._categories.map((cat) => _buildCategoryTile(cat, sw)),
                  const SizedBox(height: 16),

                  // ─── History ────────────────────────────
                  _buildSectionTitle(sw ? 'Historia' : 'History'),
                  const SizedBox(height: 8),
                  if (_history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        sw
                            ? 'Hakuna stika bado'
                            : 'No stickers yet',
                        style: const TextStyle(
                            fontSize: 13, color: _kSecondary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._history.take(30).map((h) =>
                        _buildHistoryItem(h, sw)),
                  // ─── Cross-module links ──────────────
                  const SizedBox(height: 20),
                  Text(
                    sw ? 'Viunganishi' : 'Related',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCrossModuleLink(
                    icon: Icons.chat_rounded,
                    label: sw
                        ? 'Uliza Shangazi kuhusu mbinu za nidhamu chanya'
                        : 'Ask Shangazi about positive discipline tips',
                    onTap: () => Navigator.pushNamed(context, '/chat/0'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  Widget _buildCategoryTile(_BehaviorCategory cat, bool sw) {
    final count = _stickerCounts[cat.key] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _awardSticker(cat.key),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cat.icon, size: 20, color: _kGold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sw ? cat.sw : cat.en,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sw ? '$count stika' : '$count stickers',
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: _kGold),
                      const SizedBox(width: 4),
                      Text(
                        sw ? 'Toa' : 'Award',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(_StickerEntry entry, bool sw) {
    final cat = _categories.firstWhere(
      (c) => c.key == entry.category,
      orElse: () => _categories.first,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.star_rounded, size: 16, color: _kGold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                sw ? cat.sw : cat.en,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${entry.date.day}/${entry.date.month} ${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _kPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _BehaviorCategory {
  final String key;
  final String en;
  final String sw;
  final IconData icon;
  const _BehaviorCategory({
    required this.key,
    required this.en,
    required this.sw,
    required this.icon,
  });
}

class _StickerEntry {
  final String category;
  final DateTime date;
  const _StickerEntry({required this.category, required this.date});
}
