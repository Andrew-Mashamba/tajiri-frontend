import 'package:flutter/material.dart';

import '../services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);

enum _NeedType { oneOff, recurring }
enum _MealType { breakfast, lunch, dinner, snack }
enum _DeliveryMode { pickup, delivery, either }

const List<String> _kDayLabels = ['Jtatu', 'Jnne', 'Jtano', 'Ijumaa', 'Jmosi', 'Jpili', 'Jumamosi'];
const List<String> _kDayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _kDietOptions = ['halal', 'no_pork', 'vegetarian', 'vegan', 'gluten_free', 'soft_food'];

String _dietLabel(String tag) {
  switch (tag) {
    case 'halal': return 'Halal';
    case 'no_pork': return 'Hakuna Nguruwe';
    case 'vegetarian': return 'Mboga Mboga';
    case 'vegan': return 'Vegan';
    case 'gluten_free': return 'Bila Gluten';
    case 'soft_food': return 'Laini';
    default: return tag;
  }
}

String _mealLabel(_MealType m) {
  switch (m) {
    case _MealType.breakfast: return 'Kifungua Kinywa';
    case _MealType.lunch: return 'Chakula cha Mchana';
    case _MealType.dinner: return 'Chakula cha Jioni';
    case _MealType.snack: return 'Vitafunio';
  }
}

String _mealApi(_MealType m) {
  switch (m) {
    case _MealType.breakfast: return 'breakfast';
    case _MealType.lunch: return 'lunch';
    case _MealType.dinner: return 'dinner';
    case _MealType.snack: return 'snack';
  }
}

String _deliveryLabel(_DeliveryMode d) {
  switch (d) {
    case _DeliveryMode.pickup: return 'Tutakuja kuchukua';
    case _DeliveryMode.delivery: return 'Mfadhili aletee';
    case _DeliveryMode.either: return 'Yoyote inafaa';
  }
}

String _deliveryApi(_DeliveryMode d) {
  switch (d) {
    case _DeliveryMode.pickup: return 'pickup';
    case _DeliveryMode.delivery: return 'delivery';
    case _DeliveryMode.either: return 'either';
  }
}

class PostNeedPage extends StatefulWidget {
  final int orgId;
  final int userId;
  const PostNeedPage({super.key, required this.orgId, required this.userId});

  @override
  State<PostNeedPage> createState() => _PostNeedPageState();
}

class _PostNeedPageState extends State<PostNeedPage> {
  final FoodService _service = FoodService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _portionsController = TextEditingController(text: '10');
  final _durationController = TextEditingController(text: '4');

  _NeedType _type = _NeedType.oneOff;
  _MealType _meal = _MealType.lunch;
  _DeliveryMode _delivery = _DeliveryMode.either;
  final Set<int> _days = <int>{};
  final Set<String> _diet = <String>{};
  DateTime? _dueDate;
  bool _alwaysOn = false;
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _portionsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kPrimary)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dueDate = d);
  }

  String? _validate() {
    if (_titleController.text.trim().isEmpty) return 'Weka kichwa cha hitaji';
    final portions = int.tryParse(_portionsController.text.trim()) ?? 0;
    if (portions <= 0) return 'Weka idadi sahihi ya milo';
    if (_type == _NeedType.oneOff && _dueDate == null) return 'Chagua tarehe ya hitaji';
    if (_type == _NeedType.recurring && _days.isEmpty) return 'Chagua siku angalau moja';
    if (_type == _NeedType.recurring && !_alwaysOn) {
      final w = int.tryParse(_durationController.text.trim()) ?? 0;
      if (w <= 0) return 'Weka idadi sahihi ya wiki';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final res = await _service.createBeneficiaryNeed(
      orgId: widget.orgId,
      userId: widget.userId,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      portionsNeeded: int.parse(_portionsController.text.trim()),
      dueDate: _type == _NeedType.oneOff ? _dueDate : null,
      needType: _type == _NeedType.recurring ? 'recurring' : 'one_off',
      mealType: _mealApi(_meal),
      daysOfWeek: _type == _NeedType.recurring ? (_days.toList()..sort()) : null,
      deliveryMode: _deliveryApi(_delivery),
      dietaryConstraints: _diet.toList(),
      durationWeeks: _type == _NeedType.recurring && !_alwaysOn
          ? int.tryParse(_durationController.text.trim())
          : null,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Hitaji limetumwa.')));
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text('Tuma Hitaji', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _sectionLabel('Aina ya hitaji'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _typeButton(_NeedType.oneOff, 'Mara Moja', Icons.event_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _typeButton(_NeedType.recurring, 'Kurudiwa', Icons.repeat_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Aina ya mlo'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _MealType.values.map((m) {
              final sel = _meal == m;
              return ChoiceChip(
                label: Text(_mealLabel(m), style: TextStyle(fontSize: 12, color: sel ? Colors.white : _kPrimary)),
                selected: sel,
                onSelected: (_) => setState(() => _meal = m),
                backgroundColor: _kCardBg,
                selectedColor: _kPrimary,
                side: BorderSide(color: _kPrimary.withValues(alpha: sel ? 0 : 0.12)),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Kichwa'),
          const SizedBox(height: 6),
          _textField(_titleController, hint: 'mfano: Chakula cha watoto 20'),
          const SizedBox(height: 14),
          _sectionLabel('Maelezo (hiari)'),
          const SizedBox(height: 6),
          _textField(_descController, hint: '"20 watoto, hakuna nguruwe, laini ikiwezekana"', maxLines: 3),
          const SizedBox(height: 14),
          _sectionLabel('Milo inayohitajika'),
          const SizedBox(height: 6),
          _textField(_portionsController, hint: '10', keyboard: TextInputType.number),
          const SizedBox(height: 16),
          if (_type == _NeedType.oneOff) ...[
            _sectionLabel('Tarehe'),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 16, color: _kPrimary),
              label: Text(
                _dueDate == null
                    ? 'Chagua tarehe'
                    : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: _kPrimary.withValues(alpha: 0.15)),
              ),
            ),
          ] else ...[
            _sectionLabel('Siku za juma'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(7, (i) {
                final sel = _days.contains(i);
                return FilterChip(
                  label: Text(_kDayLabels[i], style: TextStyle(fontSize: 12, color: sel ? Colors.white : _kPrimary)),
                  tooltip: _kDayShort[i],
                  selected: sel,
                  onSelected: (v) => setState(() => v ? _days.add(i) : _days.remove(i)),
                  backgroundColor: _kCardBg,
                  selectedColor: _kPrimary,
                  side: BorderSide(color: _kPrimary.withValues(alpha: sel ? 0 : 0.12)),
                  showCheckmark: false,
                );
              }),
            ),
            const SizedBox(height: 14),
            _sectionLabel('Muda'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: _alwaysOn ? 0.4 : 1,
                    child: _textField(
                      _durationController,
                      hint: 'Wiki',
                      keyboard: TextInputType.number,
                      enabled: !_alwaysOn,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: Text('Bila mwisho', style: TextStyle(fontSize: 12, color: _alwaysOn ? Colors.white : _kPrimary)),
                  selected: _alwaysOn,
                  onSelected: (v) => setState(() => _alwaysOn = v),
                  backgroundColor: _kCardBg,
                  selectedColor: _kPrimary,
                  side: BorderSide(color: _kPrimary.withValues(alpha: _alwaysOn ? 0 : 0.12)),
                  showCheckmark: false,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _sectionLabel('Upokeaji'),
          const SizedBox(height: 6),
          Column(
            children: _DeliveryMode.values.map((d) {
              final sel = _delivery == d;
              return InkWell(
                onTap: () => setState(() => _delivery = d),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        sel ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: sel ? _kPrimary : _kSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(_deliveryLabel(d), style: const TextStyle(fontSize: 13, color: _kPrimary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _sectionLabel('Vikwazo vya lishe (hiari)'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _kDietOptions.map((tag) {
              final sel = _diet.contains(tag);
              return FilterChip(
                label: Text(_dietLabel(tag), style: TextStyle(fontSize: 12, color: sel ? Colors.white : _kPrimary)),
                selected: sel,
                onSelected: (v) => setState(() => v ? _diet.add(tag) : _diet.remove(tag)),
                backgroundColor: _kCardBg,
                selectedColor: _kPrimary,
                side: BorderSide(color: _kPrimary.withValues(alpha: sel ? 0 : 0.12)),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _previewCard(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton(
          onPressed: _busy ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Tuma hitaji', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _typeButton(_NeedType t, String label, IconData icon) {
    final sel = _type == t;
    return OutlinedButton.icon(
      onPressed: () => setState(() => _type = t),
      icon: Icon(icon, size: 18, color: sel ? Colors.white : _kPrimary),
      label: Text(label, style: TextStyle(color: sel ? Colors.white : _kPrimary, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        backgroundColor: sel ? _kPrimary : _kCardBg,
        side: BorderSide(color: _kPrimary.withValues(alpha: sel ? 0 : 0.18)),
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }

  Widget _textField(
    TextEditingController c, {
    required String hint,
    int maxLines = 1,
    TextInputType? keyboard,
    bool enabled = true,
  }) {
    return TextField(
      controller: c,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: _kPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kSecondary, fontSize: 12),
        filled: true,
        fillColor: _kCardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kSecondary,
          letterSpacing: 0.6,
        ),
      );

  Widget _previewCard() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return const SizedBox.shrink();
    final portions = int.tryParse(_portionsController.text.trim()) ?? 0;
    final schedule = _type == _NeedType.oneOff
        ? (_dueDate == null
            ? 'Tarehe: —'
            : 'Tarehe: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}')
        : (_days.isEmpty
            ? 'Siku: —'
            : 'Siku: ${(_days.toList()..sort()).map((i) => _kDayShort[i]).join(', ')}'
                '${_alwaysOn ? ' · bila mwisho' : ' · ${_durationController.text.trim()} wiki'}');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined, color: _kAccent, size: 14),
              const SizedBox(width: 6),
              const Text('ONYESHO', style: TextStyle(color: _kAccent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 4),
          Text(
            '$portions milo · ${_mealLabel(_meal)} · ${_deliveryLabel(_delivery)}',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          const SizedBox(height: 2),
          Text(schedule, style: const TextStyle(fontSize: 12, color: _kSecondary)),
          if (_diet.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _diet.map(_dietLabel).join(' • '),
              style: const TextStyle(fontSize: 11, color: _kSecondary, fontStyle: FontStyle.italic),
            ),
          ],
          if (_descController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_descController.text.trim(), style: const TextStyle(fontSize: 12, color: _kPrimary)),
          ],
        ],
      ),
    );
  }
}

