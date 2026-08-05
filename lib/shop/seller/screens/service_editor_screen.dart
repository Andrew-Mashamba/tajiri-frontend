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

/// Create or edit a service listing.
class ServiceEditorScreen extends StatefulWidget {
  final int? serviceId;

  const ServiceEditorScreen({super.key, this.serviceId});

  @override
  State<ServiceEditorScreen> createState() => _ServiceEditorScreenState();
}

class _ServiceEditorScreenState extends State<ServiceEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  String _deliveryMode = 'On-site';
  bool _loading = false;
  bool _saving = false;

  bool get _isEdit => widget.serviceId != null;

  static const _deliveryModes = [
    'On-site',
    'Remote',
    'Both',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadService();
  }

  Future<void> _loadService() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _titleCtrl.text = 'Hair braiding — all styles';
      _descCtrl.text =
          'Professional hair braiding: box braids, cornrows, loc maintenance. '
          'All hair types welcome.';
      _priceCtrl.text = '1500';
      _locationCtrl.text = 'Nairobi, Kenya';
      _durationCtrl.text = '2';
      _deliveryMode = 'On-site';
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              _isEdit ? 'Service updated' : 'Service created')),
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
            title: Text(
              _isEdit ? 'Edit Service' : 'New Service',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kText),
            ),
            iconTheme: const IconThemeData(color: _kText),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: _saving ? null : _save,
                  style: TextButton.styleFrom(
                    backgroundColor: _kText,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(0, 36),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save',
                          style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image picker
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: _kSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kDivider),
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
                                Text('Add service photos',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: _kMuted)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      _FormSection(
                        title: 'Service Details',
                        children: [
                          _field(
                            ctrl: _titleCtrl,
                            label: 'Service Title',
                            hint: 'e.g. Professional Logo Design',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Enter a title'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            ctrl: _descCtrl,
                            label: 'Description',
                            hint: 'What do you offer? Process, results…',
                            maxLines: 4,
                            maxLength: 600,
                          ),
                        ],
                      ),

                      _FormSection(
                        title: 'Pricing & Duration',
                        children: [
                          Row(children: [
                            Expanded(
                              child: _field(
                                ctrl: _priceCtrl,
                                label: 'Price (TZS)',
                                hint: '1500',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly
                                ],
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                ctrl: _durationCtrl,
                                label: 'Duration (hours)',
                                hint: '2',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly
                                ],
                              ),
                            ),
                          ]),
                        ],
                      ),

                      _FormSection(
                        title: 'Delivery & Location',
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _deliveryMode,
                            onChanged: (v) => setState(
                                () => _deliveryMode = v!),
                            decoration: InputDecoration(
                              labelText: 'Delivery Mode',
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                            ),
                            items: _deliveryModes
                                .map((m) => DropdownMenuItem(
                                    value: m, child: Text(m)))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          _field(
                            ctrl: _locationCtrl,
                            label: 'Location / Area',
                            hint: 'e.g. Nairobi, Westlands',
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
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
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kText)),
        const SizedBox(height: 10),
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
