// lib/legal_gpt/pages/document_templates_page.dart
import 'package:flutter/material.dart';
import '../models/legal_gpt_models.dart';
import '../services/legal_gpt_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DocumentTemplatesPage extends StatefulWidget {
  const DocumentTemplatesPage({super.key});

  @override
  State<DocumentTemplatesPage> createState() => _DocumentTemplatesPageState();
}

class _DocumentTemplatesPageState extends State<DocumentTemplatesPage> {
  List<DocumentTemplate> _templates = [];
  bool _loading = true;
  String? _selectedCategory;
  final _service = LegalGptService();

  static const _categories = ['employment', 'rental', 'sale', 'business', 'family'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getTemplates(category: _selectedCategory);
    if (mounted) {
      setState(() {
        _templates = result.items;
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
        title: const Text('Mikataba na Nyaraka',
            style: TextStyle(color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ── Category filter ──
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Zote'),
                    selected: _selectedCategory == null,
                    selectedColor: _kPrimary,
                    labelStyle: TextStyle(
                      color: _selectedCategory == null ? Colors.white : _kPrimary,
                      fontSize: 13,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                      _load();
                    },
                  ),
                ),
                ..._categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(c),
                    selected: _selectedCategory == c,
                    selectedColor: _kPrimary,
                    labelStyle: TextStyle(
                      color: _selectedCategory == c ? Colors.white : _kPrimary,
                      fontSize: 13,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = c);
                      _load();
                    },
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Templates list ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _templates.isEmpty
                    ? const Center(child: Text('Hakuna mikataba', style: TextStyle(color: _kSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _templates.length,
                        itemBuilder: (_, i) => _buildTemplate(_templates[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplate(DocumentTemplate tpl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded, color: _kPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(tpl.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(tpl.description, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tpl.category,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
              ),
              const Spacer(),
              Text('${tpl.fields.length} sehemu',
                  style: const TextStyle(fontSize: 12, color: _kSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
