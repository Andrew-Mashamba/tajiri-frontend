// lib/nida/pages/document_checklist_page.dart
import 'package:flutter/material.dart';
import '../models/nida_models.dart';
import '../services/nida_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DocumentChecklistPage extends StatefulWidget {
  const DocumentChecklistPage({super.key});
  @override
  State<DocumentChecklistPage> createState() => _DocumentChecklistPageState();
}

class _DocumentChecklistPageState extends State<DocumentChecklistPage> {
  String _type = 'first_registration';
  List<ChecklistItem> _items = [];
  final Set<String> _checked = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await NidaService.getChecklist(_type);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _items = result.items;
      } else {
        // Fallback static checklist
        _items = _staticChecklist();
      }
    });
  }

  List<ChecklistItem> _staticChecklist() {
    if (_type == 'first_registration') {
      return [
        ChecklistItem(id: '1', title: 'Cheti cha Kuzaliwa', description: 'Birth certificate (original & copy)', whereToGet: 'RITA Office'),
        ChecklistItem(id: '2', title: 'Barua ya Mtaa', description: 'Introduction letter from Ward Executive Officer', whereToGet: 'Ofisi ya Mtaa'),
        ChecklistItem(id: '3', title: 'Picha za Pasipoti', description: '2 passport-size photos (white background)', whereToGet: 'Photo studio'),
        ChecklistItem(id: '4', title: 'Kitambulisho cha Mzazi', description: 'Parent\'s NIDA card (copy)', whereToGet: 'Parent'),
      ];
    } else if (_type == 'replacement') {
      return [
        ChecklistItem(id: '1', title: 'Taarifa ya Polisi', description: 'Police report for lost/stolen card', whereToGet: 'Kituo cha Polisi'),
        ChecklistItem(id: '2', title: 'Barua ya Kiapo', description: 'Affidavit for lost card', whereToGet: 'Advocate/Commissioner for Oaths'),
        ChecklistItem(id: '3', title: 'Picha za Pasipoti', description: '2 passport photos', whereToGet: 'Photo studio'),
      ];
    }
    return [
      ChecklistItem(id: '1', title: 'Nyaraka za Kusahihisha', description: 'Supporting documents for correction', whereToGet: 'Varies'),
      ChecklistItem(id: '2', title: 'Kitambulisho cha Sasa', description: 'Current NIDA card or receipt', whereToGet: 'Your records'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Nyaraka Zinazohitajika',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(
        children: [
          // Type selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _TypeChip(label: 'Usajili Mpya', selected: _type == 'first_registration',
                    onTap: () { _type = 'first_registration'; _load(); }),
                const SizedBox(width: 8),
                _TypeChip(label: 'Kibadala', selected: _type == 'replacement',
                    onTap: () { _type = 'replacement'; _load(); }),
                const SizedBox(width: 8),
                _TypeChip(label: 'Marekebisho', selected: _type == 'correction',
                    onTap: () { _type = 'correction'; _load(); }),
              ],
            ),
          ),
          // Progress
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${_checked.length}/${_items.length} tayari',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                const Spacer(),
                if (_checked.length == _items.length && _items.isNotEmpty)
                  const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF4CAF50)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Checklist
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final done = _checked.contains(item.id);
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => setState(() {
                            done ? _checked.remove(item.id) : _checked.add(item.id);
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(
                                  done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  size: 22,
                                  color: done ? const Color(0xFF4CAF50) : _kSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title,
                                        style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary,
                                          decoration: done ? TextDecoration.lineThrough : null,
                                        ),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(item.description,
                                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                                        maxLines: 2, overflow: TextOverflow.ellipsis),
                                    if (item.whereToGet != null) ...[
                                      const SizedBox(height: 4),
                                      Text('Inapatikana: ${item.whereToGet}',
                                          style: const TextStyle(fontSize: 11, color: _kSecondary, fontStyle: FontStyle.italic),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ],
                                )),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _kPrimary : const Color(0xFFE0E0E0)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _kPrimary)),
      ),
    );
  }
}
