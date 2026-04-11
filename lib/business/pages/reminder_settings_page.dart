// lib/business/pages/reminder_settings_page.dart
// Automated Payment Reminders (Vikumbusho vya Malipo).
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ReminderSettingsPage extends StatefulWidget {
  final int businessId;
  const ReminderSettingsPage({super.key, required this.businessId});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  String? _token;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _isEnabled = false;
  final Set<int> _reminderDays = {0, 7, 14, 30};
  final Set<String> _channels = {'sms', 'tajiri'};
  final _messageCtrl = TextEditingController();

  static const _availableDays = [0, 3, 7, 14, 30, 60, 90];
  static const _dayLabels = {
    0: 'Due Date',
    3: '3 days after',
    7: '1 week after',
    14: '2 weeks after',
    30: '1 month after',
    60: '2 months after',
    90: '3 months after',
  };

  static const _channelInfo = {
    'sms': {'label': 'SMS', 'icon': Icons.sms_rounded},
    'tajiri': {'label': 'TAJIRI', 'icon': Icons.message_rounded},
    'whatsapp': {'label': 'WhatsApp', 'icon': Icons.chat_rounded},
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await BusinessService.getReminderConfig(_token!, widget.businessId);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success && res.data != null) {
            final c = res.data!;
            _isEnabled = c.isEnabled;
            _reminderDays
              ..clear()
              ..addAll(c.reminderDays);
            _channels
              ..clear()
              ..addAll(c.channels);
            _messageCtrl.text = c.customMessage ?? '';
          } else if (!res.success) {
            _error = res.message ?? 'Failed to load settings';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Connection error. Tap Save to retry.';
        });
      }
    }
  }

  Future<void> _save() async {
    if (_token == null) return;
    setState(() => _saving = true);
    try {
      final body = {
        'is_enabled': _isEnabled,
        'reminder_days': _reminderDays.toList()..sort(),
        'channels': _channels.toList(),
        'custom_message': _messageCtrl.text.trim(),
      };
      final res = await BusinessService.updateReminderConfig(
          _token!, widget.businessId, body);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                res.success ? 'Reminders updated' : (res.message ?? 'Failed'))));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection error')));
      }
    }
  }

  void _showPreviewMessage() {
    final msg = _messageCtrl.text.trim().isNotEmpty
        ? _messageCtrl.text
            .replaceAll('{customer_name}', 'Juma Hassan')
            .replaceAll('{amount}', 'TZS 500,000')
            .replaceAll('{due_date}', '15/04/2026')
        : 'Hello Juma Hassan, this is a reminder that a payment of TZS 500,000 was due on 15/04/2026. Please pay at your earliest convenience.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Message Preview'),
        content: Text(msg, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null && _reminderDays.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style:
                            TextButton.styleFrom(foregroundColor: _kPrimary),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Enable toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isEnabled
                                  ? Colors.green.shade50
                                  : _kPrimary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.notifications_active_rounded,
                              size: 22,
                              color: _isEnabled
                                  ? Colors.green.shade700
                                  : _kSecondary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Auto Reminders',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _kPrimary,
                                        fontSize: 14)),
                                Text(
                                  _isEnabled
                                      ? 'Reminders are sent automatically'
                                      : 'Reminders are disabled',
                                  style: const TextStyle(
                                      fontSize: 12, color: _kSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isEnabled,
                            onChanged: (v) =>
                                setState(() => _isEnabled = v),
                            activeTrackColor:
                                _kPrimary.withValues(alpha: 0.4),
                            activeThumbColor: _kPrimary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Reminder schedule
                    const Text('Reminder Schedule',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary)),
                    const SizedBox(height: 4),
                    const Text(
                        'Select when to send reminders relative to the due date',
                        style:
                            TextStyle(fontSize: 12, color: _kSecondary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableDays.map((d) {
                        final isSelected = _reminderDays.contains(d);
                        return FilterChip(
                          label: Text(_dayLabels[d] ?? 'Day $d',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : _kPrimary)),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              if (isSelected) {
                                _reminderDays.remove(d);
                              } else {
                                _reminderDays.add(d);
                              }
                            });
                          },
                          selectedColor: _kPrimary,
                          backgroundColor: _kCardBg,
                          side: BorderSide(
                              color: isSelected
                                  ? _kPrimary
                                  : Colors.grey.shade200),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Channel selection
                    const Text('Delivery Channels',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary)),
                    const SizedBox(height: 10),
                    ...(_channelInfo.entries.map((entry) {
                      final key = entry.key;
                      final label = entry.value['label'] as String;
                      final icon = entry.value['icon'] as IconData;
                      final isSelected = _channels.contains(key);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected
                                  ? _kPrimary
                                  : Colors.grey.shade200),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) {
                            setState(() {
                              if (isSelected) {
                                _channels.remove(key);
                              } else {
                                _channels.add(key);
                              }
                            });
                          },
                          title: Text(label,
                              style: const TextStyle(
                                  fontSize: 14, color: _kPrimary)),
                          secondary:
                              Icon(icon, color: _kPrimary, size: 20),
                          activeColor: _kPrimary,
                          controlAffinity:
                              ListTileControlAffinity.trailing,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    })),

                    const SizedBox(height: 20),

                    // Custom message
                    const Text('Custom Message',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary)),
                    const SizedBox(height: 4),
                    const Text(
                        'Use {customer_name}, {amount}, {due_date} as placeholders',
                        style:
                            TextStyle(fontSize: 11, color: _kSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Hello {customer_name}, this is a reminder that a payment of {amount} was due on {due_date}...',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color: _kSecondary.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: _kCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _showPreviewMessage,
                        icon: const Icon(Icons.preview_rounded, size: 16),
                        label: const Text('Preview',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                            foregroundColor: _kPrimary),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Save Settings',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
    );
  }
}
