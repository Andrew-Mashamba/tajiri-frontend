// lib/newton/pages/periodic_table_page.dart
import 'package:flutter/material.dart';
import '../models/newton_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PeriodicTablePage extends StatefulWidget {
  final bool isSwahili;
  const PeriodicTablePage({super.key, this.isSwahili = false});
  @override
  State<PeriodicTablePage> createState() => _PeriodicTablePageState();
}

class _PeriodicTablePageState extends State<PeriodicTablePage> {
  String? _selectedCategory;

  static const _categoryColors = {
    'Alkali Metal': Color(0xFFFF6B6B),
    'Alkaline Earth': Color(0xFFFFAB76),
    'Transition Metal': Color(0xFFFFD93D),
    'Post-Transition': Color(0xFFA8E6CF),
    'Metalloid': Color(0xFF88D8B0),
    'Nonmetal': Color(0xFF6EC5FF),
    'Halogen': Color(0xFFB8A9C9),
    'Noble Gas': Color(0xFFDDA0DD),
    'Lanthanide': Color(0xFFFFB347),
    'Actinide': Color(0xFFE8A0BF),
  };

  static const _categorySwahili = {
    'Alkali Metal': 'Metali Alkali',
    'Alkaline Earth': 'Metali ya Ardhi',
    'Transition Metal': 'Metali ya Mpito',
    'Post-Transition': 'Baada ya Mpito',
    'Metalloid': 'Nusu-Metali',
    'Nonmetal': 'Isiyo Metali',
    'Halogen': 'Halogeni',
    'Noble Gas': 'Gesi Bora',
    'Lanthanide': 'Lanthanidi',
    'Actinide': 'Aktinidi',
  };

  Color _colorFor(String category) {
    return _categoryColors[category] ?? Colors.grey.shade300;
  }

  void _showElementDetail(PeriodicElement el) {
    final sw = widget.isSwahili;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              // Element card
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _colorFor(el.category),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${el.atomicNumber}',
                        style: const TextStyle(fontSize: 10, color: _kPrimary)),
                    Text(el.symbol,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(el.name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary)),
              const SizedBox(height: 12),
              _detailRow(sw ? 'Nambari ya Atomu' : 'Atomic number',
                  '${el.atomicNumber}'),
              _detailRow(sw ? 'Uzito wa Atomu' : 'Atomic mass',
                  el.atomicMass.toStringAsFixed(3)),
              _detailRow(sw ? 'Aina' : 'Category', el.category),
              _detailRow(sw ? 'Kundi' : 'Group', '${el.group}'),
              _detailRow(sw ? 'Kipindi' : 'Period', '${el.period}'),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.isSwahili;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Jedwali la elementi' : 'Periodic table',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // Category legend
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _categoryColors.entries.map((e) {
                final isSelected = _selectedCategory == e.key;
                final label = sw
                    ? (_categorySwahili[e.key] ?? e.key)
                    : e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory =
                            _selectedCategory == e.key ? null : e.key;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: e.value.withValues(
                            alpha: isSelected ? 1.0 : 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: _kPrimary, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 9, color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Elements grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.85,
              ),
              itemCount: _elements.length,
              itemBuilder: (_, i) {
                final el = _elements[i];
                final isHighlighted = _selectedCategory == null ||
                    el.category == _selectedCategory;
                return GestureDetector(
                  onTap: () => _showElementDetail(el),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isHighlighted ? 1.0 : 0.25,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _colorFor(el.category),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${el.atomicNumber}',
                            style: const TextStyle(
                                fontSize: 7, color: _kPrimary),
                          ),
                          Text(
                            el.symbol,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            el.name,
                            style: const TextStyle(
                                fontSize: 6, color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

// ─── Elements data (first 36 elements + key heavy ones) ─────

const _elements = [
  PeriodicElement(symbol: 'H', name: 'Hydrogen', atomicNumber: 1, atomicMass: 1.008, category: 'Nonmetal', group: 1, period: 1),
  PeriodicElement(symbol: 'He', name: 'Helium', atomicNumber: 2, atomicMass: 4.003, category: 'Noble Gas', group: 18, period: 1),
  PeriodicElement(symbol: 'Li', name: 'Lithium', atomicNumber: 3, atomicMass: 6.941, category: 'Alkali Metal', group: 1, period: 2),
  PeriodicElement(symbol: 'Be', name: 'Beryllium', atomicNumber: 4, atomicMass: 9.012, category: 'Alkaline Earth', group: 2, period: 2),
  PeriodicElement(symbol: 'B', name: 'Boron', atomicNumber: 5, atomicMass: 10.811, category: 'Metalloid', group: 13, period: 2),
  PeriodicElement(symbol: 'C', name: 'Carbon', atomicNumber: 6, atomicMass: 12.011, category: 'Nonmetal', group: 14, period: 2),
  PeriodicElement(symbol: 'N', name: 'Nitrogen', atomicNumber: 7, atomicMass: 14.007, category: 'Nonmetal', group: 15, period: 2),
  PeriodicElement(symbol: 'O', name: 'Oxygen', atomicNumber: 8, atomicMass: 15.999, category: 'Nonmetal', group: 16, period: 2),
  PeriodicElement(symbol: 'F', name: 'Fluorine', atomicNumber: 9, atomicMass: 18.998, category: 'Halogen', group: 17, period: 2),
  PeriodicElement(symbol: 'Ne', name: 'Neon', atomicNumber: 10, atomicMass: 20.180, category: 'Noble Gas', group: 18, period: 2),
  PeriodicElement(symbol: 'Na', name: 'Sodium', atomicNumber: 11, atomicMass: 22.990, category: 'Alkali Metal', group: 1, period: 3),
  PeriodicElement(symbol: 'Mg', name: 'Magnesium', atomicNumber: 12, atomicMass: 24.305, category: 'Alkaline Earth', group: 2, period: 3),
  PeriodicElement(symbol: 'Al', name: 'Aluminium', atomicNumber: 13, atomicMass: 26.982, category: 'Post-Transition', group: 13, period: 3),
  PeriodicElement(symbol: 'Si', name: 'Silicon', atomicNumber: 14, atomicMass: 28.086, category: 'Metalloid', group: 14, period: 3),
  PeriodicElement(symbol: 'P', name: 'Phosphorus', atomicNumber: 15, atomicMass: 30.974, category: 'Nonmetal', group: 15, period: 3),
  PeriodicElement(symbol: 'S', name: 'Sulfur', atomicNumber: 16, atomicMass: 32.065, category: 'Nonmetal', group: 16, period: 3),
  PeriodicElement(symbol: 'Cl', name: 'Chlorine', atomicNumber: 17, atomicMass: 35.453, category: 'Halogen', group: 17, period: 3),
  PeriodicElement(symbol: 'Ar', name: 'Argon', atomicNumber: 18, atomicMass: 39.948, category: 'Noble Gas', group: 18, period: 3),
  PeriodicElement(symbol: 'K', name: 'Potassium', atomicNumber: 19, atomicMass: 39.098, category: 'Alkali Metal', group: 1, period: 4),
  PeriodicElement(symbol: 'Ca', name: 'Calcium', atomicNumber: 20, atomicMass: 40.078, category: 'Alkaline Earth', group: 2, period: 4),
  PeriodicElement(symbol: 'Sc', name: 'Scandium', atomicNumber: 21, atomicMass: 44.956, category: 'Transition Metal', group: 3, period: 4),
  PeriodicElement(symbol: 'Ti', name: 'Titanium', atomicNumber: 22, atomicMass: 47.867, category: 'Transition Metal', group: 4, period: 4),
  PeriodicElement(symbol: 'V', name: 'Vanadium', atomicNumber: 23, atomicMass: 50.942, category: 'Transition Metal', group: 5, period: 4),
  PeriodicElement(symbol: 'Cr', name: 'Chromium', atomicNumber: 24, atomicMass: 51.996, category: 'Transition Metal', group: 6, period: 4),
  PeriodicElement(symbol: 'Mn', name: 'Manganese', atomicNumber: 25, atomicMass: 54.938, category: 'Transition Metal', group: 7, period: 4),
  PeriodicElement(symbol: 'Fe', name: 'Iron', atomicNumber: 26, atomicMass: 55.845, category: 'Transition Metal', group: 8, period: 4),
  PeriodicElement(symbol: 'Co', name: 'Cobalt', atomicNumber: 27, atomicMass: 58.933, category: 'Transition Metal', group: 9, period: 4),
  PeriodicElement(symbol: 'Ni', name: 'Nickel', atomicNumber: 28, atomicMass: 58.693, category: 'Transition Metal', group: 10, period: 4),
  PeriodicElement(symbol: 'Cu', name: 'Copper', atomicNumber: 29, atomicMass: 63.546, category: 'Transition Metal', group: 11, period: 4),
  PeriodicElement(symbol: 'Zn', name: 'Zinc', atomicNumber: 30, atomicMass: 65.380, category: 'Transition Metal', group: 12, period: 4),
  PeriodicElement(symbol: 'Ga', name: 'Gallium', atomicNumber: 31, atomicMass: 69.723, category: 'Post-Transition', group: 13, period: 4),
  PeriodicElement(symbol: 'Ge', name: 'Germanium', atomicNumber: 32, atomicMass: 72.640, category: 'Metalloid', group: 14, period: 4),
  PeriodicElement(symbol: 'As', name: 'Arsenic', atomicNumber: 33, atomicMass: 74.922, category: 'Metalloid', group: 15, period: 4),
  PeriodicElement(symbol: 'Se', name: 'Selenium', atomicNumber: 34, atomicMass: 78.960, category: 'Nonmetal', group: 16, period: 4),
  PeriodicElement(symbol: 'Br', name: 'Bromine', atomicNumber: 35, atomicMass: 79.904, category: 'Halogen', group: 17, period: 4),
  PeriodicElement(symbol: 'Kr', name: 'Krypton', atomicNumber: 36, atomicMass: 83.798, category: 'Noble Gas', group: 18, period: 4),
  // Period 5 key elements
  PeriodicElement(symbol: 'Rb', name: 'Rubidium', atomicNumber: 37, atomicMass: 85.468, category: 'Alkali Metal', group: 1, period: 5),
  PeriodicElement(symbol: 'Sr', name: 'Strontium', atomicNumber: 38, atomicMass: 87.620, category: 'Alkaline Earth', group: 2, period: 5),
  PeriodicElement(symbol: 'Ag', name: 'Silver', atomicNumber: 47, atomicMass: 107.868, category: 'Transition Metal', group: 11, period: 5),
  PeriodicElement(symbol: 'Sn', name: 'Tin', atomicNumber: 50, atomicMass: 118.710, category: 'Post-Transition', group: 14, period: 5),
  PeriodicElement(symbol: 'I', name: 'Iodine', atomicNumber: 53, atomicMass: 126.904, category: 'Halogen', group: 17, period: 5),
  PeriodicElement(symbol: 'Xe', name: 'Xenon', atomicNumber: 54, atomicMass: 131.293, category: 'Noble Gas', group: 18, period: 5),
  // Period 6 key elements
  PeriodicElement(symbol: 'Cs', name: 'Caesium', atomicNumber: 55, atomicMass: 132.905, category: 'Alkali Metal', group: 1, period: 6),
  PeriodicElement(symbol: 'Ba', name: 'Barium', atomicNumber: 56, atomicMass: 137.327, category: 'Alkaline Earth', group: 2, period: 6),
  PeriodicElement(symbol: 'W', name: 'Tungsten', atomicNumber: 74, atomicMass: 183.840, category: 'Transition Metal', group: 6, period: 6),
  PeriodicElement(symbol: 'Pt', name: 'Platinum', atomicNumber: 78, atomicMass: 195.084, category: 'Transition Metal', group: 10, period: 6),
  PeriodicElement(symbol: 'Au', name: 'Gold', atomicNumber: 79, atomicMass: 196.967, category: 'Transition Metal', group: 11, period: 6),
  PeriodicElement(symbol: 'Hg', name: 'Mercury', atomicNumber: 80, atomicMass: 200.592, category: 'Transition Metal', group: 12, period: 6),
  PeriodicElement(symbol: 'Pb', name: 'Lead', atomicNumber: 82, atomicMass: 207.200, category: 'Post-Transition', group: 14, period: 6),
  PeriodicElement(symbol: 'Rn', name: 'Radon', atomicNumber: 86, atomicMass: 222.018, category: 'Noble Gas', group: 18, period: 6),
  PeriodicElement(symbol: 'U', name: 'Uranium', atomicNumber: 92, atomicMass: 238.029, category: 'Actinide', group: 3, period: 7),
];
