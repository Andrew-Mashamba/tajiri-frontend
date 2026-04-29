// lib/my_parents/pages/wellness_checkin_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_parents_models.dart';
import '../services/my_parents_service.dart';
import '../services/parents_notification_helper.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kWarning = Color(0xFFFFA726);
const Color _kDanger = Color(0xFFEF5350);

class WellnessCheckInPage extends StatefulWidget {
  final Parent parent;

  const WellnessCheckInPage({super.key, required this.parent});

  @override
  State<WellnessCheckInPage> createState() => _WellnessCheckInPageState();
}

class _WellnessCheckInPageState extends State<WellnessCheckInPage> {
  final MyParentsService _service = MyParentsService();
  final TextEditingController _notesCtrl = TextEditingController();
  String? _token;
  bool _isLoading = true;
  bool _isSaving = false;

  List<WellnessCheckIn> _history = [];

  // Today's check-in state
  String? _selectedMood;
  bool _ateMeals = false;
  bool _tookMedication = false;
  bool _exercised = false;
  bool _socialized = false;
  bool _todayAlreadyCheckedIn = false;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadHistory();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getWellnessHistory(_token!, widget.parent.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _history = result.items
            ..sort((a, b) => b.date.compareTo(a.date));

          // Check if today already has a check-in
          final now = DateTime.now();
          final todayCheckIn = _history.where((c) =>
              c.date.year == now.year &&
              c.date.month == now.month &&
              c.date.day == now.day).toList();
          if (todayCheckIn.isNotEmpty) {
            _todayAlreadyCheckedIn = true;
            final today = todayCheckIn.first;
            _selectedMood = today.mood;
            _ateMeals = today.ateMeals;
            _tookMedication = today.tookMedication;
            _exercised = today.exercised;
            _socialized = today.socialized;
            _notesCtrl.text = today.notes ?? '';
          }

          // Schedule daily wellness check-in prompt
          _scheduleWellnessNotifications();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Imeshindikana kupakia historia'
            : 'Failed to load history')),
      );
    }
  }

  /// Fire-and-forget: schedule daily wellness prompt and missed check-in alert.
  void _scheduleWellnessNotifications() {
    final sw = _sw;
    final parentId = widget.parent.id;
    final parentName = widget.parent.name;

    try {
      // Ensure daily 9am check-in prompt is scheduled
      ParentsNotificationHelper.scheduleWellnessCheckInPrompt(
        parentId, parentName, sw,
      );
    } catch (_) {}

    try {
      // Alert if 2+ days missed
      if (_missedDays >= 2) {
        ParentsNotificationHelper.scheduleMissedCheckInAlert(
          parentId, parentName, _missedDays, sw,
        );
      }
    } catch (_) {}
  }

  int get _streakDays {
    if (_history.isEmpty) return 0;
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final hasCheckIn = _history.any((c) =>
          c.date.year == day.year &&
          c.date.month == day.month &&
          c.date.day == day.day);
      if (hasCheckIn) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get _missedDays {
    if (_history.isEmpty) return 0;
    final now = DateTime.now();
    int missed = 0;
    for (int i = 1; i <= 2; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final hasCheckIn = _history.any((c) =>
          c.date.year == day.year &&
          c.date.month == day.month &&
          c.date.day == day.day);
      if (!hasCheckIn) missed++;
    }
    return missed;
  }

  int get _unwell3Days {
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < 3; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final checkIn = _history.where((c) =>
          c.date.year == day.year &&
          c.date.month == day.month &&
          c.date.day == day.day).toList();
      if (checkIn.isNotEmpty && checkIn.first.mood == 'unwell') {
        count++;
      }
    }
    return count;
  }

  Future<void> _saveCheckIn() async {
    if (_token == null || _selectedMood == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    setState(() => _isSaving = true);

    try {
      final result = await _service.saveWellnessCheckIn(
        token: _token!,
        parentId: widget.parent.id,
        mood: _selectedMood!,
        ateMeals: _ateMeals,
        tookMedication: _tookMedication,
        exercised: _exercised,
        socialized: _socialized,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw
              ? 'Hali imehifadhiwa!'
              : 'Check-in saved!')),
        );
        _loadHistory();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  String _moodEmoji(String? mood) {
    switch (mood) {
      case 'happy':
        return '\u{1F60A}';
      case 'okay':
        return '\u{1F610}';
      case 'sad':
        return '\u{1F61E}';
      case 'unwell':
        return '\u{1F912}';
      default:
        return '\u{2753}';
    }
  }

  String _moodLabel(String mood, bool sw) {
    switch (mood) {
      case 'happy':
        return sw ? 'Furaha' : 'Happy';
      case 'okay':
        return sw ? 'Sawa' : 'Okay';
      case 'sad':
        return sw ? 'Huzuni' : 'Sad';
      case 'unwell':
        return sw ? 'Mgonjwa' : 'Unwell';
      default:
        return mood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Hali ya Kila Siku' : 'Daily Wellness',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Alerts
                  if (_missedDays >= 2)
                    _buildAlert(
                      sw ? 'Siku $_missedDays zilizopita hazijarekodiwa!'
                          : '$_missedDays days missed!',
                      _kWarning,
                    ),
                  if (_unwell3Days >= 3)
                    _buildAlert(
                      sw ? '${widget.parent.name} amekuwa mgonjwa siku 3+. Tafadhali ona daktari.'
                          : '${widget.parent.name} has been unwell 3+ days. Consider seeing a doctor.',
                      _kDanger,
                    ),

                  // Streak
                  if (_streakDays > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text('\u{1F525}', style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_streakDays ${sw ? 'siku mfululizo' : 'day streak'}',
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                                ),
                                Text(
                                  sw ? 'Hongera! Endelea kurekodi.' : 'Great! Keep checking in.',
                                  style: const TextStyle(fontSize: 11, color: _kSecondary),
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
                  ],

                  // Today's check-in card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw
                              ? '${widget.parent.name} uko vipi leo?'
                              : 'How is ${widget.parent.name} today?',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                        ),
                        const SizedBox(height: 16),

                        // Mood selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['happy', 'okay', 'sad', 'unwell'].map((mood) {
                            final selected = _selectedMood == mood;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedMood = mood),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _kPrimary.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: selected
                                      ? Border.all(color: _kPrimary, width: 1.5)
                                      : Border.all(color: Colors.transparent),
                                ),
                                child: Column(
                                  children: [
                                    Text(_moodEmoji(mood),
                                        style: const TextStyle(fontSize: 28)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _moodLabel(mood, sw),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selected ? _kPrimary : _kSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Quick toggles
                        _buildToggle(
                          icon: Icons.restaurant_rounded,
                          label: sw ? 'Amekula chakula?' : 'Ate meals?',
                          value: _ateMeals,
                          onChanged: (v) => setState(() => _ateMeals = v),
                        ),
                        _buildToggle(
                          icon: Icons.medication_rounded,
                          label: sw ? 'Amemeza dawa?' : 'Took medication?',
                          value: _tookMedication,
                          onChanged: (v) => setState(() => _tookMedication = v),
                        ),
                        _buildToggle(
                          icon: Icons.directions_walk_rounded,
                          label: sw ? 'Amefanya mazoezi?' : 'Exercised?',
                          value: _exercised,
                          onChanged: (v) => setState(() => _exercised = v),
                        ),
                        _buildToggle(
                          icon: Icons.people_rounded,
                          label: sw ? 'Amechanganyika na watu?' : 'Socialized?',
                          value: _socialized,
                          onChanged: (v) => setState(() => _socialized = v),
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: sw ? 'Maelezo ya ziada...' : 'Additional notes...',
                            hintStyle: TextStyle(
                                color: _kSecondary.withValues(alpha: 0.5)),
                            filled: true,
                            fillColor: _kPrimary.withValues(alpha: 0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                          style: const TextStyle(fontSize: 13, color: _kPrimary),
                        ),
                        const SizedBox(height: 16),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: (_selectedMood == null || _isSaving)
                                ? null
                                : _saveCheckIn,
                            style: FilledButton.styleFrom(
                              backgroundColor: _kPrimary,
                              disabledBackgroundColor: _kPrimary.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(
                                    _todayAlreadyCheckedIn
                                        ? (sw ? 'Sasisha' : 'Update')
                                        : (sw ? 'Hifadhi' : 'Save'),
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cross-module link if unwell
                  if (_unwell3Days >= 3)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            try { Navigator.pushNamed(context, '/doctor'); } catch (_) {}
                          },
                          icon: const Icon(Icons.medical_services_rounded, size: 16),
                          label: Text(
                            sw ? 'Panga Miadi na Daktari' : 'Book Doctor Appointment',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kDanger,
                            side: BorderSide(color: _kDanger.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),

                  // History calendar (last 30 days)
                  Text(
                    sw ? 'Historia (Siku 30)' : 'History (30 Days)',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryCalendar(sw),
                  const SizedBox(height: 20),

                  // Cross-module link
                  _buildCrossModuleLink(
                    icon: Icons.smart_toy_rounded,
                    label: sw
                        ? 'Uliza Shangazi kuhusu kutunza mzazi mzee'
                        : 'Ask Shangazi about caring for elderly parent',
                    onTap: () {
                      try { Navigator.pushNamed(context, '/chat/0'); } catch (_) {}
                    },
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
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 13, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _kSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 48, height: 28,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: _kPrimary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlert(String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCalendar(bool sw) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(30, (i) {
          final day = DateTime(now.year, now.month, now.day - (29 - i));
          final checkIn = _history.where((c) =>
              c.date.year == day.year &&
              c.date.month == day.month &&
              c.date.day == day.day).toList();

          final hasCheckIn = checkIn.isNotEmpty;
          final mood = hasCheckIn ? checkIn.first.mood : null;

          return Tooltip(
            message: '${day.day}/${day.month} - ${hasCheckIn ? _moodLabel(mood ?? '', sw) : (sw ? 'Hakuna' : 'None')}',
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hasCheckIn
                    ? _moodColor(mood).withValues(alpha: 0.15)
                    : _kPrimary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: hasCheckIn
                  ? Text(_moodEmoji(mood), style: const TextStyle(fontSize: 14))
                  : Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  Color _moodColor(String? mood) {
    switch (mood) {
      case 'happy':
        return _kSuccess;
      case 'okay':
        return const Color(0xFF42A5F5);
      case 'sad':
        return _kWarning;
      case 'unwell':
        return _kDanger;
      default:
        return _kSecondary;
    }
  }
}
