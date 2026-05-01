import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/dispute_service.dart';
import '../widgets/dispute_window_banner.dart';

/// Spec F7 #69 — Mediation chat thread.
class DisputeMediationPage extends StatefulWidget {
  final int userId;
  final int engagementId;
  final String role;

  const DisputeMediationPage({
    super.key,
    required this.userId,
    required this.engagementId,
    required this.role,
  });

  @override
  State<DisputeMediationPage> createState() => _DisputeMediationPageState();
}

class _DisputeMediationPageState extends State<DisputeMediationPage> {
  final _ctrl = TextEditingController();
  DisputeThread _thread = const DisputeThread(messages: []);
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final t = await DisputeService.thread(widget.engagementId);
    if (!mounted) return;
    setState(() {
      _thread = t;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    final ok = await DisputeService.send(
      userId: widget.userId,
      engagementId: widget.engagementId,
      role: widget.role,
      body: body,
    );
    if (!mounted) return;
    if (ok) {
      _ctrl.clear();
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindikana kutuma')),
      );
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _escalate() async {
    final ok = await DisputeService.escalate(
      userId: widget.userId,
      engagementId: widget.engagementId,
    );
    if (!mounted) return;
    if (ok) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Mzozo + upatanishi' : 'Dispute mediation'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_thread.windowStartedAt != null)
                  DisputeWindowBanner(
                    windowStartedAt: _thread.windowStartedAt!,
                    escalatedAt: _thread.escalatedAt,
                    onEscalate: _thread.escalatedAt != null ? null : _escalate,
                  ),
                if (_thread.releaseTo != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isSw
                          ? 'Uamuzi: pesa zinarudi kwa ${_thread.releaseTo}'
                          : 'Resolved: funds released to ${_thread.releaseTo}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20)),
                    ),
                  ),
                Expanded(
                  child: _thread.messages.isEmpty
                      ? Center(
                          child: Text(
                            isSw
                                ? 'Anza kujadili na mtoa huduma hapa.'
                                : 'Start the conversation with the partner.',
                            style: const TextStyle(color: Color(0xFF666666)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _thread.messages.length,
                          itemBuilder: (ctx, i) {
                            final m = _thread.messages[i];
                            final mine = m.senderUserId == widget.userId;
                            final isMediator = m.senderRole == 'mediator';
                            return Align(
                              alignment: isMediator
                                  ? Alignment.center
                                  : (mine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                                ),
                                decoration: BoxDecoration(
                                  color: isMediator
                                      ? const Color(0xFFFFF3E0)
                                      : (mine
                                          ? const Color(0xFF1A1A1A)
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isMediator
                                      ? Border.all(
                                          color:
                                              const Color(0xFFE65100).withValues(alpha: 0.3))
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isMediator)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          'TAJIRI MEDIATOR',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFE65100)),
                                        ),
                                      ),
                                    Text(
                                      m.body,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: mine && !isMediator
                                            ? Colors.white
                                            : const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    if (m.createdAt != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${m.createdAt!.hour.toString().padLeft(2, '0')}:${m.createdAt!.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: mine && !isMediator
                                                ? Colors.white70
                                                : const Color(0xFF999999),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: isSw ? 'Andika ujumbe…' : 'Type a message…',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFAFAFA),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                          onPressed: _sending ? null : _send,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
