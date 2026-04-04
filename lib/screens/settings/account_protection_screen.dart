import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../services/local_storage_service.dart';

/// Active sessions and login alerts management screen.
/// Navigation: Settings -> Security -> Account Protection.
class AccountProtectionScreen extends StatefulWidget {
  final int currentUserId;

  const AccountProtectionScreen({super.key, required this.currentUserId});

  @override
  State<AccountProtectionScreen> createState() => _AccountProtectionScreenState();
}

class _AccountProtectionScreenState extends State<AccountProtectionScreen> {
  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  bool _isLoading = true;
  bool _loginAlertsEnabled = false;
  List<_SessionInfo> _sessions = [];
  String? _error;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      final headers = token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers;

      // Fetch sessions and login alert preference in parallel
      final results = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/sessions?user_id=${widget.currentUserId}'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/users/${widget.currentUserId}/privacy-settings'),
          headers: headers,
        ),
      ]);

      final sessionsResp = results[0];
      final privacyResp = results[1];

      if (mounted) {
        setState(() {
          // Parse sessions
          if (sessionsResp.statusCode == 200) {
            final data = jsonDecode(sessionsResp.body);
            final list = data['sessions'] ?? data['data'] ?? [];
            _sessions = (list as List)
                .map((s) => _SessionInfo.fromJson(s as Map<String, dynamic>))
                .toList();
          }

          // Parse login alerts preference
          if (privacyResp.statusCode == 200) {
            final data = jsonDecode(privacyResp.body);
            final settings = data['data'] ?? data;
            _loginAlertsEnabled = settings['login_alerts_enabled'] == true;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load session data';
        });
      }
    }
  }

  Future<void> _toggleLoginAlerts(bool value) async {
    setState(() => _loginAlertsEnabled = value);
    try {
      final token = await _getToken();
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/${widget.currentUserId}/privacy-settings'),
        headers: {
          ...(token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'login_alerts_enabled': value}),
      );
    } catch (_) {
      // Revert on failure
      if (mounted) setState(() => _loginAlertsEnabled = !value);
    }
  }

  Future<void> _revokeSession(int sessionId) async {
    setState(() => _isProcessing = true);
    try {
      final token = await _getToken();
      final resp = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/sessions/$sessionId'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _sessions.removeWhere((s) => s.id == sessionId);
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session revoked'), backgroundColor: Colors.green),
        );
      } else {
        if (mounted) setState(() => _isProcessing = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to revoke session'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _revokeAllSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out all devices'),
        content: const Text('This will sign you out from all other devices. You will remain signed in on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out all', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final token = await _getToken();
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/sessions/revoke-all'),
        headers: {
          ...(token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': widget.currentUserId}),
      );
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          // Keep only current session (if identifiable)
          _sessions = _sessions.where((s) => s.isCurrent).toList();
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All other sessions revoked'), backgroundColor: Colors.green),
        );
      } else {
        if (mounted) setState(() => _isProcessing = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to revoke sessions'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primaryText,
        title: const Text('Account Protection'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primaryText))
            : _error != null
                ? _buildErrorState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Login alerts toggle
                        _buildSection(
                          title: 'Login Alerts',
                          child: _buildSwitchTile(
                            icon: Icons.notifications_active_outlined,
                            title: 'Login Alerts',
                            subtitle: 'Get notified when someone logs into your account',
                            value: _loginAlertsEnabled,
                            onChanged: _toggleLoginAlerts,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Active sessions
                        _buildSection(
                          title: 'Active Sessions',
                          child: _sessions.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No active sessions found',
                                    style: TextStyle(color: _secondaryText, fontSize: 13),
                                  ),
                                )
                              : Column(
                                  children: _sessions.map((s) => _buildSessionTile(s)).toList(),
                                ),
                        ),

                        if (_sessions.length > 1) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: OutlinedButton.icon(
                                onPressed: _isProcessing ? null : _revokeAllSessions,
                                icon: const Icon(Icons.logout, color: Colors.red),
                                label: const Text(
                                  'Sign out all other devices',
                                  style: TextStyle(color: Colors.red),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: _secondaryText, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryText),
            ),
          ),
          child,
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryText.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryText, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _primaryText)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _secondaryText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _primaryText.withOpacity(0.5),
            activeThumbColor: _primaryText,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(_SessionInfo session) {
    final df = DateFormat('MMM d, yyyy HH:mm');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: session.isCurrent
                  ? Colors.green.withOpacity(0.1)
                  : _primaryText.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              session.isMobile ? Icons.phone_android : Icons.computer,
              color: session.isCurrent ? Colors.green : _primaryText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.deviceName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _primaryText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (session.isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  session.lastActiveAt != null
                      ? 'Last active: ${df.format(session.lastActiveAt!)}'
                      : 'Unknown activity',
                  style: const TextStyle(fontSize: 12, color: _secondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!session.isCurrent)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red, size: 20),
              tooltip: 'Sign out',
              onPressed: _isProcessing ? null : () => _revokeSession(session.id),
            ),
        ],
      ),
    );
  }
}

class _SessionInfo {
  final int id;
  final String deviceName;
  final DateTime? lastActiveAt;
  final bool isCurrent;
  final bool isMobile;

  _SessionInfo({
    required this.id,
    required this.deviceName,
    this.lastActiveAt,
    this.isCurrent = false,
    this.isMobile = false,
  });

  factory _SessionInfo.fromJson(Map<String, dynamic> json) {
    return _SessionInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      deviceName: json['device_name'] as String? ?? json['user_agent'] as String? ?? 'Unknown Device',
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'].toString())
          : null,
      isCurrent: json['is_current'] == true,
      isMobile: json['is_mobile'] == true ||
          (json['device_name'] ?? json['user_agent'] ?? '')
              .toString()
              .toLowerCase()
              .contains(RegExp(r'android|iphone|mobile').pattern),
    );
  }
}
