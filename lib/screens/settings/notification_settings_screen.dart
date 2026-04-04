import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/local_storage_service.dart';

/// Notification Settings screen.
/// Navigation: Settings → Arifa (Notifications).
class NotificationSettingsScreen extends StatefulWidget {
  final int currentUserId;

  const NotificationSettingsScreen({super.key, required this.currentUserId});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _cardBackground = Color(0xFFFFFFFF);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _iconBackground = Color(0xFF1A1A1A);

  bool _isLoading = true;
  String? _error;

  // Message notifications
  bool _messagesEnabled = true;
  bool _groupsEnabled = true;
  bool _reactionsEnabled = true;
  bool _mentionsEnabled = true;

  // Calls
  bool _callsEnabled = true;

  // Social
  bool _socialEnabled = true;

  // System
  bool _systemEnabled = true;

  // Sound & Vibration
  bool _globalVibrate = true;

  // Quiet Hours
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Hujaingia. Tafadhali ingia tena.';
          });
        }
        return;
      }

      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notification-preferences'),
        headers: ApiConfig.authHeaders(token),
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final prefs = data['preferences'] as Map<String, dynamic>? ?? data;
        setState(() {
          _messagesEnabled = prefs['messages_enabled'] ?? true;
          _groupsEnabled = prefs['groups_enabled'] ?? true;
          _reactionsEnabled = prefs['reactions_enabled'] ?? true;
          _mentionsEnabled = prefs['mentions_enabled'] ?? true;
          _callsEnabled = prefs['calls_enabled'] ?? true;
          _socialEnabled = prefs['social_enabled'] ?? true;
          _systemEnabled = prefs['system_enabled'] ?? true;
          _globalVibrate = prefs['global_vibrate'] ?? true;
          _quietHoursEnabled = prefs['quiet_hours_enabled'] ?? false;
          _quietHoursStart =
              _parseTime(prefs['quiet_hours_start'] as String?) ??
                  const TimeOfDay(hour: 22, minute: 0);
          _quietHoursEnd =
              _parseTime(prefs['quiet_hours_end'] as String?) ??
                  const TimeOfDay(hour: 7, minute: 0);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Imeshindwa kupakia mipangilio (${resp.statusCode})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Imeshindwa kupakia mipangilio';
        });
      }
    }
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;

      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notification-preferences'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({key: value}),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imeshindwa kuhifadhi mipangilio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _quietHoursStart : _quietHoursEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _quietHoursStart = picked;
      } else {
        _quietHoursEnd = picked;
      }
    });

    final key = isStart ? 'quiet_hours_start' : 'quiet_hours_end';
    _updatePreference(key, _formatTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Arifa'),
        backgroundColor: _cardBackground,
        foregroundColor: _primaryText,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWithRetry()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Messages section
                        _buildSectionHeader('Arifa za Ujumbe'),
                        _buildSwitchTile(
                          icon: Icons.message_outlined,
                          title: 'Ujumbe',
                          subtitle: 'Arifa za ujumbe mpya',
                          value: _messagesEnabled,
                          onChanged: (v) {
                            setState(() => _messagesEnabled = v);
                            _updatePreference('messages_enabled', v);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.group_outlined,
                          title: 'Vikundi',
                          subtitle: 'Arifa za vikundi',
                          value: _groupsEnabled,
                          onChanged: (v) {
                            setState(() => _groupsEnabled = v);
                            _updatePreference('groups_enabled', v);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.emoji_emotions_outlined,
                          title: 'Majibu',
                          subtitle: 'Arifa za majibu kwenye ujumbe',
                          value: _reactionsEnabled,
                          onChanged: (v) {
                            setState(() => _reactionsEnabled = v);
                            _updatePreference('reactions_enabled', v);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.alternate_email,
                          title: 'Kutajwa',
                          subtitle: 'Arifa unapotajwa',
                          value: _mentionsEnabled,
                          onChanged: (v) {
                            setState(() => _mentionsEnabled = v);
                            _updatePreference('mentions_enabled', v);
                          },
                        ),

                        // Calls section
                        _buildSectionHeader('Simu'),
                        _buildSwitchTile(
                          icon: Icons.call_outlined,
                          title: 'Simu',
                          subtitle: 'Arifa za simu zinazoingia',
                          value: _callsEnabled,
                          onChanged: (v) {
                            setState(() => _callsEnabled = v);
                            _updatePreference('calls_enabled', v);
                          },
                        ),

                        // Social section
                        _buildSectionHeader('Mitandao'),
                        _buildSwitchTile(
                          icon: Icons.people_outlined,
                          title: 'Wafuasi na Maoni',
                          subtitle: 'Arifa za wafuasi wapya na maoni',
                          value: _socialEnabled,
                          onChanged: (v) {
                            setState(() => _socialEnabled = v);
                            _updatePreference('social_enabled', v);
                          },
                        ),

                        // System section
                        _buildSectionHeader('Mfumo'),
                        _buildSwitchTile(
                          icon: Icons.settings_outlined,
                          title: 'Arifa za mfumo',
                          subtitle: 'Masasisho ya programu na mfumo',
                          value: _systemEnabled,
                          onChanged: (v) {
                            setState(() => _systemEnabled = v);
                            _updatePreference('system_enabled', v);
                          },
                        ),

                        // Sound & Vibration section
                        _buildSectionHeader('Sauti na Mtetemo'),
                        _buildSwitchTile(
                          icon: Icons.vibration,
                          title: 'Mtetemo',
                          subtitle: 'Washa mtetemo kwa arifa',
                          value: _globalVibrate,
                          onChanged: (v) {
                            setState(() => _globalVibrate = v);
                            _updatePreference('global_vibrate', v);
                          },
                        ),

                        // Quiet Hours section
                        _buildSectionHeader('Masaa ya Utulivu'),
                        _buildSwitchTile(
                          icon: Icons.bedtime_outlined,
                          title: 'Washa masaa ya utulivu',
                          subtitle:
                              'Hutapokea arifa wakati wa masaa ya utulivu, isipokuwa simu',
                          value: _quietHoursEnabled,
                          onChanged: (v) {
                            setState(() => _quietHoursEnabled = v);
                            _updatePreference('quiet_hours_enabled', v);
                          },
                        ),
                        if (_quietHoursEnabled) ...[
                          _buildTimeTile(
                            icon: Icons.schedule,
                            title: 'Kuanzia',
                            time: _quietHoursStart,
                            onTap: () => _pickTime(isStart: true),
                          ),
                          _buildTimeTile(
                            icon: Icons.schedule,
                            title: 'Hadi',
                            time: _quietHoursEnd,
                            onTap: () => _pickTime(isStart: false),
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorWithRetry() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Imeshindwa kupakia mipangilio',
              style: const TextStyle(color: _secondaryText, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loadPreferences,
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _primaryText,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: _primaryText.withValues(alpha: 0.5),
                  activeThumbColor: _primaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required IconData icon,
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final displayTime = time.format(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    displayTime,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _secondaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: _secondaryText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
