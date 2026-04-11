// lib/legal_gpt/pages/legal_gpt_home_page.dart
import 'package:flutter/material.dart';
import '../services/legal_gpt_service.dart';
import '../models/legal_gpt_models.dart';
import 'legal_chat_page.dart';
import 'rights_cards_page.dart';
import 'document_templates_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class LegalGptHomePage extends StatefulWidget {
  final int userId;
  const LegalGptHomePage({super.key, required this.userId});

  @override
  State<LegalGptHomePage> createState() => _LegalGptHomePageState();
}

class _LegalGptHomePageState extends State<LegalGptHomePage> {
  final _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _askQuestion() {
    final q = _inputCtrl.text.trim();
    if (q.isEmpty) return;
    _inputCtrl.clear();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalChatPage(initialQuestion: q),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── AI intro ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.balance_rounded, size: 40, color: _kPrimary),
                SizedBox(height: 12),
                Text(
                  'Uliza swali lolote la kisheria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Pata ushauri wa kisheria kwa Kiswahili au Kiingereza, ukirejelewa sheria za Tanzania.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kSecondary, fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Quick actions ──
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TopicChip(
                icon: Icons.shield_rounded,
                label: 'Haki Zako',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RightsCardsPage(),
                  ),
                ),
              ),
              _TopicChip(
                icon: Icons.description_rounded,
                label: 'Mikataba',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentTemplatesPage(),
                  ),
                ),
              ),
              _TopicChip(
                icon: Icons.gavel_rounded,
                label: 'Mahakama',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LegalChatPage(initialQuestion: 'Mahakama za Tanzania na utaratibu wake'),
                  ));
                },
              ),
              _TopicChip(
                icon: Icons.people_rounded,
                label: 'Wakili',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LegalChatPage(initialQuestion: 'Jinsi ya kupata wakili Tanzania'),
                  ));
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Quick topics ──
          const Text(
            'Mada Maarufu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _topicTile(Icons.landscape_rounded, 'Haki za Ardhi', 'Land Rights'),
          _topicTile(Icons.work_rounded, 'Sheria ya Kazi', 'Employment Law'),
          _topicTile(Icons.family_restroom_rounded, 'Sheria ya Familia',
              'Family Law'),
          _topicTile(
              Icons.home_rounded, 'Haki za Mpangaji', 'Tenant Rights'),
          _topicTile(Icons.local_police_rounded, 'Haki Unapokamatwa',
              'Arrest Rights'),
          const SizedBox(height: 24),

          // ── Emergency ──
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => LegalChatPage(initialQuestion: 'Ninahitaji msaada wa kisheria wa dharura'),
              ));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Msaada wa Kisheria wa Dharura',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      // ── Bottom input ──
      bottomNavigationBar: SafeArea(
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
                  onSubmitted: (_) => _askQuestion(),
                  decoration: const InputDecoration(
                    hintText: 'Andika swali lako...',
                    hintStyle: TextStyle(color: _kSecondary, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: _kPrimary),
                onPressed: _askQuestion,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topicTile(IconData icon, String titleSw, String titleEn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: _kPrimary, size: 24),
        title: Text(
          titleSw,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          titleEn,
          style: const TextStyle(fontSize: 12, color: _kSecondary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: _kSecondary),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LegalChatPage(initialQuestion: titleSw),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 0,
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TopicChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 44) / 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPrimary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kPrimary)),
          ],
        ),
      ),
    );
  }
}
