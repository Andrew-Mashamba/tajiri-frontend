import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';
import '../../shared/widgets/product_card.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);

/// Geo-based discovery (`GET /shop/products/nearby`).
class NearbyProductsScreen extends StatefulWidget {
  const NearbyProductsScreen({super.key, required this.currentUserId});

  final int currentUserId;

  @override
  State<NearbyProductsScreen> createState() => _NearbyProductsScreenState();
}

class _NearbyProductsScreenState extends State<NearbyProductsScreen> {
  final ShopRepository _repo = ShopRepository.instance;
  List<Product> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final perm = await Geolocator.checkPermission();
      LocationPermission p = perm;
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.deniedForever || p == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Location permission is required for nearby listings.';
          });
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final r = await _repo.getNearbyProducts(
        latitude: pos.latitude,
        longitude: pos.longitude,
        currentUserId: widget.currentUserId,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (r.success) {
          _items = r.products;
        } else {
          _error = r.message ?? 'Could not load nearby products';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Nearby'),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(child: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_off_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Nothing nearby yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('No listings found in your area', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _kText,
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) => ProductCard(
                          product: _items[i],
                          onTap: () => Navigator.pushNamed(
                            ctx,
                            '/shop/product',
                            arguments: {'productId': _items[i].id},
                          ),
                        ),
                      ),
                    ),
      ),
    );
  }
}
