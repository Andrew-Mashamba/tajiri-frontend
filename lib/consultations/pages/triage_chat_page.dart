import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F7 #47 + #48 — Conversational AI triage with bilingual symptom capture.
///
/// Customer types in Swahili or English; backend calls Anthropic and returns
/// reply + extracted intent (`category`, `urgency`, `summary`). Page accumulates
/// turns locally for UI; conversation_id keeps the server-side log linked.
class TriageChatPage extends StatefulWidget {
  final int userId;
  const TriageChatPage({super.key, required this.userId});

  @override
  State<TriageChatPage> createState() => _TriageChatPageState();
}

class _Turn {
  final String role;
  final String content;
  _Turn(this.role, this.content);
}

class _TriageChatPageState extends State<TriageChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  int? _conversationId;
  Map<String, dynamic>? _intent;
  final List<_Turn> _turns = [];
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) return;
    _ctrl.clear();
    setState(() {
      _turns.add(_Turn('user', msg));
      _sending = true;
    });
    final res = await TriageService.turn(
      userId: widget.userId,
      conversationId: _conversationId,
      message: msg,
    );
    if (!mounted) return;
    if (res != null && res['ok'] == true) {
      _conversationId = (res['conversation_id'] as num?)?.toInt();
      final reply = res['reply']?.toString() ?? '';
      final intent = res['intent'];
      setState(() {
        _turns.add(_Turn('assistant', reply));
        _intent = intent is Map<String, dynamic> ? intent : null;
        _sending = false;
      });
    } else {
      setState(() => _sending = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Color _urgencyColor(String? u) {
    switch (u) {
      case 'emergency':
        return const Color(0xFFB71C1C);
      case 'high':
        return const Color(0xFFE65100);
      case 'low':
        return const Color(0xFF1B5E20);
      default:
        return const Color(0xFF666666);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final urgency = _intent?['urgency']?.toString();
    final category = _intent?['category']?.toString();
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Mshauri wa awali' : 'AI triage'),
      ),
      body: Column(
        children: [
          if (_intent != null && (urgency != null || category != null))
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _urgencyColor(urgency).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _urgencyColor(urgency).withValues(alpha: 0.3)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (category != null && category.isNotEmpty)
                    Chip(
                      label: Text(category, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (urgency != null)
                    Chip(
                      label: Text(urgency, style: const TextStyle(fontSize: 11)),
                      backgroundColor: _urgencyColor(urgency),
                      labelStyle: const TextStyle(color: Colors.white),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          Expanded(
            child: _turns.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        isSw
                            ? 'Eleza tatizo lako kwa Kiswahili au Kiingereza.'
                            : 'Describe your concern in Swahili or English.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF666666)),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _turns.length,
                    itemBuilder: (ctx, i) {
                      final t = _turns[i];
                      final mine = t.role == 'user';
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
                            border: mine
                                ? null
                                : Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Text(
                            t.content,
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
                        hintText: isSw ? 'Andika hapa…' : 'Type here…',
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
