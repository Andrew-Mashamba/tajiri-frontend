import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F2 #12 — In-app help chat with <3-min SLA.
///
/// User opens a ticket; ops responds in the same thread. SLA target enforced
/// server-side (`first_response_seconds` recorded the moment an ops reply
/// hits the thread). This page is the customer surface; ops queue gets its
/// own admin tool (out of mobile-app scope).
class SupportChatPage extends StatefulWidget {
  final int userId;
  final int? existingTicketId;
  const SupportChatPage({
    super.key,
    required this.userId,
    this.existingTicketId,
  });

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  int? _ticketId;
  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _messages = const [];
  final _ctrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ticketId = widget.existingTicketId;
    if (_ticketId != null) _refresh();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_ticketId == null) return;
    final body = await SupportTicketsService.thread(_ticketId!);
    if (!mounted || body == null) return;
    setState(() {
      _ticket = body['ticket'] is Map<String, dynamic> ? body['ticket'] : null;
      _messages = (body['messages'] as List?)
              ?.whereType<Map>()
              .map((m) => m.cast<String, dynamic>())
              .toList() ??
          const [];
    });
  }

  Future<void> _open() async {
    if (_subjectCtrl.text.trim().isEmpty || _ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final id = await SupportTicketsService.open(
      userId: widget.userId,
      subject: _subjectCtrl.text.trim(),
      message: _ctrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _ticketId = id;
      _ctrl.clear();
    });
    if (id != null) await _refresh();
  }

  Future<void> _send() async {
    if (_ticketId == null) return;
    final body = _ctrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _loading = true);
    await SupportTicketsService.send(
      ticketId: _ticketId!,
      userId: widget.userId,
      role: 'customer',
      body: body,
    );
    if (!mounted) return;
    _ctrl.clear();
    setState(() => _loading = false);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final firstResp = _ticket?['first_response_seconds'] as num?;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Pata msaada' : 'Help'),
      ),
      body: _ticketId == null ? _buildOpenForm(isSw) : _buildThread(isSw, firstResp),
    );
  }

  Widget _buildOpenForm(bool isSw) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          isSw
              ? 'Tueleze tatizo lako — tutajibu ndani ya dakika 3.'
              : 'Tell us what\'s wrong — we reply within 3 minutes.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _subjectCtrl,
          decoration: InputDecoration(
            labelText: isSw ? 'Kichwa cha tatizo' : 'Subject',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: isSw ? 'Eleza zaidi' : 'Describe in detail',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A)),
            onPressed: _loading ? null : _open,
            child: Text(_loading
                ? (isSw ? 'Inatuma…' : 'Sending…')
                : (isSw ? 'Fungua tiketi' : 'Open ticket')),
          ),
        ),
      ],
    );
  }

  Widget _buildThread(bool isSw, num? firstRespSeconds) {
    return Column(
      children: [
        if (firstRespSeconds != null && firstRespSeconds > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: firstRespSeconds <= 180
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFF3E0),
            child: Text(
              isSw
                  ? 'Jibu la kwanza: ${firstRespSeconds}s'
                  : 'First response: ${firstRespSeconds}s',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: firstRespSeconds <= 180
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFFE65100),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (ctx, i) {
              final m = _messages[i];
              final mine = (m['sender_role'] as String?) == 'customer';
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8),
                  decoration: BoxDecoration(
                    color: mine ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: mine ? null : Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Text(
                    (m['body'] as String?) ?? '',
                    style: TextStyle(
                      color: mine ? Colors.white : const Color(0xFF1A1A1A),
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
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
                  icon: _loading
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  onPressed: _loading ? null : _send,
                  color: const Color(0xFF1A1A1A),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
