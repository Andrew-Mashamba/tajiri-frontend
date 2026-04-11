// lib/my_family/pages/add_member_page.dart
import 'package:flutter/material.dart';
import '../models/my_family_models.dart';
import '../services/my_family_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AddMemberPage extends StatefulWidget {
  final int userId;
  final FamilyMember? existingMember;

  const AddMemberPage({
    super.key,
    required this.userId,
    this.existingMember,
  });

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final MyFamilyService _service = MyFamilyService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _nhifCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _linkPhoneCtrl;
  final TextEditingController _allergyCtrl = TextEditingController();
  final TextEditingController _conditionCtrl = TextEditingController();

  Relationship _relationship = Relationship.child;
  Gender _gender = Gender.male;
  BloodType _bloodType = BloodType.unknown;
  DateTime? _dob;
  List<String> _allergies = [];
  List<String> _conditions = [];
  bool _isSaving = false;
  bool _isSearching = false;
  int? _linkedUserId;
  String? _linkedUserName;

  bool get _isEditing => widget.existingMember != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existingMember;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _nhifCtrl = TextEditingController(text: m?.nhifNumber ?? '');
    _phoneCtrl = TextEditingController(text: m?.emergencyPhone ?? '');
    _linkPhoneCtrl = TextEditingController();

    if (m != null) {
      _relationship = m.relationship;
      _gender = m.gender;
      _bloodType = m.bloodType;
      _dob = m.dateOfBirth;
      _allergies = List.from(m.allergies);
      _conditions = List.from(m.chronicConditions);
      _linkedUserId = m.userId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nhifCtrl.dispose();
    _phoneCtrl.dispose();
    _linkPhoneCtrl.dispose();
    _allergyCtrl.dispose();
    _conditionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Chagua Tarehe ya Kuzaliwa',
      cancelText: 'Ghairi',
      confirmText: 'Chagua',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _kPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _searchUser() async {
    final phone = _linkPhoneCtrl.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isSearching = true);
    final result = await _service.searchUserByPhone(phone);
    if (mounted) {
      setState(() => _isSearching = false);
      if (result.success && result.data != null) {
        setState(() {
          _linkedUserId = (result.data!['id'] as num).toInt();
          _linkedUserName = result.data!['name'] as String?;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Amepatikana: ${_linkedUserName ?? phone}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    result.message ?? 'Mtumiaji hajapatikana')),
          );
        }
      }
    }
  }

  void _addAllergy() {
    final text = _allergyCtrl.text.trim();
    if (text.isNotEmpty && !_allergies.contains(text)) {
      setState(() => _allergies.add(text));
      _allergyCtrl.clear();
    }
  }

  void _addCondition() {
    final text = _conditionCtrl.text.trim();
    if (text.isNotEmpty && !_conditions.contains(text)) {
      setState(() => _conditions.add(text));
      _conditionCtrl.clear();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    FamilyResult<FamilyMember> result;

    if (_isEditing) {
      result = await _service.updateMember(
        memberId: widget.existingMember!.id,
        fields: {
          'name': _nameCtrl.text.trim(),
          'relationship': _relationship.name,
          'gender': _gender.name,
          if (_dob != null)
            'date_of_birth': _dob!.toIso8601String().split('T').first,
          'blood_type': _bloodType.displayName,
          'allergies': _allergies,
          'chronic_conditions': _conditions,
          if (_nhifCtrl.text.trim().isNotEmpty)
            'nhif_number': _nhifCtrl.text.trim(),
          if (_phoneCtrl.text.trim().isNotEmpty)
            'emergency_phone': _phoneCtrl.text.trim(),
          if (_linkedUserId != null) 'linked_user_id': _linkedUserId,
        },
      );
    } else {
      result = await _service.addMember(
        userId: widget.userId,
        name: _nameCtrl.text.trim(),
        relationship: _relationship.name,
        gender: _gender.name,
        dateOfBirth: _dob?.toIso8601String().split('T').first,
        bloodType: _bloodType.displayName,
        allergies: _allergies,
        chronicConditions: _conditions,
        nhifNumber: _nhifCtrl.text.trim().isNotEmpty
            ? _nhifCtrl.text.trim()
            : null,
        emergencyPhone: _phoneCtrl.text.trim().isNotEmpty
            ? _phoneCtrl.text.trim()
            : null,
        linkedUserId: _linkedUserId,
      );
    }

    if (mounted) setState(() => _isSaving = false);

    if (result.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Taarifa zimesasishwa'
              : 'Mwanafamilia ameongezwa'),
        ),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kuhifadhi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isEditing ? 'Hariri Mwanafamilia' : 'Ongeza Mwanafamilia',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Basic Info ─────────────────────────────────
            _SectionHeader(title: 'Taarifa za Msingi'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _nameCtrl,
              label: 'Jina Kamili',
              icon: Icons.person_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Jina linahitajika' : null,
            ),
            const SizedBox(height: 12),

            // Relationship dropdown
            _buildDropdown<Relationship>(
              label: 'Uhusiano',
              icon: Icons.people_rounded,
              value: _relationship,
              items: Relationship.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.displayName),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _relationship = v);
              },
            ),
            const SizedBox(height: 12),

            // Gender
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<Gender>(
                    label: 'Jinsia',
                    icon: Icons.wc_rounded,
                    value: _gender,
                    items: Gender.values
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _gender = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // DOB picker
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDob,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: TextEditingController(
                          text: _dob != null
                              ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                              : '',
                        ),
                        label: 'Tarehe ya Kuzaliwa',
                        icon: Icons.cake_rounded,
                        suffixIcon: Icons.calendar_today_rounded,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Health Info ────────────────────────────────
            _SectionHeader(title: 'Taarifa za Afya'),
            const SizedBox(height: 10),

            // Blood type
            _buildDropdown<BloodType>(
              label: 'Kundi la Damu',
              icon: Icons.bloodtype_rounded,
              value: _bloodType,
              items: BloodType.values
                  .map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b.displayName),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _bloodType = v);
              },
            ),
            const SizedBox(height: 12),

            // Allergies
            _buildChipInput(
              controller: _allergyCtrl,
              label: 'Mizio (Allergies)',
              icon: Icons.warning_amber_rounded,
              items: _allergies,
              onAdd: _addAllergy,
              onRemove: (s) => setState(() => _allergies.remove(s)),
            ),
            const SizedBox(height: 12),

            // Chronic conditions
            _buildChipInput(
              controller: _conditionCtrl,
              label: 'Magonjwa ya Kudumu',
              icon: Icons.monitor_heart_rounded,
              items: _conditions,
              onAdd: _addCondition,
              onRemove: (s) => setState(() => _conditions.remove(s)),
            ),
            const SizedBox(height: 12),

            // NHIF
            _buildTextField(
              controller: _nhifCtrl,
              label: 'Namba ya NHIF',
              icon: Icons.badge_rounded,
            ),
            const SizedBox(height: 12),

            // Emergency phone
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Simu ya Dharura',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            // ─── Link TAJIRI Account ───────────────────────
            _SectionHeader(title: 'Unganisha Akaunti ya TAJIRI'),
            const SizedBox(height: 6),
            const Text(
              'Kama mwanafamilia ana akaunti ya TAJIRI, unganisha kwa namba ya simu.',
              style: TextStyle(fontSize: 12, color: _kSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _linkPhoneCtrl,
                    label: 'Namba ya Simu',
                    icon: Icons.search_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSearching ? null : _searchUser,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Tafuta'),
                  ),
                ),
              ],
            ),
            if (_linkedUserId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ameunganishwa: ${_linkedUserName ?? 'Mtumiaji #$_linkedUserId'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _linkedUserId = null;
                        _linkedUserName = null;
                      }),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: _kSecondary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ─── Save Button ────────────────────────────────
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Hifadhi Mabadiliko' : 'Ongeza Mwanafamilia',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Form Builders ─────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    IconData? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _kPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        prefixIcon: Icon(icon, size: 20, color: _kSecondary),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 18, color: _kSecondary)
            : null,
        filled: true,
        fillColor: _kCardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: _kPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        prefixIcon: Icon(icon, size: 20, color: _kSecondary),
        filled: true,
        fillColor: _kCardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildChipInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> items,
    required VoidCallback onAdd,
    required ValueChanged<String> onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller,
                label: label,
                icon: icon,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              width: 48,
              child: Material(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(10),
                  child: const Icon(Icons.add_rounded,
                      color: _kPrimary, size: 22),
                ),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items
                .map((item) => Chip(
                      label: Text(item,
                          style: const TextStyle(
                              fontSize: 12, color: _kPrimary)),
                      deleteIcon: const Icon(Icons.close_rounded,
                          size: 14, color: _kSecondary),
                      onDeleted: () => onRemove(item),
                      backgroundColor: _kPrimary.withValues(alpha: 0.06),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _kPrimary,
      ),
    );
  }
}
