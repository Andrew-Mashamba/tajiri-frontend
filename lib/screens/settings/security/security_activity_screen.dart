import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../services/security_service.dart';
import '_security_widgets.dart';

class SecurityActivityScreen extends StatefulWidget {
  final int currentUserId;
  const SecurityActivityScreen({super.key, required this.currentUserId});

  @override
  State<SecurityActivityScreen> createState() => _SecurityActivityScreenState();
}

class _SecurityActivityScreenState extends State<SecurityActivityScreen> {
  final _service = SecurityService();
  List<SecurityActivityItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.activityLog(widget.currentUserId, limit: 100);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final df = DateFormat('MMM d, yyyy HH:mm');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kUsalamaBg,
        appBar: AppBar(
          title: Text(s?.usalamaCardActivity ?? 'Security activity'),
          backgroundColor: kUsalamaCard,
          foregroundColor: kUsalamaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kUsalamaPrimary))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            const SizedBox(height: 64),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  s?.usalamaActivityEmpty ?? 'No security activity yet',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: kUsalamaSecondary),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: _items.length,
                          itemBuilder: (ctx, i) => _activityTile(_items[i], s, df),
                        ),
                ),
        ),
      ),
    );
  }

  Widget _activityTile(SecurityActivityItem item, dynamic s, DateFormat df) {
    final label = s?.usalamaEventLabel(item.eventType) ?? item.eventType;
    final color = _eventColor(item.eventType);
    final icon = _eventIcon(item.eventType);
    final ip = item.ipAddress;
    final ua = item.userAgent;
    final created = item.createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kUsalamaCard,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kUsalamaPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (created != null) df.format(created.toLocal()),
                        if (ip != null && ip.isNotEmpty) ip,
                        if (ua != null && ua.isNotEmpty) _shortenUa(ua),
                      ].join(' • '),
                      style: const TextStyle(fontSize: 11, color: kUsalamaSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortenUa(String ua) {
    if (ua.length <= 50) return ua;
    return '${ua.substring(0, 47)}…';
  }

  Color _eventColor(String t) {
    if (t.contains('failed')) return Colors.red;
    if (t.contains('disabled') || t.contains('removed') || t.contains('revoked')) {
      return Colors.orange;
    }
    if (t.contains('enabled') || t.contains('set') || t.contains('changed')) {
      return Colors.green;
    }
    if (t.contains('login')) return Colors.blue;
    return kUsalamaPrimary;
  }

  IconData _eventIcon(String t) {
    if (t.contains('password')) return Icons.password;
    if (t.contains('2fa')) return Icons.verified_user_outlined;
    if (t.contains('app_lock')) return Icons.lock_outline;
    if (t.contains('session')) return Icons.devices_outlined;
    if (t.contains('login')) return Icons.login;
    if (t.contains('logout')) return Icons.logout;
    return Icons.history;
  }
}
