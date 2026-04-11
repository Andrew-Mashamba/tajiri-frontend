// lib/hair_nails/pages/hair_profile_page.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';
import '../services/hair_nails_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class HairProfilePage extends StatefulWidget {
  final int userId;
  final HairProfile? existingProfile;
  const HairProfilePage({super.key, required this.userId, this.existingProfile});
  @override
  State<HairProfilePage> createState() => _HairProfilePageState();
}

class _HairProfilePageState extends State<HairProfilePage> {
  final HairNailsService _service = HairNailsService();

  late HairType _selectedType;
  late Porosity _selectedPorosity;
  late HairDensity _selectedDensity;
  late HairState _selectedState;
  String? _scalpCondition;
  final List<String> _selectedGoals = [];
  bool _isSaving = false;

  final List<String> _availableGoals = [
    'Ukuaji wa nywele',
    'Kupunguza kung\'oleka',
    'Unyevu zaidi',
    'Kupunguza ukata',
    'Nywele zenye afya',
    'Kuondoa kemikali',
    'Kukuza dreadlocks',
    'Nywele laini zaidi',
    'Volume zaidi',
    'Kudhibiti dandruff',
  ];

  final List<String> _scalpConditions = [
    'Nzuri',
    'Kavu',
    'Mafuta mengi',
    'Dandruff',
    'Kuwasha',
    'Ngozi nyeti',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _selectedType = p?.hairType ?? HairType.coily4a;
    _selectedPorosity = p?.porosity ?? Porosity.normal;
    _selectedDensity = p?.density ?? HairDensity.medium;
    _selectedState = p?.currentState ?? HairState.natural;
    _scalpCondition = p?.scalpCondition;
    if (p != null) _selectedGoals.addAll(p.goals);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final result = await _service.saveHairProfile(
      userId: widget.userId,
      hairType: _selectedType,
      porosity: _selectedPorosity,
      density: _selectedDensity,
      currentState: _selectedState,
      scalpCondition: _scalpCondition,
      goals: _selectedGoals,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profaili imehifadhiwa'), backgroundColor: _kPrimary));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa kuhifadhi'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Profaili ya Nywele', style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Hair Type Selector
            _sectionTitle('Aina ya Nywele Zako'),
            const SizedBox(height: 8),
            const Text('Watanzania wengi wana nywele aina ya 4A-4C', style: TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(height: 10),
            _buildHairTypeGrid(),
            const SizedBox(height: 20),

            // Hair State
            _sectionTitle('Hali ya Nywele Sasa'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HairState.values.map((s) => _stateChip(s)).toList(),
            ),
            const SizedBox(height: 20),

            // Porosity
            _sectionTitle('Porosity (Unyevushaji)'),
            const SizedBox(height: 6),
            const Text(
              'Jinsi nywele zako zinavyochukua na kushikilia maji. '
              'Jaribu: weka nywele moja kwenye glasi ya maji. Ikizama haraka = high, ikielea = low.',
              style: TextStyle(fontSize: 12, color: _kSecondary, height: 1.3),
            ),
            const SizedBox(height: 10),
            Row(
              children: Porosity.values.map((p) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: p != Porosity.high ? 8 : 0),
                      child: _porosityCard(p),
                    ),
                  )).toList(),
            ),
            if (_selectedPorosity != Porosity.normal) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10)),
                child: Text(_selectedPorosity.tip, style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.3)),
              ),
            ],
            const SizedBox(height: 20),

            // Density
            _sectionTitle('Unene wa Nywele'),
            const SizedBox(height: 10),
            Row(
              children: HairDensity.values.map((d) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: d != HairDensity.thick ? 8 : 0),
                      child: _densityChip(d),
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 20),

            // Scalp Condition
            _sectionTitle('Hali ya Ngozi ya Kichwa'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _scalpConditions.map((c) => ChoiceChip(
                    label: Text(c, style: TextStyle(fontSize: 12, color: _scalpCondition == c ? Colors.white : _kPrimary)),
                    selected: _scalpCondition == c,
                    selectedColor: _kPrimary,
                    backgroundColor: _kCardBg,
                    onSelected: (selected) => setState(() => _scalpCondition = selected ? c : null),
                  )).toList(),
            ),
            const SizedBox(height: 20),

            // Goals
            _sectionTitle('Malengo Yako'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableGoals.map((g) {
                final isSelected = _selectedGoals.contains(g);
                return FilterChip(
                  label: Text(g, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : _kPrimary)),
                  selected: isSelected,
                  selectedColor: _kPrimary,
                  backgroundColor: _kCardBg,
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGoals.add(g);
                      } else {
                        _selectedGoals.remove(g);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: _kSecondary,
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Hifadhi Profaili', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary));
  }

  Widget _buildHairTypeGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.75,
      children: HairType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? _kPrimary : _kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? _kPrimary : _kPrimary.withValues(alpha: 0.1), width: isSelected ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon, size: 28, color: isSelected ? Colors.white : _kPrimary),
                const SizedBox(height: 6),
                Text(type.shortLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : _kPrimary)),
                const SizedBox(height: 2),
                Text(
                  type == HairType.coily4a || type == HairType.coily4b || type == HairType.coily4c ? 'Afrika' : type.displayName.split(' ').first,
                  style: TextStyle(fontSize: 8, color: isSelected ? Colors.white70 : _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _stateChip(HairState state) {
    final isSelected = _selectedState == state;
    return GestureDetector(
      onTap: () => setState(() => _selectedState = state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _kPrimary : _kPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(state.icon, size: 16, color: isSelected ? Colors.white : _kPrimary),
            const SizedBox(width: 6),
            Text(state.displayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : _kPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _porosityCard(Porosity porosity) {
    final isSelected = _selectedPorosity == porosity;
    return GestureDetector(
      onTap: () => setState(() => _selectedPorosity = porosity),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _kPrimary : _kPrimary.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(
              porosity == Porosity.low ? Icons.water_drop_outlined : porosity == Porosity.normal ? Icons.water_drop_rounded : Icons.opacity_rounded,
              size: 22,
              color: isSelected ? Colors.white : _kPrimary,
            ),
            const SizedBox(height: 4),
            Text(porosity.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : _kPrimary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _densityChip(HairDensity density) {
    final isSelected = _selectedDensity == density;
    return GestureDetector(
      onTap: () => setState(() => _selectedDensity = density),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _kPrimary : _kPrimary.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Text(density.displayName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : _kPrimary)),
        ),
      ),
    );
  }
}
