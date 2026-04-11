// lib/rent_car/pages/rent_car_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/rent_car_models.dart';
import '../services/rent_car_service.dart';
import '../widgets/vehicle_card.dart';
import 'browse_vehicles_page.dart';
import 'my_bookings_page.dart';
import 'vehicle_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class RentCarHomePage extends StatefulWidget {
  final int userId;
  const RentCarHomePage({super.key, required this.userId});
  @override
  State<RentCarHomePage> createState() => _RentCarHomePageState();
}

class _RentCarHomePageState extends State<RentCarHomePage> {
  final RentCarService _service = RentCarService();
  List<RentalVehicle> _featured = [];
  List<RentalVehicle> _safariVehicles = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.searchVehicles(page: 1),
      _service.searchVehicles(category: 'safari', page: 1),
    ]);
    if (mounted) {
      final featuredResult = results[0];
      final safariResult = results[1];
      setState(() {
        _isLoading = false;
        if (featuredResult.success) _featured = featuredResult.items.take(6).toList();
        if (safariResult.success) _safariVehicles = safariResult.items.take(4).toList();
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
                  // Category chips
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: VehicleCategory.values.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(cat.label, style: const TextStyle(fontSize: 13)),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            onPressed: () => _nav(BrowseVehiclesPage(
                              userId: widget.userId,
                              initialCategory: cat,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick actions
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.search_rounded,
                        label: 'Tafuta',
                        onTap: () => _nav(BrowseVehiclesPage(userId: widget.userId)),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.bookmark_rounded,
                        label: 'Bookings',
                        onTap: () => _nav(MyBookingsPage(userId: widget.userId)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Featured vehicles
                  _SectionHeader(
                    title: _isSwahili ? 'Magari Bora' : 'Featured Vehicles',
                    onSeeAll: () => _nav(BrowseVehiclesPage(userId: widget.userId)),
                  ),
                  const SizedBox(height: 8),
                  if (_featured.isEmpty)
                    _EmptyState(message: _isSwahili ? 'Hakuna magari' : 'No vehicles available')
                  else
                    SizedBox(
                      height: 210,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _featured.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => SizedBox(
                          width: 180,
                          child: VehicleCard(
                            vehicle: _featured[i],
                            onTap: () => _nav(VehicleDetailPage(vehicle: _featured[i])),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Safari vehicles
                  _SectionHeader(
                    title: _isSwahili ? 'Magari ya Safari' : 'Safari Vehicles',
                    onSeeAll: () => _nav(BrowseVehiclesPage(
                      userId: widget.userId,
                      initialCategory: VehicleCategory.safari,
                    )),
                  ),
                  const SizedBox(height: 8),
                  if (_safariVehicles.isEmpty)
                    _EmptyState(message: _isSwahili ? 'Hakuna magari ya safari' : 'No safari vehicles')
                  else
                    ..._safariVehicles.map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: VehicleCard(
                            vehicle: v,
                            horizontal: true,
                            onTap: () => _nav(VehicleDetailPage(vehicle: v)),
                          ),
                        )),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('See All', style: TextStyle(fontSize: 13, color: _kSecondary)),  // inherited widget handles i18n
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car_rounded, size: 36, color: _kSecondary),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: _kSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
