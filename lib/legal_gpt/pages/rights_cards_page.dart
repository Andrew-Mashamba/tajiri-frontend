// lib/legal_gpt/pages/rights_cards_page.dart
import 'package:flutter/material.dart';
import '../models/legal_gpt_models.dart';
import '../services/legal_gpt_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class RightsCardsPage extends StatefulWidget {
  const RightsCardsPage({super.key});

  @override
  State<RightsCardsPage> createState() => _RightsCardsPageState();
}

class _RightsCardsPageState extends State<RightsCardsPage> {
  List<RightsCard> _cards = [];
  bool _loading = true;
  final _service = LegalGptService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getRightsCards();
    if (mounted) {
      setState(() {
        _cards = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text('Haki Zako',
            style: TextStyle(color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _cards.isEmpty
              ? const Center(child: Text('Hakuna kadi za haki', style: TextStyle(color: _kSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cards.length,
                  itemBuilder: (_, i) => _buildCard(_cards[i]),
                ),
    );
  }

  Widget _buildCard(RightsCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(card.category,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            card.titleSw.isNotEmpty ? card.titleSw : card.titleEn,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            card.descriptionSw.isNotEmpty ? card.descriptionSw : card.descriptionEn,
            style: const TextStyle(fontSize: 13, color: _kSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (card.keyPointsSw.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...card.keyPointsSw.take(3).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('  ', style: TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(p, style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
                ],
              ),
            )),
          ],
          if (card.whatToDo.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {},
              child: const Text('Nini cha kufanya >',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
            ),
          ],
        ],
      ),
    );
  }
}
