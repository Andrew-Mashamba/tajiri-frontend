import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

/// Store Identity — banner, bio, social links, theme, collections.
class ShopCustomizationScreen extends StatefulWidget {
  const ShopCustomizationScreen({super.key});

  @override
  State<ShopCustomizationScreen> createState() =>
      _ShopCustomizationScreenState();
}

class _ShopCustomizationScreenState
    extends State<ShopCustomizationScreen> {
  final _bioCtrl = TextEditingController(
      text: 'Authentic Kenyan crafts shipped countrywide. '
          'Custom orders welcome.');
  final _taglineCtrl =
      TextEditingController(text: 'Quality you can trust');
  final _whatsappCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();

  bool _saving = false;
  bool _bannerAdded = false;
  bool _logoAdded = false;

  @override
  void dispose() {
    _bioCtrl.dispose();
    _taglineCtrl.dispose();
    _whatsappCtrl.dispose();
    _igCtrl.dispose();
    _tiktokCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Store identity saved')),
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
              'Store Identity',
              style: TextStyle(
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
          SliverList(
            delegate: SliverChildListDelegate([
              // Banner
              _Section(
                title: 'Store Banner',
                child: GestureDetector(
                  onTap: () => setState(() => _bannerAdded = true),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kDivider),
                    ),
                    child: _bannerAdded
                        ? const Center(
                            child: HeroIcon(HeroIcons.photo,
                                style: HeroIconStyle.outline,
                                color: _kMuted,
                                size: 40))
                        : Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: const [
                              HeroIcon(HeroIcons.photo,
                                  style: HeroIconStyle.outline,
                                  color: _kFaint,
                                  size: 32),
                              SizedBox(height: 6),
                              Text('Upload banner',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _kMuted)),
                              Text('1200 × 400 px recommended',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _kFaint)),
                            ],
                          ),
                  ),
                ),
              ),

              // Logo
              _Section(
                title: 'Store Logo',
                child: Row(children: [
                  GestureDetector(
                    onTap: () => setState(() => _logoAdded = true),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8E8),
                        shape: BoxShape.circle,
                        border: Border.all(color: _kDivider),
                      ),
                      child: _logoAdded
                          ? const Center(
                              child: HeroIcon(HeroIcons.photo,
                                  style: HeroIconStyle.outline,
                                  color: _kMuted,
                                  size: 28))
                          : const Center(
                              child: HeroIcon(HeroIcons.camera,
                                  style: HeroIconStyle.outline,
                                  color: _kFaint,
                                  size: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Store logo',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _kText)),
                        SizedBox(height: 4),
                        Text('Square, min 200 × 200 px',
                            style:
                                TextStyle(fontSize: 12, color: _kMuted)),
                      ]),
                ]),
              ),

              // Bio & tagline
              _Section(
                title: 'About Your Store',
                child: Column(children: [
                  TextField(
                    controller: _taglineCtrl,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: 'Tagline',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText: 'Store Bio',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ]),
              ),

              // Social links
              _Section(
                title: 'Social Links',
                child: Column(children: [
                  _socialField(
                    ctrl: _whatsappCtrl,
                    icon: HeroIcons.phone,
                    label: 'WhatsApp',
                    hint: '+254700000000',
                  ),
                  const SizedBox(height: 12),
                  _socialField(
                    ctrl: _igCtrl,
                    icon: HeroIcons.camera,
                    label: 'Instagram',
                    hint: '@yourstore',
                  ),
                  const SizedBox(height: 12),
                  _socialField(
                    ctrl: _tiktokCtrl,
                    icon: HeroIcons.musicalNote,
                    label: 'TikTok',
                    hint: '@yourstore',
                  ),
                ]),
              ),

              // Store health hint
              _Section(
                title: 'Store Health',
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const HeroIcon(HeroIcons.informationCircle,
                        style: HeroIconStyle.outline,
                        color: _kMuted,
                        size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'A complete store profile increases buyer trust '
                        'and search ranking.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 13, color: _kMuted),
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _socialField({
    required TextEditingController ctrl,
    required HeroIcons icon,
    required String label,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: HeroIcon(icon,
              style: HeroIconStyle.outline, color: _kMuted, size: 20),
        ),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

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
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [_kCardShadow],
          ),
          child: child,
        ),
      ]),
    );
  }
}
