import 'package:flutter/material.dart';
import '../../models/gossip_models.dart';
import '../../services/gossip_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/gossip_thread_card.dart';
import '../../l10n/app_strings_scope.dart';

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
    return hour >= 5 && hour < 17;
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
          if (digest == null) _error = 'Could not load digest';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
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
          strings?.digest ?? 'Digest',
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
                      TextButton(onPressed: _loadDigest, child: Text(strings?.retry ?? 'Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDigest,
                  color: const Color(0xFF1A1A1A),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      // Greeting
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
                      // Proverb card
                      if (_digest?.proverbEn != null || _digest?.proverbSw != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings?.proverbOfTheDay ?? 'Proverb of the Day',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _digest!.proverb(isSwahili: isSwahili),
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Top threads header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          strings?.topThreadsToday ?? 'Top Threads Today',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                      // Thread cards
                      if (_digest != null && _digest!.threads.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              strings?.noThreadsYet ?? 'No threads yet',
                              style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
                            ),
                          ),
                        )
                      else if (_digest != null)
                        ..._digest!.threads.map((thread) => GossipThreadCard(
                              key: ValueKey('digest_thread_${thread.id}'),
                              thread: thread,
                              onTap: () => Navigator.pushNamed(context, '/thread/${thread.id}'),
                            )),
                    ],
                  ),
                ),
    );
  }
}
