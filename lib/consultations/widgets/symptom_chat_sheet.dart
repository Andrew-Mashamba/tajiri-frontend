import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/symptom_checker_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kUserBubble = Color(0xFF1A1A1A);
const Color _kAiBubble = Color(0xFFF5F5F5);

/// Spec line 716 — conversational AI triage bottom sheet.
/// Cap at 6 turns. Displays follow-up questions in Sw/En.
/// Returns a [SymptomTriage] when ready=true so callers route to booking.
class SymptomChatSheet extends StatefulWidget {
  const SymptomChatSheet({super.key});

  static Future<SymptomTriage?> show(BuildContext context) {
    return showModalBottomSheet<SymptomTriage>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SymptomChatSheet(),
    );
  }

  @override
  State<SymptomChatSheet> createState() => _SymptomChatSheetState();
}

class _ChatTurn {
  final bool isUser;
  final String text;
  _ChatTurn({required this.isUser, required this.text});
}

class _SymptomChatSheetState extends State<SymptomChatSheet> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatTurn> _turns = [];
  bool _busy = false;
  SymptomTriage? _lastTriage;
  String? _error;
  static const int _maxTurns = 6;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _busy) return;
    if (_turns.length >= _maxTurns * 2) return;

    setState(() {
      _turns.add(_ChatTurn(isUser: true, text: text));
      _busy = true;
      _error = null;
    });
    _ctrl.clear();
    _scrollToBottom();

    final history = <Map<String, String>>[];
    for (var i = 0; i < _turns.length - 1; i += 2) {
      if (i < _turns.length && !_turns[i].isUser) continue;
      final userMsg = _turns[i].text;
      final aiMsg = (i + 1 < _turns.length) ? _turns[i + 1].text : '';
      history.add({'role': 'user', 'message': userMsg});
      history.add({'role': 'assistant', 'message': aiMsg});
    }

    final res = await SymptomCheckerService.checkConversational(
      symptom: text,
      conversationHistory: history,
    );

    if (!mounted) return;

    if (res == null) {
      setState(() {
        _busy = false;
        _error = _isSwahili
            ? 'Imeshindikana. Jaribu tena.'
            : 'Failed. Please try again.';
      });
      _scrollToBottom();
      return;
    }

    final isSw = _isSwahili;
    final aiText = isSw
        ? (res.followUpQuestionSw ?? res.followUpQuestionEn ?? '')
        : (res.followUpQuestionEn ?? res.followUpQuestionSw ?? '');

    setState(() {
      _busy = false;
      _lastTriage = res;
      if (aiText.isNotEmpty) {
        _turns.add(_ChatTurn(isUser: false, text: aiText));
      }
    });
    _scrollToBottom();

    if (res.severity == 'emergency' && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_rounded,
              color: Color(0xFFB71C1C), size: 32),
          title: Text(isSw ? 'Tahadhari!' : 'Emergency!'),
          content: Text(
            isSw
                ? 'Hii inaonekana kama dharura. Nenda hospitalini sasa au piga 112.'
                : 'This looks like an emergency. Go to the ER now or call 112.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isSw ? 'Sawa' : 'OK'),
            ),
          ],
        ),
      );
    }
  }

  void _routeToBooking() {
    if (_lastTriage != null) {
      Navigator.pop(context, _lastTriage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    final turnCount = _turns.where((t) => t.isUser).length;
    final atMax = turnCount >= _maxTurns;
    final ready = _lastTriage?.ready == true || atMax;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.health_and_safety_rounded,
                      size: 18, color: _kPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isSw
                          ? 'Mazungumzo ya tathmini ya dalili'
                          : 'Symptom triage chat',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$turnCount/$_maxTurns',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isSw
                    ? 'Jibu maswali ili kupata daktari sahihi.'
                    : 'Answer questions to find the right doctor.',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _turns.length + (_busy ? 1 : 0),
                    itemBuilder: (ctx, idx) {
                      if (idx >= _turns.length) {
                        return _typingIndicator();
                      }
                      return _bubble(_turns[idx], isSw);
                    },
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB71C1C),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (ready && _lastTriage != null) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _routeToBooking,
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: Text(
                    isSw
                        ? 'Tafuta madaktari wa ${_lastTriage!.specialty}'
                        : 'Find ${_lastTriage!.specialty} doctors',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ],
              if (!ready) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        enabled: !atMax,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: isSw
                              ? 'Andika jibu lako...'
                              : 'Type your answer...',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: atMax || _busy ? null : _send,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      color: _kPrimary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(_ChatTurn turn, bool isSw) {
    final isUser = turn.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? _kUserBubble : _kAiBubble,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          turn.text,
          style: TextStyle(
            fontSize: 13,
            color: isUser ? Colors.white : _kPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kAiBubble,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: _kSecondary.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}
