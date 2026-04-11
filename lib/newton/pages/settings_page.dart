// lib/newton/pages/settings_page.dart
import 'package:flutter/material.dart';
import '../models/newton_models.dart';
import '../services/newton_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class NewtonSettingsPage extends StatefulWidget {
  final int userId;
  final bool isSwahili;
  const NewtonSettingsPage({
    super.key,
    required this.userId,
    this.isSwahili = false,
  });
  @override
  State<NewtonSettingsPage> createState() => _NewtonSettingsPageState();
}

class _NewtonSettingsPageState extends State<NewtonSettingsPage> {
  final NewtonService _service = NewtonService();
  late bool _isSwahili;
  DifficultyLevel _defaultDifficulty = DifficultyLevel.form1_4;
  bool _defaultSocratic = false;
  UsageStats _usage = UsageStats();
  bool _isLoadingUsage = true;

  @override
  void initState() {
    super.initState();
    _isSwahili = widget.isSwahili;
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final result = await _service.getUsageStats();
    if (!mounted) return;
    setState(() {
      _isLoadingUsage = false;
      if (result.success && result.data != null) {
        _usage = result.data!;
      }
    });
  }

  void _clearHistory() async {
    final sw = _isSwahili;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          sw ? 'Futa historia yote?' : 'Clear all history?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          sw
              ? 'Mazungumzo yote yatafutwa. Hii haiwezi kurudishwa.'
              : 'All conversations will be deleted. This cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sw ? 'Futa' : 'Clear',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    // Delete all conversations
    final result = await _service.getConversations();
    if (result.success) {
      for (final conv in result.items) {
        await _service.deleteConversation(conv.id);
      }
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
            sw ? 'Historia imefutwa' : 'History cleared'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Mipangilio ya Newton' : 'Newton settings',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language
          _sectionHeader(sw ? 'Lugha' : 'Language'),
          _settingTile(
            icon: Icons.translate_rounded,
            title: sw ? 'Lugha ya majibu' : 'Response language',
            subtitle: _isSwahili ? 'Kiswahili' : 'English',
            trailing: Switch.adaptive(
              value: _isSwahili,
              activeTrackColor: _kPrimary,
              onChanged: (v) => setState(() => _isSwahili = v),
            ),
          ),

          const SizedBox(height: 20),

          // Defaults
          _sectionHeader(sw ? 'Chaguo za msingi' : 'Defaults'),
          _settingTile(
            icon: Icons.school_rounded,
            title: sw ? 'Kiwango cha chaguo-msingi' : 'Default difficulty',
            subtitle: _isSwahili
                ? _defaultDifficulty.displayNameSw
                : _defaultDifficulty.displayName,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: Text(
                    sw ? 'Chagua kiwango' : 'Select difficulty',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  children: DifficultyLevel.values.map((d) {
                    return SimpleDialogOption(
                      onPressed: () {
                        setState(() => _defaultDifficulty = d);
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              _defaultDifficulty == d
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 20,
                              color: _kPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              sw ? d.displayNameSw : d.displayName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          _settingTile(
            icon: Icons.psychology_rounded,
            title: sw
                ? 'Njia ya Socratic kwa chaguo-msingi'
                : 'Socratic mode by default',
            subtitle: sw
                ? 'Newton atakuuliza maswali ya kuongoza badala ya kutoa majibu moja kwa moja'
                : 'Newton will ask guiding questions instead of giving direct answers',
            trailing: Switch.adaptive(
              value: _defaultSocratic,
              activeTrackColor: _kPrimary,
              onChanged: (v) => setState(() => _defaultSocratic = v),
            ),
          ),

          const SizedBox(height: 20),

          // Usage
          _sectionHeader(sw ? 'Matumizi' : 'Usage'),
          _isLoadingUsage
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary),
                  ),
                )
              : Column(
                  children: [
                    _settingTile(
                      icon: Icons.today_rounded,
                      title: sw ? 'Maswali ya leo' : 'Questions today',
                      subtitle:
                          '${_usage.questionsToday} / ${_usage.dailyLimit}',
                    ),
                    _settingTile(
                      icon: Icons.bar_chart_rounded,
                      title: sw ? 'Jumla ya maswali' : 'Total questions',
                      subtitle: '${_usage.questionsTotal}',
                    ),
                    _settingTile(
                      icon: Icons.timer_rounded,
                      title: sw ? 'Maswali yaliyobaki' : 'Questions remaining',
                      subtitle: '${_usage.remaining}',
                    ),
                  ],
                ),

          const SizedBox(height: 20),

          // Danger zone
          _sectionHeader(sw ? 'Eneo hatari' : 'Danger zone'),
          _settingTile(
            icon: Icons.delete_forever_rounded,
            title: sw ? 'Futa historia yote' : 'Clear all history',
            subtitle: sw
                ? 'Futa mazungumzo yote na Newton'
                : 'Delete all Newton conversations',
            titleColor: Colors.red,
            onTap: _clearHistory,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kSecondary,
            letterSpacing: 0.5),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, size: 22, color: titleColor ?? _kPrimary),
        title: Text(
          title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: titleColor ?? _kPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: _kSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded,
                    size: 20, color: _kSecondary)
                : null),
        onTap: onTap,
      ),
    );
  }
}
