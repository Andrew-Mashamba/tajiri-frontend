import 'package:flutter/material.dart';

import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/partner_product_service.dart';
import '../widgets/partner_product_card.dart';
import 'post_partner_product_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);

class MyPartnerProductsPage extends StatefulWidget {
  const MyPartnerProductsPage({super.key});

  @override
  State<MyPartnerProductsPage> createState() => _MyPartnerProductsPageState();
}

class _MyPartnerProductsPageState extends State<MyPartnerProductsPage> {
  int? _userId;
  bool _loading = true;
  String? _error;
  List<PartnerProduct> _products = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sijaingia';
      });
      return;
    }
    _userId = user.userId;
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_userId == null) return;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await PartnerProductService.listProducts(
      mine: true,
      userId: _userId,
      activeOnly: false,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _products = res.products;
      } else {
        _error = res.message;
      }
    });
  }

  Future<void> _openCreate() async {
    if (_userId == null) return;
    final created = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostPartnerProductPage(userId: _userId!),
      ),
    );
    if (created != null) await _refresh();
  }

  Future<void> _openEdit(PartnerProduct p) async {
    if (_userId == null) return;
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostPartnerProductPage(userId: _userId!, existing: p),
      ),
    );
    if (updated != null) await _refresh();
  }

  Future<void> _toggleActive(PartnerProduct p) async {
    if (_userId == null) return;
    final res = await PartnerProductService.updateProduct(
      productId: p.id,
      userId: _userId!,
      isActive: !p.isActive,
    );
    if (!mounted) return;
    if (res.success) {
      await _refresh();
    } else {
      _toast(res.message ?? 'Imeshindikana');
    }
  }

  Future<void> _delete(PartnerProduct p) async {
    if (_userId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: const Text('Futa huduma?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Una uhakika unataka kufuta "${p.title}"?',
            style: const TextStyle(fontSize: 13, color: _kSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hapana',
                style: TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Futa',
                style:
                    TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final res = await PartnerProductService.deleteProduct(
      productId: p.id,
      userId: _userId!,
    );
    if (!mounted) return;
    if (res.success) {
      await _refresh();
    } else {
      _toast(res.message ?? 'Imeshindikana');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kAccent,
        onPressed: _openCreate,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                size: 22, color: _kPrimary),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'Huduma zangu',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _kSecondary)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _refresh,
                child: const Text('Jaribu tena',
                    style: TextStyle(color: _kPrimary)),
              ),
            ],
          ),
        ),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_rounded,
                  size: 48, color: _kBorder),
              const SizedBox(height: 12),
              const Text(
                'Bado hujachapisha huduma',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tangaza huduma au bidhaa za kwanza ili wateja waone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _kSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _openCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tangaza ya kwanza',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _products.length,
        itemBuilder: (_, i) {
          final p = _products[i];
          return PartnerProductCard(
            product: p,
            showOwnerActions: true,
            onTap: () => _openEdit(p),
            onEdit: () => _openEdit(p),
            onToggleActive: () => _toggleActive(p),
            onDelete: () => _delete(p),
          );
        },
      ),
    );
  }
}
