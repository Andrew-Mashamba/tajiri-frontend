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

class _ServiceOption {
  final int id;
  final String name;
  final String price;

  const _ServiceOption(
      {required this.id, required this.name, required this.price});
}

/// Create a social service post — media + caption + tagged service.
class CreateServicePostScreen extends StatefulWidget {
  const CreateServicePostScreen({super.key});

  @override
  State<CreateServicePostScreen> createState() =>
      _CreateServicePostScreenState();
}

class _CreateServicePostScreenState
    extends State<CreateServicePostScreen> {
  final _captionCtrl = TextEditingController();
  final List<_ServiceOption> _myServices = [
    const _ServiceOption(
        id: 1, name: 'Hair braiding — all styles', price: 'TZS 1,500'),
    const _ServiceOption(
        id: 2, name: 'Logo design (48 h delivery)', price: 'TZS 2,500'),
    const _ServiceOption(
        id: 3, name: 'Home cleaning — 3-bedroom', price: 'TZS 3,000'),
  ];

  int? _taggedServiceId;
  bool _mediaAdded = false;
  bool _submitting = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_captionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a caption for your post')),
      );
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Service post published')),
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
              'New Service Post',
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
                  onPressed: _submitting ? null : _submit,
                  style: TextButton.styleFrom(
                    backgroundColor: _kText,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(0, 36),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Post',
                          style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Media picker
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => setState(() => _mediaAdded = true),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kDivider),
                    ),
                    child: _mediaAdded
                        ? Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: const Color(0xFFE8E8E8),
                                child: const Center(
                                  child: HeroIcon(HeroIcons.photo,
                                      style: HeroIconStyle.outline,
                                      color: _kMuted,
                                      size: 48),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _mediaAdded = false),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xBB000000),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const HeroIcon(
                                      HeroIcons.xMark,
                                      style: HeroIconStyle.outline,
                                      color: Colors.white,
                                      size: 16),
                                ),
                              ),
                            ),
                          ])
                        : Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              HeroIcon(HeroIcons.photo,
                                  style: HeroIconStyle.outline,
                                  color: _kFaint,
                                  size: 40),
                              const SizedBox(height: 8),
                              const Text('Add photo or video',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: _kMuted)),
                              const SizedBox(height: 4),
                              const Text(
                                  'Show your service in action',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _kFaint)),
                            ],
                          ),
                  ),
                ),
              ),

              // Caption
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [_kCardShadow],
                  ),
                  child: TextField(
                    controller: _captionCtrl,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe your service… results, process, pricing',
                      border: InputBorder.none,
                      hintStyle:
                          TextStyle(color: _kFaint, fontSize: 14),
                    ),
                  ),
                ),
              ),

              // Tag a service
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tag a service',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kText)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [_kCardShadow],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _myServices.length,
                          separatorBuilder: (context, index) => const Divider(
                              height: 1, color: _kDivider),
                          itemBuilder: (context, i) {
                            final svc = _myServices[i];
                            final selected = _taggedServiceId == svc.id;
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4),
                              title: Text(
                                svc.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _kText),
                              ),
                              subtitle: Text(svc.price,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _kMuted)),
                              trailing: selected
                                  ? const HeroIcon(
                                      HeroIcons.checkCircle,
                                      style: HeroIconStyle.solid,
                                      color: _kText,
                                      size: 22)
                                  : const HeroIcon(
                                      HeroIcons.plusCircle,
                                      style: HeroIconStyle.outline,
                                      color: _kMuted,
                                      size: 22),
                              onTap: () => setState(() =>
                                  _taggedServiceId =
                                      selected ? null : svc.id),
                            );
                          },
                        ),
                      ),
                    ]),
              ),

              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}
