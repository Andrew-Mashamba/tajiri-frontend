// lib/newton/pages/physics_tools_page.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PhysicsToolsPage extends StatefulWidget {
  final bool isSwahili;
  const PhysicsToolsPage({super.key, this.isSwahili = false});
  @override
  State<PhysicsToolsPage> createState() => _PhysicsToolsPageState();
}

class _PhysicsToolsPageState extends State<PhysicsToolsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabC;

  @override
  void initState() {
    super.initState();
    _tabC = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabC.dispose();
    super.dispose();
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
          sw ? 'Zana za Fizikia' : 'Physics tools',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabC,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: sw ? 'Fomula' : 'Formulas'),
            Tab(text: sw ? 'Vipimo' : 'Units'),
            Tab(text: sw ? 'Mara kwa mara' : 'Constants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabC,
        children: [
          _buildFormulas(sw),
          _buildUnitConverter(sw),
          _buildConstants(sw),
        ],
      ),
    );
  }

  // ── Formulas tab ────────────────────────────────────────────

  Widget _buildFormulas(bool sw) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(sw ? 'Mwendo (Kinematics)' : 'Kinematics', Icons.directions_run_rounded),
        _formulaCard('v = u + at',
            sw ? 'Kasi ya mwisho = kasi ya awali + kuongeza kasi × muda' : 'Final velocity = initial velocity + acceleration × time'),
        _formulaCard('s = ut + ½at²',
            sw ? 'Umbali = kasi ya awali × muda + ½ × kuongeza kasi × muda²' : 'Displacement = initial velocity × time + ½ × acceleration × time²'),
        _formulaCard('v² = u² + 2as',
            sw ? 'Kasi ya mwisho² = kasi ya awali² + 2 × kuongeza kasi × umbali' : 'Final velocity² = initial velocity² + 2 × acceleration × displacement'),
        _formulaCard('s = (u + v)t / 2',
            sw ? 'Umbali = wastani wa kasi × muda' : 'Displacement = average velocity × time'),

        const SizedBox(height: 16),
        _sectionHeader(sw ? 'Nguvu (Forces)' : 'Forces', Icons.bolt_rounded),
        _formulaCard('F = ma',
            sw ? 'Nguvu = misa × kuongeza kasi' : 'Force = mass × acceleration'),
        _formulaCard('W = mg',
            sw ? 'Uzito = misa × mvuto wa ardhi (g = 9.81 m/s²)' : 'Weight = mass × gravitational field strength (g = 9.81 m/s²)'),
        _formulaCard('F = μN',
            sw ? 'Nguvu ya msuguano = mgawo wa msuguano × nguvu ya kawaida' : 'Friction force = coefficient of friction × normal force'),
        _formulaCard('F = kx',
            sw ? "Sheria ya Hooke: nguvu ya chemchemi = mara kwa mara ya spring × upanuzi" : "Hooke's law: spring force = spring constant × extension"),
        _formulaCard('p = mv',
            sw ? 'Kasi ya mwendo = misa × kasi' : 'Momentum = mass × velocity'),

        const SizedBox(height: 16),
        _sectionHeader(sw ? 'Nishati (Energy)' : 'Energy', Icons.flash_on_rounded),
        _formulaCard('KE = ½mv²',
            sw ? 'Nishati ya kinetic = ½ × misa × kasi²' : 'Kinetic energy = ½ × mass × velocity²'),
        _formulaCard('GPE = mgh',
            sw ? 'Nishati ya mvuto = misa × g × urefu' : 'Gravitational potential energy = mass × g × height'),
        _formulaCard('W = Fd cos(θ)',
            sw ? 'Kazi = nguvu × umbali × cosine ya pembe' : 'Work done = force × displacement × cos(angle)'),
        _formulaCard('P = W/t = Fv',
            sw ? 'Nguvu ya kufanya kazi = kazi / muda = nguvu × kasi' : 'Power = work done / time = force × velocity'),
        _formulaCard('Efficiency = (useful output / input) × 100%',
            sw ? 'Ufanisi wa mashine' : 'Machine efficiency'),

        const SizedBox(height: 16),
        _sectionHeader(sw ? 'Mawimbi (Waves)' : 'Waves', Icons.waves_rounded),
        _formulaCard('v = fλ',
            sw ? 'Kasi ya wimbi = masafa × urefu wa wimbi' : 'Wave speed = frequency × wavelength'),
        _formulaCard('T = 1/f',
            sw ? 'Kipindi = 1 / masafa' : 'Period = 1 / frequency'),
        _formulaCard('n₁sin(θ₁) = n₂sin(θ₂)',
            sw ? "Sheria ya Snell kwa kuakisi nuru" : "Snell's law for refraction"),
        _formulaCard('v_sound ≈ 340 m/s (air, 20°C)',
            sw ? 'Kasi ya sauti hewani kwa joto la kawaida' : 'Speed of sound in air at room temperature'),
      ],
    );
  }

  // ── Unit converter tab ──────────────────────────────────────

  Widget _buildUnitConverter(bool sw) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(sw ? 'Umbali' : 'Length', Icons.straighten_rounded),
        _conversionCard('1 km', '= 1000 m', sw ? 'kilomita hadi mita' : 'kilometres to metres'),
        _conversionCard('1 m', '= 100 cm = 1000 mm', sw ? 'mita hadi sentimita/milimita' : 'metres to centimetres/millimetres'),
        _conversionCard('1 mile', '≈ 1.609 km', sw ? 'maili hadi kilomita' : 'miles to kilometres'),
        _conversionCard('1 inch', '= 2.54 cm', sw ? 'inchi hadi sentimita' : 'inches to centimetres'),

        const SizedBox(height: 16),
        _sectionHeader(sw ? 'Uzito / Misa' : 'Mass / Weight', Icons.scale_rounded),
        _conversionCard('1 kg', '= 1000 g', sw ? 'kilogramu hadi gramu' : 'kilograms to grams'),
        _conversionCard('1 tonne', '= 1000 kg', sw ? 'tani hadi kilogramu' : 'tonnes to kilograms'),
        _conversionCard('Weight (N)', '= mass (kg) × 9.81', sw ? 'Uzito kutoka kwa misa' : 'Weight from mass'),

        const SizedBox(height: 16),
        _sectionHeader(sw ? 'Muda' : 'Time', Icons.timer_rounded),
        _conversionCard('1 hr', '= 3600 s = 60 min', sw ? 'saa hadi sekunde' : 'hours to seconds'),
        _conversionCard('1 min', '= 60 s', sw ? 'dakika hadi sekunde' : 'minutes to seconds'),
        _conversionCard('1 day', '= 86,400 s', sw ? 'siku hadi sekunde' : 'days to seconds'),

        const SizedBox(height: 16),
        _sectionHeader(sw ? 'Joto' : 'Temperature', Icons.thermostat_rounded),
        _conversionCard('°C to K', 'K = °C + 273.15', sw ? 'Celsius hadi Kelvin' : 'Celsius to Kelvin'),
        _conversionCard('°C to °F', '°F = (°C × 9/5) + 32', sw ? 'Celsius hadi Fahrenheit' : 'Celsius to Fahrenheit'),

        const SizedBox(height: 16),
        _sectionHeader(sw ? 'Nishati' : 'Energy', Icons.electric_bolt_rounded),
        _conversionCard('1 J', '= 1 N·m = 1 kg·m²/s²', sw ? 'Joule kwa maneno mengine' : 'Joule in other terms'),
        _conversionCard('1 kWh', '= 3,600,000 J = 3.6 MJ', sw ? 'kilowati-saa hadi joule' : 'kilowatt-hours to joules'),
        _conversionCard('1 eV', '≈ 1.602 × 10⁻¹⁹ J', sw ? 'elektroni-volt hadi joule' : 'electron-volt to joules'),

        const SizedBox(height: 16),
        _sectionHeader(sw ? 'Shinikizo' : 'Pressure', Icons.compress_rounded),
        _conversionCard('1 atm', '= 101,325 Pa = 101.3 kPa', sw ? 'angahewa hadi pascal' : 'atmospheres to pascals'),
        _conversionCard('1 bar', '= 100,000 Pa', sw ? 'baa hadi pascal' : 'bar to pascals'),
        _conversionCard('1 mmHg', '≈ 133.3 Pa', sw ? 'milimita ya zebaki hadi pascal' : 'mmHg to pascals'),
      ],
    );
  }

  // ── Constants tab ───────────────────────────────────────────

  Widget _buildConstants(bool sw) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(sw ? 'Mara kwa mara za kimsingi' : 'Fundamental constants', Icons.science_rounded),
        _constantCard('g', '9.81 m/s²',
            sw ? 'Mvuto wa ardhi (Tanzania / uso wa ardhi)' : 'Gravitational field strength (Earth surface)'),
        _constantCard('G', '6.674 × 10⁻¹¹ N·m²/kg²',
            sw ? 'Mara kwa mara ya mvuto wa ulimwengu' : 'Universal gravitational constant'),
        _constantCard('c', '3.00 × 10⁸ m/s',
            sw ? 'Kasi ya nuru katika utupu' : 'Speed of light in vacuum'),
        _constantCard('h', '6.626 × 10⁻³⁴ J·s',
            sw ? 'Mara kwa mara ya Planck' : "Planck's constant"),
        _constantCard('Nₐ', '6.022 × 10²³ mol⁻¹',
            sw ? 'Nambari ya Avogadro' : "Avogadro's number"),
        _constantCard('R', '8.314 J/(mol·K)',
            sw ? 'Mara kwa mara ya gesi ya ulimwengu' : 'Universal gas constant'),
        _constantCard('k', '1.381 × 10⁻²³ J/K',
            sw ? 'Mara kwa mara ya Boltzmann' : "Boltzmann's constant"),
        _constantCard('e', '1.602 × 10⁻¹⁹ C',
            sw ? 'Chaji ya elektroni' : 'Elementary charge (electron)'),
        _constantCard('mₑ', '9.109 × 10⁻³¹ kg',
            sw ? 'Misa ya elektroni' : 'Electron mass'),
        _constantCard('mₚ', '1.673 × 10⁻²⁷ kg',
            sw ? 'Misa ya protoni' : 'Proton mass'),
        _constantCard('ε₀', '8.854 × 10⁻¹² F/m',
            sw ? 'Usimamizi wa umeme wa utupu' : 'Permittivity of free space'),
        _constantCard('μ₀', '4π × 10⁻⁷ T·m/A',
            sw ? 'Upenyezaji wa magnetic wa utupu' : 'Permeability of free space'),

        const SizedBox(height: 16),
        _sectionHeader(sw ? 'Mara kwa mara za wimbi na sauti' : 'Wave & sound constants', Icons.graphic_eq_rounded),
        _constantCard('v_sound', '≈ 340 m/s',
            sw ? 'Kasi ya sauti hewani (20°C)' : 'Speed of sound in air (20°C)'),
        _constantCard('v_sound (water)', '≈ 1480 m/s',
            sw ? 'Kasi ya sauti ndani ya maji' : 'Speed of sound in water'),
        _constantCard('Standard temp', '273.15 K = 0°C',
            sw ? 'Joto la kawaida (STP)' : 'Standard temperature (STP)'),
        _constantCard('Standard pressure', '101.325 kPa',
            sw ? 'Shinikizo la kawaida (STP)' : 'Standard pressure (STP)'),
      ],
    );
  }

  // ── Widget helpers ──────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _formulaCard(String formula, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formula,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: _kPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _conversionCard(String from, String to, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(
            from,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              to,
              style: const TextStyle(
                fontSize: 13,
                color: _kSecondary,
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _constantCard(String symbol, String value, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              symbol,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kPrimary,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
