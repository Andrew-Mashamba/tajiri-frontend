import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../mafundi/widgets/intake_form_renderer.dart';
import '../services/engagement_questionnaire_service.dart';

/// Spec F7 #73 — Honeybook-style questionnaire designer.
///
/// Partner-side WYSIWYG: list/add/reorder/edit fields, preview the resulting
/// form using the same `IntakeFormRenderer` used at customer fill time, save
/// to `engagement_questionnaires`.
class QuestionnaireDesignerPage extends StatefulWidget {
  final int userId;
  final int? questionnaireId;

  const QuestionnaireDesignerPage({
    super.key,
    required this.userId,
    this.questionnaireId,
  });

  @override
  State<QuestionnaireDesignerPage> createState() =>
      _QuestionnaireDesignerPageState();
}

class _QuestionnaireDesignerPageState extends State<QuestionnaireDesignerPage> {
  final _titleCtrl = TextEditingController();
  String? _skillCategory;
  bool _isActive = true;
  final List<EngagementQuestionField> _fields = [];
  bool _loading = false;
  bool _previewing = false;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    if (widget.questionnaireId != null) {
      _editingId = widget.questionnaireId;
      _load();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final q = await EngagementQuestionnaireService.show(widget.questionnaireId!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (q != null) {
        _titleCtrl.text = q.title;
        _skillCategory = q.skillCategory;
        _isActive = q.isActive;
        _fields
          ..clear()
          ..addAll(q.fields);
      }
    });
  }

  Future<void> _editField(int? index) async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final f = index == null
        ? EngagementQuestionField(
            key: 'q_${DateTime.now().millisecondsSinceEpoch}',
            label: '',
          )
        : _fields[index];
    final result = await showModalBottomSheet<EngagementQuestionField>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FieldEditor(field: f, isSw: isSw),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _fields.add(result);
      } else {
        _fields[index] = result;
      }
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _toast('Tafadhali weka jina');
      return;
    }
    setState(() => _loading = true);
    final id = await EngagementQuestionnaireService.save(
      userId: widget.userId,
      id: _editingId,
      title: _titleCtrl.text.trim(),
      skillCategory: _skillCategory,
      isActive: _isActive,
      schemaJson: {'fields': _fields.map((f) => f.toJson()).toList()},
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (id != null) {
      _editingId = id;
      _toast('Imehifadhiwa');
    } else {
      _toast('Imeshindikana kuhifadhi');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Tengeneza fomu' : 'Questionnaire designer'),
        actions: [
          IconButton(
            icon: Icon(_previewing
                ? Icons.edit_rounded
                : Icons.remove_red_eye_rounded),
            tooltip: _previewing
                ? (isSw ? 'Hariri' : 'Edit')
                : (isSw ? 'Onesha' : 'Preview'),
            onPressed: () => setState(() => _previewing = !_previewing),
          ),
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: isSw ? 'Hifadhi' : 'Save',
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _previewing
              ? _buildPreview(isSw)
              : _buildEditor(isSw),
      floatingActionButton: _previewing
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1A1A1A),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                isSw ? 'Ongeza swali' : 'Add field',
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () => _editField(null),
            ),
    );
  }

  Widget _buildEditor(bool isSw) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: isSw ? 'Jina la fomu' : 'Form title',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(isSw ? 'Inafanya kazi' : 'Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_fields.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                isSw
                    ? 'Bonyeza "+" kuongeza swali la kwanza.'
                    : 'Tap "+" to add the first field.',
                style: const TextStyle(color: Color(0xFF666666)),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _fields.length,
            onReorder: (oldI, newI) {
              setState(() {
                if (newI > oldI) newI -= 1;
                final f = _fields.removeAt(oldI);
                _fields.insert(newI, f);
              });
            },
            itemBuilder: (_, i) {
              final f = _fields[i];
              return Container(
                key: ValueKey('field_${f.key}'),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: ListTile(
                  leading: Icon(_iconForType(f.type),
                      color: const Color(0xFF666666)),
                  title: Text(
                    f.label.isEmpty ? '(${isSw ? 'hakuna kichwa' : 'no label'})' : f.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  ),
                  subtitle: Text(
                    _typeLabel(f.type, isSw) + (f.required ? ' • ${isSw ? 'lazima' : 'required'}' : ''),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        onPressed: () => _editField(i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        onPressed: () => setState(() => _fields.removeAt(i)),
                      ),
                      const Icon(Icons.drag_handle_rounded,
                          color: Color(0xFFCCCCCC)),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPreview(bool isSw) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _titleCtrl.text.isEmpty
              ? (isSw ? 'Onesho la fomu' : 'Form preview')
              : _titleCtrl.text,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 16),
        IntakeFormRenderer(
          schema: {'fields': _fields.map((f) => f.toJson()).toList()},
          onSubmit: (answers) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isSw
                    ? 'Hii ni onesho tu — majibu yamechukuliwa: ${answers.length}'
                    : 'Preview only — captured ${answers.length} answers'),
              ),
            );
          },
          submitLabelEn: 'Submit (preview)',
          submitLabelSw: 'Tuma (onesho)',
        ),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'number':
        return Icons.numbers_rounded;
      case 'textarea':
        return Icons.notes_rounded;
      case 'boolean':
        return Icons.toggle_on_rounded;
      case 'select':
        return Icons.list_rounded;
      case 'photos':
        return Icons.photo_camera_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }

  String _typeLabel(String type, bool isSw) {
    switch (type) {
      case 'number':
        return isSw ? 'Nambari' : 'Number';
      case 'textarea':
        return isSw ? 'Maandishi marefu' : 'Long text';
      case 'boolean':
        return isSw ? 'Ndio/Hapana' : 'Yes/No';
      case 'select':
        return isSw ? 'Chagua moja' : 'Single select';
      case 'photos':
        return isSw ? 'Picha' : 'Photos';
      default:
        return isSw ? 'Maandishi' : 'Text';
    }
  }
}

class _FieldEditor extends StatefulWidget {
  final EngagementQuestionField field;
  final bool isSw;
  const _FieldEditor({required this.field, required this.isSw});

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _labelSwCtrl;
  late final TextEditingController _optionsCtrl;
  late String _type;
  late bool _required;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.field.label);
    _labelSwCtrl = TextEditingController(text: widget.field.labelSw ?? '');
    _optionsCtrl =
        TextEditingController(text: (widget.field.options ?? []).join('\n'));
    _type = widget.field.type;
    _required = widget.field.required;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _labelSwCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = widget.isSw;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isSw ? 'Hariri swali' : 'Edit field',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                labelText: isSw ? 'Kichwa (Kiingereza)' : 'Label (English)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelSwCtrl,
              decoration: InputDecoration(
                labelText: isSw ? 'Kichwa (Kiswahili)' : 'Label (Swahili)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: isSw ? 'Aina ya jibu' : 'Answer type',
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Text')),
                DropdownMenuItem(value: 'textarea', child: Text('Long text')),
                DropdownMenuItem(value: 'number', child: Text('Number')),
                DropdownMenuItem(value: 'boolean', child: Text('Yes / No')),
                DropdownMenuItem(value: 'select', child: Text('Single select')),
                DropdownMenuItem(value: 'photos', child: Text('Photos')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _type = v);
              },
            ),
            if (_type == 'select') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _optionsCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: isSw
                      ? 'Chaguo (kila moja kwa mstari)'
                      : 'Options (one per line)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isSw ? 'Lazima' : 'Required'),
              value: _required,
              onChanged: (v) => setState(() => _required = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                ),
                onPressed: () {
                  final updated = EngagementQuestionField(
                    key: widget.field.key,
                    label: _labelCtrl.text.trim(),
                    labelSw: _labelSwCtrl.text.trim().isEmpty
                        ? null
                        : _labelSwCtrl.text.trim(),
                    type: _type,
                    required: _required,
                    options: _type == 'select'
                        ? _optionsCtrl.text
                            .split('\n')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList()
                        : null,
                  );
                  Navigator.pop(context, updated);
                },
                child: Text(isSw ? 'Hifadhi swali' : 'Save field'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
