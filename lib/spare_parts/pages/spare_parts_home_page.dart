// lib/spare_parts/pages/spare_parts_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/spare_parts_models.dart';
import '../services/spare_parts_service.dart';
import '../widgets/part_card.dart';
import 'parts_search_page.dart';
import 'my_orders_page.dart';
import 'shop_directory_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class SparePartsHomePage extends StatefulWidget {
  final int userId;
  const SparePartsHomePage({super.key, required this.userId});
  @override
  State<SparePartsHomePage> createState() => _SparePartsHomePageState();
}

class _SparePartsHomePageState extends State<SparePartsHomePage> {
  final SparePartsService _service = SparePartsService();
  List<SparePart> _recentParts = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  static const _categories = [
    ('Engine', Icons.settings_rounded, 'engine'),
    ('Brakes', Icons.do_not_touch_rounded, 'brakes'),
    ('Body', Icons.directions_car_rounded, 'body'),
    ('Electrical', Icons.electrical_services_rounded, 'electrical'),
    ('Suspension', Icons.height_rounded, 'suspension'),
    ('Interior', Icons.weekend_rounded, 'interior'),
  ];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await _service.searchParts(page: 1);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _recentParts = result.items.take(6).toList();
      });
    }
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: _kPrimary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                  // Search bar
                  GestureDetector(
                    onTap: () => _nav(PartsSearchPage(userId: widget.userId)),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded, color: _kSecondary, size: 22),
                          SizedBox(width: 10),
                          Text('Tafuta spare parts...', style: TextStyle(color: _kSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Categories
                  Text(_isSwahili ? 'Makundi' : 'Categories', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1,
                    children: _categories.map((cat) {
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _nav(PartsSearchPage(
                            userId: widget.userId,
                            initialCategory: cat.$3,
                          )),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat.$2, size: 28, color: _kPrimary),
                              const SizedBox(height: 6),
                              Text(cat.$1,
                                  style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Quick actions
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.store_rounded,
                        label: 'Shops',
                        onTap: () => _nav(ShopDirectoryPage(userId: widget.userId)),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.local_shipping_rounded,
                        label: 'Orders',
                        onTap: () => _nav(MyOrdersPage(userId: widget.userId)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Recent parts
                  Text(_isSwahili ? 'Vipuri vya Hivi Karibuni' : 'Recent Parts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 8),
                  if (_recentParts.isEmpty)
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.build_rounded, size: 36, color: _kSecondary),
                          const SizedBox(height: 8),
                          Text(_isSwahili ? 'Hakuna vipuri' : 'No parts found', style: const TextStyle(color: _kSecondary, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: _recentParts.length,
                      itemBuilder: (_, i) => PartCard(part_: _recentParts[i]),
                    ),
                ],
              ),
            );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: _kPrimary),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
