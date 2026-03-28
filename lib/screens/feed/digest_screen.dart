import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/gossip_models.dart';
import '../../services/gossip_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/gossip_thread_card.dart';
import '../../l10n/app_strings_scope.dart';
import 'thread_viewer_screen.dart';

class DigestScreen extends StatefulWidget {
  final int currentUserId;
  const DigestScreen({super.key, required this.currentUserId});

  @override
  State<DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends State<DigestScreen> {
  final GossipService _gossipService = GossipService();
  DigestResponse? _digest;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDigest();
  }

  bool get _isMorning {
    final hour = DateTime.now().hour;
    return hour >= 5 && hour < 12;
  }

  Future<void> _loadDigest() async {
    setState(() { _loading = true; _error = null; });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() { _error = 'Not authenticated'; _loading = false; });
        return;
      }
      final digest = await _gossipService.getDigest(token: token);
      if (mounted) {
        setState(() {
          _digest = digest;
          _loading = false;
          if (digest == null) _error = 'No digest available';
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DigestScreen] Error: $e');
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Widget _buildRecapRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF999999)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF666666)))),
        if (value.isNotEmpty)
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          _isMorning
              ? (isSwahili ? 'Kumekucha' : 'Good Morning')
              : (isSwahili ? 'Usiku Mwema' : 'Evening Recap'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Color(0xFF666666))),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loadDigest,
                        child: Text(strings?.retry ?? 'Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDigest,
                  color: const Color(0xFF1A1A1A),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Greeting
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _isMorning
                              ? (strings?.goodMorning ?? 'Good Morning!')
                              : (strings?.goodEvening ?? 'Good Evening!'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      // Proverb of the day
                      if (_digest != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSwahili ? 'Methali ya Leo' : 'Proverb of the Day',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _digest!.proverb(isSwahili: isSwahili),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Trending threads section
                      Text(
                        isSwahili ? 'Mada Zinazovuma' : 'Trending Threads',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_digest != null && _digest!.threads.isNotEmpty)
                        ..._digest!.threads.map((thread) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GossipThreadCard(
                            key: ValueKey('digest_thread_${thread.id}'),
                            thread: thread,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ThreadViewerScreen(
                                  threadId: thread.id,
                                  currentUserId: widget.currentUserId,
                                ),
                              ),
                            ),
                          ),
                        ))
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              isSwahili ? 'Hakuna mada kwa sasa' : 'No threads yet',
                              style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
                            ),
                          ),
                        ),
                      // Evening recap (only shown in evening)
                      if (!_isMorning) ...[
                        const SizedBox(height: 20),
                        Text(
                          isSwahili ? 'Muhtasari wa Jioni' : 'Evening Recap',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                          ),
                          child: Column(
                            children: [
                              _buildRecapRow(Icons.visibility_outlined, isSwahili ? 'Machapisho uliyotazama leo' : 'Posts you viewed today', '${_digest?.threads.length ?? 0}+'),
                              const SizedBox(height: 12),
                              _buildRecapRow(Icons.local_fire_department_rounded, isSwahili ? 'Mada mpya leo' : 'New threads today', '${_digest?.threads.where((t) => t.status == ThreadStatus.active).length ?? 0}'),
                              const SizedBox(height: 12),
                              _buildRecapRow(Icons.schedule_rounded, isSwahili ? 'Usiku Mwema' : 'Good Night', ''),
                            ],
                          ),
                        ),
                      ],
                      // Unfinished threads section (placeholder)
                      const SizedBox(height: 20),
                      Text(
                        isSwahili ? 'Mada Ambayo Hukukamilisha' : 'Threads You Left Unfinished',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                        ),
                        child: Center(
                          child: Text(
                            isSwahili ? 'Uko sawa — umesoma yote!' : 'You\'re all caught up!',
                            style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
