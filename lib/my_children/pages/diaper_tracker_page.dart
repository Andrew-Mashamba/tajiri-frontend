// lib/my_children/pages/diaper_tracker_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../services/children_notification_helper.dart';
import '../services/my_children_service.dart';
import '../../doctor/doctor_module.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class DiaperTrackerPage extends StatefulWidget {
  final Baby baby;

  const DiaperTrackerPage({super.key, required this.baby});

  @override
  State<DiaperTrackerPage> createState() => _DiaperTrackerPageState();
}

class _DiaperTrackerPageState extends State<DiaperTrackerPage> {
  final MyChildrenService _service = MyChildrenService();
  String? _token;
  int? _currentUserId;

  List<DiaperLog> _history = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Color picker state: shown after tapping Dirty or Both
  bool _showColorPicker = false;
  String? _pendingType; // 'dirty' or 'both', awaiting color selection

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _currentUserId = LocalStorageService.instanceSync?.getUser()?.userId;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getDiaperHistory(
        _token!,
        widget.baby.id,
        date: DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) _history = result.items;
      });
      // Fire-and-forget: check for low wet diaper count after 6PM
      _checkDiaperAlert();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Imeshindikana kupakia' : 'Failed to load')),
      );
    }
  }

  Future<void> _logDiaper(String type, {String? color}) async {
    if (_token == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final result = await _service.logDiaper(
        token: _token!,
        babyId: widget.baby.id,
        type: type,
        color: color,
      );
      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() {
          _history.insert(0, result.data!);
          _isSaving = false;
          _showColorPicker = false;
          _pendingType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sw ? 'Imehifadhiwa' : 'Saved'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? (_sw ? 'Imeshindikana' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Hitilafu imetokea' : 'An error occurred')),
      );
    }
  }

  void _onQuickTap(String type) {
    if (type == 'wet') {
      _logDiaper('wet');
    } else {
      // Dirty or Both — show optional color picker
      setState(() {
        _pendingType = type;
        _showColorPicker = true;
      });
    }
  }

  void _onColorSelected(String? color) {
    if (_pendingType != null) {
      _logDiaper(_pendingType!, color: color);
    }
  }

  /// Fire-and-forget: schedule diaper dehydration alert if wet < 6 after 6PM.
  void _checkDiaperAlert() {
    try {
      final now = DateTime.now();
      if (now.hour < 18) return;
      final wetCount = _history.where((d) => d.type == 'wet' || d.type == 'both').length;
      if (wetCount < 6) {
        ChildrenNotificationHelper.scheduleDiaperAlert(
          widget.baby.id,
          widget.baby.name,
          wetCount,
          isSwahili: _sw,
        ).catchError((_) {});
      }
    } catch (_) {}
  }

  // ─── Summary Helpers ──────────────────────────────────────────

  int _countByType(String type) =>
      _history.where((d) => d.type == type).length;

  bool _showDehydrationAlert() {
    final now = DateTime.now();
    if (now.hour < 18) return false;
    final wetCount = _history.where((d) => d.type == 'wet' || d.type == 'both').length;
    return wetCount < 6;
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _sw ? 'Kufuatilia Nepi' : 'Diaper Tracker',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadHistory,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // One-tap buttons
                    _buildQuickLogButtons(),
                    const SizedBox(height: 12),

                    // Color picker (conditionally shown)
                    if (_showColorPicker) _buildColorPicker(),
                    if (_showColorPicker) const SizedBox(height: 12),

                    // Today's count
                    _buildCountCard(),
                    const SizedBox(height: 12),

                    // Dehydration alert
                    if (_showDehydrationAlert()) _buildAlertCard(),
                    if (_showDehydrationAlert()) const SizedBox(height: 12),

                    // History
                    _buildHistorySection(),

                    // ─── Cross-module links ────────────────────
                    const SizedBox(height: 20),
                    ..._buildCrossModuleLinks(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  bool get _hasBlackOrBloodyStool =>
      _history.any((d) =>
          (d.type == 'dirty' || d.type == 'both') &&
          (d.color == 'black'));

  List<Widget> _buildCrossModuleLinks() {
    final sw = _sw;
    return [
      Text(
        sw ? 'Viunganishi' : 'Related',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _kSecondary,
        ),
      ),
      const SizedBox(height: 8),
      // Alert for black/bloody stool
      if (_hasBlackOrBloodyStool && _currentUserId != null)
        _buildCrossModuleLink(
          icon: Icons.warning_rounded,
          label: sw
              ? 'Wasiliana na daktari kuhusu rangi isiyo ya kawaida ya kinyesi'
              : 'Consult your doctor about unusual stool color',
          iconColor: Colors.red.shade600,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => DoctorModule(userId: _currentUserId!))),
        ),
      _buildCrossModuleLink(
        icon: Icons.shopping_cart_rounded,
        label: sw ? 'Nunua nepi na wipes' : 'Shop diapers and wipes',
        onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
      ),
    ];
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
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogButtons() {
    return Row(
      children: [
        Expanded(
          child: _QuickButton(
            icon: Icons.water_drop_rounded,
            label: _sw ? 'Mkojo' : 'Wet',
            emoji: '\uD83D\uDCA7',
            isSaving: _isSaving,
            onTap: () => _onQuickTap('wet'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickButton(
            icon: Icons.circle_rounded,
            label: _sw ? 'Kinyesi' : 'Dirty',
            emoji: '\uD83D\uDCA9',
            isSaving: _isSaving,
            onTap: () => _onQuickTap('dirty'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickButton(
            icon: Icons.join_full_rounded,
            label: _sw ? 'Zote' : 'Both',
            emoji: '\uD83D\uDCA7\uD83D\uDCA9',
            isSaving: _isSaving,
            onTap: () => _onQuickTap('both'),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    final colors = <_StoolColor>[
      _StoolColor('green', const Color(0xFF4CAF50), _sw ? 'Kijani' : 'Green'),
      _StoolColor('yellow', const Color(0xFFFFC107), _sw ? 'Njano' : 'Yellow'),
      _StoolColor('brown', const Color(0xFF795548), _sw ? 'Kahawia' : 'Brown'),
      _StoolColor('black', const Color(0xFF212121), _sw ? 'Nyeusi' : 'Black'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _sw ? 'Rangi ya kinyesi (hiari)' : 'Stool color (optional)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => _onColorSelected(null),
                  child: Text(
                    _sw ? 'Ruka' : 'Skip',
                    style: const TextStyle(color: _kSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: colors.map((c) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _onColorSelected(c.name),
                      child: Text(
                        c.label,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard() {
    final wet = _countByType('wet');
    final dirty = _countByType('dirty');
    final both = _countByType('both');
    final total = _history.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sw ? 'Hesabu ya Leo' : "Today's Count",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CountItem(label: _sw ? 'Mkojo' : 'Wet', value: '$wet'),
              _CountItem(label: _sw ? 'Kinyesi' : 'Dirty', value: '$dirty'),
              _CountItem(label: _sw ? 'Zote' : 'Both', value: '$both'),
              _CountItem(label: _sw ? 'Jumla' : 'Total', value: '$total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _kPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sw ? 'Tahadhari' : 'Warning',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _sw
                      ? 'Upungufu wa maji unawezekana — nepi za mkojo chini ya 6 leo'
                      : 'Possible dehydration — fewer than 6 wet diapers today',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
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

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _sw ? 'Historia ya Leo' : "Today's History",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (_history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _sw ? 'Hakuna historia bado' : 'No diapers logged yet',
                style: const TextStyle(fontSize: 13, color: _kTertiary),
              ),
            ),
          )
        else
          ..._history.map((d) => GestureDetector(
              onLongPress: () => _confirmDeleteDiaper(d),
              child: _buildDiaperTile(d),
            )),
      ],
    );
  }

  void _confirmDeleteDiaper(DiaperLog diaper) {
    if (diaper.id == null) return;
    final sw = _sw;
    String label;
    switch (diaper.type) {
      case 'wet':
        label = sw ? 'Mkojo' : 'Wet';
      case 'dirty':
        label = sw ? 'Kinyesi' : 'Dirty';
      case 'both':
        label = sw ? 'Zote' : 'Both';
      default:
        label = diaper.type;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa?' : 'Delete?'),
        content: Text(sw ? 'Futa "$label"?' : 'Delete "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteDiaper(_token!, diaper.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Imefutwa' : 'Deleted')),
                  );
                  _loadHistory();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Imeshindikana kufuta' : 'Failed to delete')),
                  );
                }
              }
            },
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaperTile(DiaperLog diaper) {
    final time = diaper.loggedAt;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    IconData icon;
    String typeLabel;
    switch (diaper.type) {
      case 'wet':
        icon = Icons.water_drop_rounded;
        typeLabel = _sw ? 'Mkojo' : 'Wet';
      case 'dirty':
        icon = Icons.circle_rounded;
        typeLabel = _sw ? 'Kinyesi' : 'Dirty';
      case 'both':
        icon = Icons.join_full_rounded;
        typeLabel = _sw ? 'Zote' : 'Both';
      default:
        icon = Icons.child_care_rounded;
        typeLabel = diaper.type;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (diaper.color != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    diaper.color!,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Caregiver attribution
                if (diaper.loggedBy != null &&
                    _currentUserId != null &&
                    diaper.loggedBy != _currentUserId) ...[
                  const SizedBox(height: 2),
                  Text(
                    _sw ? 'na Mlezi' : 'by Caregiver',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(fontSize: 12, color: _kTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────

class _StoolColor {
  final String name;
  final Color color;
  final String label;
  const _StoolColor(this.name, this.color, this.label);
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String emoji;
  final bool isSaving;
  final VoidCallback onTap;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isSaving ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountItem extends StatelessWidget {
  final String label;
  final String value;

  const _CountItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
