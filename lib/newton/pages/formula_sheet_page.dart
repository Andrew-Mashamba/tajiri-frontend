// lib/newton/pages/formula_sheet_page.dart
import 'package:flutter/material.dart';
import '../models/newton_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FormulaSheetPage extends StatefulWidget {
  final bool isSwahili;
  const FormulaSheetPage({super.key, this.isSwahili = false});
  @override
  State<FormulaSheetPage> createState() => _FormulaSheetPageState();
}

class _FormulaSheetPageState extends State<FormulaSheetPage>
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
          sw ? 'Karatasi ya fomula' : 'Formula sheet',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabC,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: sw ? 'Hisabati' : 'Math'),
            Tab(text: sw ? 'Fizikia' : 'Physics'),
            Tab(text: sw ? 'Kemia' : 'Chemistry'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabC,
        children: [
          _formulaList(_mathFormulas),
          _formulaList(_physicsFormulas),
          _formulaList(_chemistryFormulas),
        ],
      ),
    );
  }

  Widget _formulaList(List<FormulaEntry> formulas) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: formulas.length,
      itemBuilder: (_, i) {
        final f = formulas[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f.formula,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    color: _kPrimary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                f.description,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Hardcoded formula data (offline-ready) ──────────────────

const _mathFormulas = [
  FormulaEntry(
    name: 'Quadratic Formula',
    formula: 'x = (-b \u00B1 \u221A(b\u00B2 - 4ac)) / 2a',
    description: 'Solves ax\u00B2 + bx + c = 0',
  ),
  FormulaEntry(
    name: 'Pythagorean Theorem',
    formula: 'a\u00B2 + b\u00B2 = c\u00B2',
    description: 'Relates sides of a right triangle',
  ),
  FormulaEntry(
    name: 'Area of Circle',
    formula: 'A = \u03C0r\u00B2',
    description: 'Area equals pi times radius squared',
  ),
  FormulaEntry(
    name: 'Circumference',
    formula: 'C = 2\u03C0r',
    description: 'Circumference of a circle',
  ),
  FormulaEntry(
    name: 'Slope Formula',
    formula: 'm = (y\u2082 - y\u2081) / (x\u2082 - x\u2081)',
    description: 'Gradient between two points',
  ),
  FormulaEntry(
    name: 'Distance Formula',
    formula: 'd = \u221A((x\u2082-x\u2081)\u00B2 + (y\u2082-y\u2081)\u00B2)',
    description: 'Distance between two points',
  ),
  FormulaEntry(
    name: 'Sine Rule',
    formula: 'a/sin(A) = b/sin(B) = c/sin(C)',
    description: 'Relates sides and angles in any triangle',
  ),
  FormulaEntry(
    name: 'Cosine Rule',
    formula: 'c\u00B2 = a\u00B2 + b\u00B2 - 2ab\u00B7cos(C)',
    description: 'Relates sides and one angle in any triangle',
  ),
  FormulaEntry(
    name: 'Logarithm Rules',
    formula: 'log(ab) = log(a) + log(b)\nlog(a/b) = log(a) - log(b)',
    description: 'Product and quotient rules for logarithms',
  ),
  FormulaEntry(
    name: 'Compound Interest',
    formula: 'A = P(1 + r/n)^(nt)',
    description: 'P=principal, r=rate, n=compounds/year, t=years',
  ),
  FormulaEntry(
    name: 'Arithmetic Sequence',
    formula: 'a\u2099 = a\u2081 + (n-1)d\nS\u2099 = n/2(2a\u2081 + (n-1)d)',
    description: 'nth term and sum of arithmetic progression',
  ),
  FormulaEntry(
    name: 'Geometric Sequence',
    formula: 'a\u2099 = a\u2081\u00B7r^(n-1)\nS\u2099 = a\u2081(r\u207F-1)/(r-1)',
    description: 'nth term and sum of geometric progression',
  ),
  FormulaEntry(
    name: 'Binomial Theorem',
    formula: '(a+b)\u207F = \u2211 C(n,k)\u00B7a^(n-k)\u00B7b^k',
    description: 'Expansion of binomial raised to power n',
  ),
  FormulaEntry(
    name: 'Standard Deviation',
    formula: '\u03C3 = \u221A(\u2211(x\u1D62 - \u03BC)\u00B2 / N)',
    description: 'Measure of spread of a data set',
  ),
];

const _physicsFormulas = [
  FormulaEntry(
    name: 'Newton\'s Second Law',
    formula: 'F = ma',
    description: 'Force equals mass times acceleration',
  ),
  FormulaEntry(
    name: 'Equations of Motion',
    formula: 'v = u + at\ns = ut + \u00BDat\u00B2\nv\u00B2 = u\u00B2 + 2as',
    description: 'Linear motion under constant acceleration',
  ),
  FormulaEntry(
    name: 'Kinetic Energy',
    formula: 'KE = \u00BDmv\u00B2',
    description: 'Energy of a moving object',
  ),
  FormulaEntry(
    name: 'Potential Energy',
    formula: 'PE = mgh',
    description: 'Energy due to height in gravitational field',
  ),
  FormulaEntry(
    name: 'Work Done',
    formula: 'W = Fd\u00B7cos(\u03B8)',
    description: 'Work equals force times displacement times cos theta',
  ),
  FormulaEntry(
    name: 'Power',
    formula: 'P = W/t = Fv',
    description: 'Rate of doing work',
  ),
  FormulaEntry(
    name: 'Ohm\'s Law',
    formula: 'V = IR',
    description: 'Voltage equals current times resistance',
  ),
  FormulaEntry(
    name: 'Electric Power',
    formula: 'P = VI = I\u00B2R = V\u00B2/R',
    description: 'Power in electrical circuits',
  ),
  FormulaEntry(
    name: 'Wave Equation',
    formula: 'v = f\u03BB',
    description: 'Wave speed equals frequency times wavelength',
  ),
  FormulaEntry(
    name: 'Pressure',
    formula: 'P = F/A\nP = \u03C1gh',
    description: 'Pressure as force per area; fluid pressure',
  ),
  FormulaEntry(
    name: 'Snell\'s Law',
    formula: 'n\u2081 sin(\u03B8\u2081) = n\u2082 sin(\u03B8\u2082)',
    description: 'Law of refraction for light waves',
  ),
  FormulaEntry(
    name: 'Momentum',
    formula: 'p = mv',
    description: 'Linear momentum equals mass times velocity',
  ),
  FormulaEntry(
    name: 'Gravitational Force',
    formula: 'F = Gm\u2081m\u2082/r\u00B2',
    description: 'Newton\'s law of universal gravitation',
  ),
  FormulaEntry(
    name: 'Coulomb\'s Law',
    formula: 'F = kq\u2081q\u2082/r\u00B2',
    description: 'Force between two electric charges',
  ),
];

const _chemistryFormulas = [
  FormulaEntry(
    name: 'Ideal Gas Law',
    formula: 'PV = nRT',
    description: 'P=pressure, V=volume, n=moles, R=8.314, T=temperature(K)',
  ),
  FormulaEntry(
    name: 'Boyle\'s Law',
    formula: 'P\u2081V\u2081 = P\u2082V\u2082',
    description: 'Pressure-volume relationship at constant temperature',
  ),
  FormulaEntry(
    name: 'Charles\'s Law',
    formula: 'V\u2081/T\u2081 = V\u2082/T\u2082',
    description: 'Volume-temperature relationship at constant pressure',
  ),
  FormulaEntry(
    name: 'Moles',
    formula: 'n = m/M',
    description: 'Number of moles = mass / molar mass',
  ),
  FormulaEntry(
    name: 'Avogadro\'s Number',
    formula: 'N\u2090 = 6.022 \u00D7 10\u00B2\u00B3 mol\u207B\u00B9',
    description: 'Number of particles in one mole',
  ),
  FormulaEntry(
    name: 'Concentration',
    formula: 'C = n/V (mol/L)',
    description: 'Molarity equals moles divided by volume in liters',
  ),
  FormulaEntry(
    name: 'Dilution',
    formula: 'C\u2081V\u2081 = C\u2082V\u2082',
    description: 'Dilution equation for solutions',
  ),
  FormulaEntry(
    name: 'pH',
    formula: 'pH = -log[H\u207A]',
    description: 'Measure of acidity; pH 7 is neutral',
  ),
  FormulaEntry(
    name: 'Enthalpy Change',
    formula: '\u0394H = \u2211H(products) - \u2211H(reactants)',
    description: 'Heat change in a chemical reaction',
  ),
  FormulaEntry(
    name: 'Rate of Reaction',
    formula: 'Rate = \u0394[concentration] / \u0394t',
    description: 'Change in concentration over time',
  ),
  FormulaEntry(
    name: 'Equilibrium Constant',
    formula: 'Kc = [C]^c[D]^d / [A]^a[B]^b',
    description: 'For reaction aA + bB \u21CC cC + dD',
  ),
  FormulaEntry(
    name: 'Percentage Yield',
    formula: '% yield = (actual/theoretical) \u00D7 100',
    description: 'Efficiency of a chemical reaction',
  ),
];
