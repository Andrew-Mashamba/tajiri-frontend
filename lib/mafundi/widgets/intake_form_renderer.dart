import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F4 #21 — Dynamic intake-form renderer.
///
/// Reads a JSON form schema from `skill_intake_forms.form_schema_json` and
/// builds Material 3 fields. Submit returns the answer map, which the host
/// page POSTs to the appropriate service-request creation endpoint as
/// `intake_form` (column already shipped on `service_requests`).
///
/// Schema shape:
///   { "fields": [
///       {"key":"rooms","label":"How many rooms?","label_sw":"Vyumba vingapi?",
///        "type":"number","required":true},
///       {"key":"flooring","type":"select","options":["Tiles","Concrete"]},
///       {"key":"photos","type":"photos","min":1,"max":5},
///       ...
///   ]}
class IntakeFormRenderer extends StatefulWidget {
  final Map<String, dynamic> schema;
  final void Function(Map<String, dynamic> answers) onSubmit;
  final String? submitLabelEn;
  final String? submitLabelSw;

  const IntakeFormRenderer({
    super.key,
    required this.schema,
    required this.onSubmit,
    this.submitLabelEn,
    this.submitLabelSw,
  });

  @override
  State<IntakeFormRenderer> createState() => _IntakeFormRendererState();
}

class _IntakeFormRendererState extends State<IntakeFormRenderer> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _controllers = {};

  List<Map<String, dynamic>> get _fields {
    final raw = widget.schema['fields'];
    if (raw is List) {
      return raw.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String key) =>
      _controllers.putIfAbsent(key, () => TextEditingController());

  String _label(Map<String, dynamic> f, bool isSw) {
    if (isSw && (f['label_sw'] is String) && (f['label_sw'] as String).isNotEmpty) {
      return f['label_sw'] as String;
    }
    return (f['label'] as String?) ?? (f['key'] as String? ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final fields = _fields;
    if (fields.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          isSw ? 'Hakuna fomu ya kukamilisha.' : 'No intake form configured.',
          style: const TextStyle(color: Color(0xFF666666)),
        ),
      );
    }
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...fields.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildField(f, isSw),
              )),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
              ),
              onPressed: _submit,
              child: Text(
                isSw
                    ? (widget.submitLabelSw ?? 'Endelea')
                    : (widget.submitLabelEn ?? 'Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(Map<String, dynamic> f, bool isSw) {
    final type = (f['type'] as String?) ?? 'text';
    final key = (f['key'] as String?) ?? '';
    final label = _label(f, isSw);
    final required = f['required'] == true;
    switch (type) {
      case 'number':
        return TextFormField(
          controller: _ctrl(key),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (v) {
            if (required && (v == null || v.isEmpty)) {
              return isSw ? 'Inahitajika' : 'Required';
            }
            return null;
          },
          onSaved: (v) {
            if (v != null && v.isNotEmpty) _answers[key] = int.tryParse(v) ?? v;
          },
        );
      case 'textarea':
        return TextFormField(
          controller: _ctrl(key),
          maxLines: 4,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (v) {
            if (required && (v == null || v.isEmpty)) {
              return isSw ? 'Inahitajika' : 'Required';
            }
            return null;
          },
          onSaved: (v) => _answers[key] = v,
        );
      case 'boolean':
        return _BooleanField(
          label: label,
          initial: _answers[key] as bool?,
          onChanged: (v) => _answers[key] = v,
        );
      case 'select':
        final opts = (f['options'] as List?)?.map((e) => e.toString()).toList() ?? const [];
        return _SelectField(
          label: label,
          options: opts,
          initial: _answers[key] as String?,
          onChanged: (v) => _answers[key] = v,
        );
      case 'photos':
        return _PhotosStub(
          label: label,
          min: (f['min'] as int?) ?? 0,
          max: (f['max'] as int?) ?? 5,
          isSw: isSw,
        );
      case 'text':
      default:
        return TextFormField(
          controller: _ctrl(key),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (v) {
            if (required && (v == null || v.isEmpty)) {
              return isSw ? 'Inahitajika' : 'Required';
            }
            return null;
          },
          onSaved: (v) => _answers[key] = v,
        );
    }
  }

  void _submit() {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) return;
    state.save();
    widget.onSubmit(Map<String, dynamic>.from(_answers));
  }
}

class _BooleanField extends StatefulWidget {
  final String label;
  final bool? initial;
  final ValueChanged<bool> onChanged;
  const _BooleanField({
    required this.label,
    required this.initial,
    required this.onChanged,
  });
  @override
  State<_BooleanField> createState() => _BooleanFieldState();
}

class _BooleanFieldState extends State<_BooleanField> {
  late bool _value = widget.initial ?? false;
  @override
  Widget build(BuildContext context) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(widget.label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A))),
        value: _value,
        onChanged: (v) {
          setState(() => _value = v);
          widget.onChanged(v);
        },
      );
}

class _SelectField extends StatefulWidget {
  final String label;
  final List<String> options;
  final String? initial;
  final ValueChanged<String> onChanged;
  const _SelectField({
    required this.label,
    required this.options,
    required this.initial,
    required this.onChanged,
  });
  @override
  State<_SelectField> createState() => _SelectFieldState();
}

class _SelectFieldState extends State<_SelectField> {
  String? _value;
  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: _value,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
        ),
        items: widget.options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => _value = v);
          widget.onChanged(v);
        },
      );
}

class _PhotosStub extends StatelessWidget {
  final String label;
  final int min;
  final int max;
  final bool isSw;
  const _PhotosStub({
    required this.label,
    required this.min,
    required this.max,
    required this.isSw,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.photo_camera_outlined, color: Color(0xFF666666)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  Text(
                    isSw
                        ? 'Pakia picha $min–$max baadaye kwenye ukurasa wa picha.'
                        : 'Upload $min–$max photos in the photo step.',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
