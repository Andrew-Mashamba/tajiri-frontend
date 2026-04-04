import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/shop_models.dart';
import '../../services/shop_service.dart';
import '../../widgets/shop/product_card.dart';

const Color _kBackground = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);

class FlashDealsScreen extends StatefulWidget {
  final int currentUserId;
  const FlashDealsScreen({super.key, required this.currentUserId});
  @override
  State<FlashDealsScreen> createState() => _FlashDealsScreenState();
}

class _FlashDealsScreenState extends State<FlashDealsScreen> {
  final ShopService _shopService = ShopService();
  List<Product> _deals = [];
  bool _isLoading = true;
  Timer? _countdownTimer;
  Duration _timeLeft = const Duration(hours: 12);

  @override
  void initState() {
    super.initState();
    _loadDeals();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft.inSeconds > 0) {
        setState(() => _timeLeft -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeals() async {
    final result = await _shopService.getFlashDeals();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _deals = result.products;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Flash Deals', style: TextStyle(color: _kPrimaryText)),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimaryText),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: _kPrimaryText,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_on, color: Color(0xFFFFB800), size: 20),
                const SizedBox(width: 8),
                const Text('Ends in  ', style: TextStyle(color: Colors.white, fontSize: 14)),
                _buildTimeBox(hours),
                const Text(' : ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                _buildTimeBox(minutes),
                const Text(' : ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                _buildTimeBox(seconds),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _deals.isEmpty
                    ? const Center(
                        child: Text(
                          'No active deals',
                          style: TextStyle(color: Color(0xFF999999)),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _deals.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: _deals[index],
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/shop/product',
                              arguments: {'productId': _deals[index].id},
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
