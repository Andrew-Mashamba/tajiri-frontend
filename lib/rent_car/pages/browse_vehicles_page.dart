// lib/rent_car/pages/browse_vehicles_page.dart
import 'package:flutter/material.dart';
import '../models/rent_car_models.dart';
import '../services/rent_car_service.dart';
import '../widgets/vehicle_card.dart';
import 'vehicle_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BrowseVehiclesPage extends StatefulWidget {
  final int userId;
  final VehicleCategory? initialCategory;
  const BrowseVehiclesPage({super.key, required this.userId, this.initialCategory});
  @override
  State<BrowseVehiclesPage> createState() => _BrowseVehiclesPageState();
}

class _BrowseVehiclesPageState extends State<BrowseVehiclesPage> {
  final RentCarService _service = RentCarService();
  final ScrollController _scroll = ScrollController();

  List<RentalVehicle> _vehicles = [];
  VehicleCategory? _selectedCategory;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _loadVehicles();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _page < _lastPage) {
      _loadMore();
    }
  }

  Future<void> _loadVehicles() async {
    setState(() { _isLoading = true; _page = 1; });
    final result = await _service.searchVehicles(
      category: _selectedCategory?.name,
      page: 1,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _vehicles = result.items;
          _lastPage = result.lastPage;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _page++;
    final result = await _service.searchVehicles(
      category: _selectedCategory?.name,
      page: _page,
    );
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) _vehicles.addAll(result.items);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Browse Vehicles', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(
        children: [
          // Category tabs
          Container(
            color: Colors.white,
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () { _selectedCategory = null; _loadVehicles(); },
                ),
                ...VehicleCategory.values.map((cat) => _CategoryChip(
                      label: cat.label,
                      selected: _selectedCategory == cat,
                      onTap: () { _selectedCategory = cat; _loadVehicles(); },
                    )),
              ],
            ),
          ),

          // Vehicle grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _vehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car_rounded, size: 48, color: _kSecondary),
                            const SizedBox(height: 12),
                            const Text('No vehicles found', style: TextStyle(color: _kSecondary, fontSize: 14)),
                            const SizedBox(height: 16),
                            TextButton(onPressed: _loadVehicles, child: const Text('Refresh')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadVehicles,
                        color: _kPrimary,
                        child: GridView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _vehicles.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _vehicles.length) {
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
                            }
                            return VehicleCard(
                              vehicle: _vehicles[i],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicle: _vehicles[i])),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : _kPrimary)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: _kPrimary,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? _kPrimary : const Color(0xFFE0E0E0)),
      ),
    );
  }
}
