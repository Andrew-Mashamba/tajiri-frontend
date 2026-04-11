// lib/spare_parts/pages/shop_directory_page.dart
import 'package:flutter/material.dart';
import '../models/spare_parts_models.dart';
import '../services/spare_parts_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ShopDirectoryPage extends StatefulWidget {
  final int userId;
  const ShopDirectoryPage({super.key, required this.userId});
  @override
  State<ShopDirectoryPage> createState() => _ShopDirectoryPageState();
}

class _ShopDirectoryPageState extends State<ShopDirectoryPage> {
  final SparePartsService _service = SparePartsService();
  List<PartsSeller> _shops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getShopDirectory();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _shops = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Shop Directory', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _shops.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_rounded, size: 48, color: _kSecondary),
                      SizedBox(height: 12),
                      Text('No shops found', style: TextStyle(color: _kSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = _shops[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE8E8E8),
                            child: Icon(
                              s.verified ? Icons.verified_rounded : Icons.store_rounded,
                              color: s.verified ? const Color(0xFF1565C0) : _kSecondary,
                              size: 22,
                            ),
                          ),
                          title: Text(s.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.location != null)
                                Text(s.location!,
                                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                                  const SizedBox(width: 2),
                                  Text('${s.rating.toStringAsFixed(1)}',
                                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                  const SizedBox(width: 8),
                                  Text('${s.salesCount} sales',
                                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(s.type.name,
                              style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
