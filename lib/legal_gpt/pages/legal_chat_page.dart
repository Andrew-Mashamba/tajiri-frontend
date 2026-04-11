// lib/legal_gpt/pages/legal_chat_page.dart
import 'package:flutter/material.dart';
import '../models/legal_gpt_models.dart';
import '../services/legal_gpt_service.dart';
import '../widgets/chat_bubble.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class LegalChatPage extends StatefulWidget {
  final String? initialQuestion;
  const LegalChatPage({super.key, this.initialQuestion});

  @override
  State<LegalChatPage> createState() => _LegalChatPageState();
}

class _LegalChatPageState extends State<LegalChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<LegalMessage> _messages = [];
  bool _sending = false;
  final _service = LegalGptService();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
      _send(widget.initialQuestion!);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = LegalMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(userMsg);
      _sending = true;
    });
    _scrollToBottom();

    final history = _messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final result = await _service.askQuestion(text.trim(), history);

    if (mounted) {
      setState(() {
        _sending = false;
        if (result.success && result.data != null) {
          _messages.add(result.data!);
        } else {
          _messages.add(LegalMessage(
            id: DateTime.now().millisecondsSinceEpoch,
            role: 'assistant',
            content: result.message.isNotEmpty
                ? result.message
                : 'Samahani, sijaweza kujibu. Jaribu tena.',
            timestamp: DateTime.now().toIso8601String(),
          ));
        }
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text('Mazungumzo ya Kisheria',
            style: TextStyle(color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text('Uliza swali lako la kisheria',
                        style: TextStyle(color: _kSecondary, fontSize: 14)),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length && _sending) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChatBubble(message: _messages[i]),
                      );
                    },
                  ),
          ),
          // ── Input ──
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      onSubmitted: (t) {
                        _send(t);
                        _inputCtrl.clear();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Andika swali...',
                        hintStyle: TextStyle(color: _kSecondary, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: _kPrimary),
                    onPressed: () {
                      _send(_inputCtrl.text);
                      _inputCtrl.clear();
                    },
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
