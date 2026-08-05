import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons/heroicons.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kError = Color(0xFFDC2626);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

/// Create a new shop ad campaign — objective, creative, targeting, budget.
class CreateShopAdScreen extends StatefulWidget {
  const CreateShopAdScreen({super.key});

  @override
  State<CreateShopAdScreen> createState() => _CreateShopAdScreenState();
}

class _CreateShopAdScreenState extends State<CreateShopAdScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _objective = 'Awareness';
  String _audience = 'All buyers';
  int _durationDays = 7;
  bool _submitting = false;

  static const _objectives = [
    'Awareness',
    'Traffic',
    'Sales',
    'Engagement',
  ];

  static const _audiences = [
    'All buyers',
    'Nearby buyers (5 km)',
    'Repeat customers',
    'New visitors',
    'Category browsers',
  ];

  static const _durations = [3, 7, 14, 30];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _budgetCtrl.dispose();
    _headlineCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ad campaign created successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _kSurface,
            elevation: 0,
            pinned: true,
            centerTitle: false,
            title: const Text(
              'Create Ad',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kText),
            ),
            iconTheme: const IconThemeData(color: _kText),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormSection(
                      title: 'Campaign Details',
                      children: [
                        _field(
                          controller: _nameCtrl,
                          label: 'Campaign Name',
                          hint: 'e.g. May Flash Sale Campaign',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Enter a campaign name'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        _DropdownField<String>(
                          label: 'Objective',
                          value: _objective,
                          items: _objectives,
                          onChanged: (v) =>
                              setState(() => _objective = v!),
                        ),
                      ],
                    ),

                    _FormSection(
                      title: 'Ad Creative',
                      children: [
                        // Image picker placeholder
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: _kSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _kDivider, width: 1.5,
                                  style: BorderStyle.solid),
                            ),
                            child: const Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                HeroIcon(HeroIcons.photo,
                                    style: HeroIconStyle.outline,
                                    color: _kFaint,
                                    size: 36),
                                SizedBox(height: 8),
                                Text('Tap to add image',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: _kMuted)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _field(
                          controller: _headlineCtrl,
                          label: 'Headline',
                          hint: 'e.g. Shop the best deals near you',
                          maxLength: 60,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Enter a headline'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          controller: _descCtrl,
                          label: 'Description',
                          hint: 'Brief ad copy (optional)',
                          maxLines: 3,
                          maxLength: 150,
                        ),
                      ],
                    ),

                    _FormSection(
                      title: 'Targeting',
                      children: [
                        _DropdownField<String>(
                          label: 'Audience',
                          value: _audience,
                          items: _audiences,
                          onChanged: (v) =>
                              setState(() => _audience = v!),
                        ),
                      ],
                    ),

                    _FormSection(
                      title: 'Budget & Schedule',
                      children: [
                        _field(
                          controller: _budgetCtrl,
                          label: 'Daily Budget (TZS)',
                          hint: 'e.g. 1000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter a daily budget';
                            }
                            final n = int.tryParse(v);
                            if (n == null || n < 100) {
                              return 'Minimum budget is TZS 100';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text('Duration',
                            style: TextStyle(
                                fontSize: 13, color: _kMuted)),
                        const SizedBox(height: 8),
                        Row(
                          children: _durations.map((d) {
                            final sel = _durationDays == d;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _durationDays = d),
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      right: 6),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? _kText
                                        : _kSurface,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color: sel
                                          ? _kText
                                          : _kDivider,
                                    ),
                                  ),
                                  child: Column(children: [
                                    Text(
                                      '$d',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.bold,
                                          color: sel
                                              ? Colors.white
                                              : _kText),
                                    ),
                                    Text(
                                      d == 1 ? 'day' : 'days',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: sel
                                              ? Colors.white70
                                              : _kFaint),
                                    ),
                                  ]),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kText,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Text('Launch Campaign',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w600)),
                        ),
                      ),
                    ),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        errorStyle: const TextStyle(color: _kError, fontSize: 11),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kText)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [_kCardShadow],
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children),
        ),
      ]),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
    );
  }
}
