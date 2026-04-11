// lib/skincare/pages/skin_profile_page.dart
import 'package:flutter/material.dart';
import '../models/skincare_models.dart';
import '../services/skincare_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SkinProfilePage extends StatefulWidget {
  final int userId;
  final SkinProfile? existingProfile;
  const SkinProfilePage({super.key, required this.userId, this.existingProfile});
  @override
  State<SkinProfilePage> createState() => _SkinProfilePageState();
}

class _SkinProfilePageState extends State<SkinProfilePage> {
  final SkincareService _service = SkincareService();

  SkinType _selectedType = SkinType.normal;
  final Set<SkinConcern> _selectedConcerns = {};
  ClimateZone _selectedClimate = ClimateZone.bara;
  String _selectedBudget = 'wastani';
  bool _isSaving = false;

  final List<String> _budgetOptions = ['chini', 'wastani', 'juu'];
  final Map<String, String> _budgetLabels = {
    'chini': 'Chini (< TZS 20,000/mwezi)',
    'wastani': 'Wastani (TZS 20,000 - 50,000)',
    'juu': 'Juu (> TZS 50,000)',
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      final p = widget.existingProfile!;
      _selectedType = p.skinType;
      _selectedConcerns.addAll(p.concerns);
      _selectedClimate = p.climateZone;
      _selectedBudget = p.budget ?? 'wastani';
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final result = await _service.saveSkinProfile(
      userId: widget.userId,
      skinType: _selectedType,
      concerns: _selectedConcerns.toList(),
      climateZone: _selectedClimate,
      budget: _selectedBudget,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profaili imehifadhiwa'), backgroundColor: _kPrimary),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kuhifadhi'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profaili ya Ngozi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ─── Skin Type ────────────────────────────────────────
          const Text(
            'Aina ya Ngozi Yako',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chagua aina inayoelezea ngozi yako vizuri zaidi',
            style: TextStyle(fontSize: 12, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          ...SkinType.values.map((type) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SkinTypeCard(
                  type: type,
                  isSelected: _selectedType == type,
                  onTap: () => setState(() => _selectedType = type),
                ),
              )),
          const SizedBox(height: 20),

          // ─── Concerns ─────────────────────────────────────────
          const Text(
            'Matatizo ya Ngozi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chagua matatizo yote yanayokuhusu (unaweza kuchagua zaidi ya moja)',
            style: TextStyle(fontSize: 12, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SkinConcern.values.map((concern) {
              final isSelected = _selectedConcerns.contains(concern);
              return FilterChip(
                label: Text(concern.displayName),
                avatar: Icon(concern.icon, size: 16),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedConcerns.add(concern);
                    } else {
                      _selectedConcerns.remove(concern);
                    }
                  });
                },
                selectedColor: _kPrimary.withValues(alpha: 0.12),
                checkmarkColor: _kPrimary,
                backgroundColor: _kCardBg,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: _kPrimary,
                ),
                side: BorderSide(
                  color: isSelected ? _kPrimary : _kPrimary.withValues(alpha: 0.15),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ─── Climate Zone ─────────────────────────────────────
          const Text(
            'Eneo la Hali ya Hewa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hali ya hewa inathiri jinsi ngozi yako inavyofanya kazi',
            style: TextStyle(fontSize: 12, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: ClimateZone.values.map((zone) {
              final isSelected = _selectedClimate == zone;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: zone != ClimateZone.ziwa ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedClimate = zone),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimary : _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _kPrimary : _kPrimary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            zone == ClimateZone.pwani
                                ? Icons.waves_rounded
                                : zone == ClimateZone.bara
                                    ? Icons.terrain_rounded
                                    : Icons.water_rounded,
                            size: 24,
                            color: isSelected ? Colors.white : _kPrimary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            zone.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : _kPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ─── Budget ───────────────────────────────────────────
          const Text(
            'Bajeti ya Kila Mwezi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          ...List.generate(_budgetOptions.length, (i) {
            final key = _budgetOptions[i];
            final isSelected = _selectedBudget == key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedBudget = key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? _kPrimary.withValues(alpha: 0.05) : _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _kPrimary : _kPrimary.withValues(alpha: 0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isSelected ? _kPrimary : _kSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _budgetLabels[key] ?? key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Hifadhi Profaili',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Skin Type Card ─────────────────────────────────────────────

class _SkinTypeCard extends StatelessWidget {
  final SkinType type;
  final bool isSelected;
  final VoidCallback onTap;
  const _SkinTypeCard({required this.type, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _kPrimary : _kPrimary.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.15) : _kPrimary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, size: 22, color: isSelected ? Colors.white : _kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white60 : _kSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 22,
              color: isSelected ? Colors.white : _kPrimary.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
