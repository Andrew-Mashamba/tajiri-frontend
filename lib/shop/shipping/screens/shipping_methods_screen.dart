import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);
const Color _kMuted = Color(0xFF999999);

class _ShippingMethod {
  final String id;
  String name;
  String carrier;
  int minDays;
  int maxDays;
  double minPrice;
  double maxPrice;
  bool isActive;

  _ShippingMethod({
    required this.id,
    required this.name,
    required this.carrier,
    required this.minDays,
    required this.maxDays,
    required this.minPrice,
    required this.maxPrice,
    this.isActive = true,
  });
}

class ShippingMethodsScreen extends StatefulWidget {
  const ShippingMethodsScreen({super.key});

  @override
  State<ShippingMethodsScreen> createState() =>
      _ShippingMethodsScreenState();
}

class _ShippingMethodsScreenState extends State<ShippingMethodsScreen> {
  bool _loading = true;
  List<_ShippingMethod> _methods = [];

  @override
  void initState() {
    super.initState();
    _loadMock();
  }

  Future<void> _loadMock() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _methods = [
        _ShippingMethod(
          id: '1',
          name: 'Standard Delivery',
          carrier: 'Tanzania Post',
          minDays: 3,
          maxDays: 7,
          minPrice: 3000,
          maxPrice: 8000,
          isActive: true,
        ),
        _ShippingMethod(
          id: '2',
          name: 'Express Delivery',
          carrier: 'DHL Express',
          minDays: 1,
          maxDays: 2,
          minPrice: 12000,
          maxPrice: 25000,
          isActive: true,
        ),
        _ShippingMethod(
          id: '3',
          name: 'Store Pickup',
          carrier: 'Self',
          minDays: 0,
          maxDays: 1,
          minPrice: 0,
          maxPrice: 0,
          isActive: false,
        ),
      ];
    });
  }

  void _showAddSheet() => _showMethodSheet(null);

  void _showMethodSheet(_ShippingMethod? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final carrierCtrl =
        TextEditingController(text: existing?.carrier ?? '');
    final minDaysCtrl = TextEditingController(
        text: existing?.minDays.toString() ?? '');
    final maxDaysCtrl = TextEditingController(
        text: existing?.maxDays.toString() ?? '');
    final minPriceCtrl = TextEditingController(
        text: existing?.minPrice.toStringAsFixed(0) ?? '');
    final maxPriceCtrl = TextEditingController(
        text: existing?.maxPrice.toStringAsFixed(0) ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                          color: _kText,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Text(
                    existing == null
                        ? 'Add Shipping Method'
                        : 'Edit Method',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kText),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SheetField(controller: nameCtrl, label: 'Method Name'),
              const SizedBox(height: 12),
              _SheetField(controller: carrierCtrl, label: 'Carrier'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SheetField(
                        controller: minDaysCtrl,
                        label: 'Min Days',
                        inputType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetField(
                        controller: maxDaysCtrl,
                        label: 'Max Days',
                        inputType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SheetField(
                        controller: minPriceCtrl,
                        label: 'Min Price (TZS)',
                        inputType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetField(
                        controller: maxPriceCtrl,
                        label: 'Max Price (TZS)',
                        inputType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final minD =
                        int.tryParse(minDaysCtrl.text.trim()) ?? 1;
                    final maxD =
                        int.tryParse(maxDaysCtrl.text.trim()) ?? 3;
                    final minP =
                        double.tryParse(minPriceCtrl.text.trim()) ?? 0;
                    final maxP =
                        double.tryParse(maxPriceCtrl.text.trim()) ?? 0;
                    Navigator.pop(ctx);
                    setState(() {
                      if (existing != null) {
                        existing.name = name;
                        existing.carrier = carrierCtrl.text.trim();
                        existing.minDays = minD;
                        existing.maxDays = maxD;
                        existing.minPrice = minP;
                        existing.maxPrice = maxP;
                      } else {
                        _methods.add(_ShippingMethod(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: name,
                          carrier: carrierCtrl.text.trim(),
                          minDays: minD,
                          maxDays: maxD,
                          minPrice: minP,
                          maxPrice: maxP,
                        ));
                      }
                    });
                  },
                  child: Text(
                    existing == null
                        ? 'Add Method'
                        : 'Save Changes',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      carrierCtrl.dispose();
      minDaysCtrl.dispose();
      maxDaysCtrl.dispose();
      minPriceCtrl.dispose();
      maxPriceCtrl.dispose();
    });
  }

  void _showActions(_ShippingMethod method) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _ActionItem(
              icon: Icons.edit_rounded,
              label: 'Edit Method',
              onTap: () {
                Navigator.pop(ctx);
                _showMethodSheet(method);
              },
            ),
            _ActionItem(
              icon: Icons.delete_rounded,
              label: 'Delete Method',
              color: const Color(0xFFD32F2F),
              onTap: () {
                Navigator.pop(ctx);
                setState(() =>
                    _methods.removeWhere((m) => m.id == method.id));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No shipping methods',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('Add methods to offer shipping to buyers',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Shipping Methods',
            style: TextStyle(
                color: _kText, fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _showAddSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _kText,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+ Add Method',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kText,
          onRefresh: _loadMock,
          child: _loading
              ? _buildShimmer()
              : _methods.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _methods.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _MethodCard(
                        method: _methods[i],
                        onMoreTap: () => _showActions(_methods[i]),
                        onToggle: (v) =>
                            setState(() => _methods[i].isActive = v),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.onMoreTap,
    required this.onToggle,
  });

  final _ShippingMethod method;
  final VoidCallback onMoreTap;
  final ValueChanged<bool> onToggle;

  IconData get _icon {
    final name = method.name.toLowerCase();
    if (name.contains('express')) return Icons.bolt_rounded;
    if (name.contains('pickup')) return Icons.storefront_rounded;
    return Icons.local_shipping_rounded;
  }

  String get _priceLabel {
    if (method.minPrice == 0 && method.maxPrice == 0) return 'Free';
    if (method.minPrice == method.maxPrice) {
      return 'TZS ${method.minPrice.toStringAsFixed(0)}';
    }
    return 'TZS ${method.minPrice.toStringAsFixed(0)} – ${method.maxPrice.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: method.isActive
                    ? Colors.grey.shade100
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon,
                  color: method.isActive ? _kSubtext : _kMuted,
                  size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            method.isActive ? _kText : _kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    method.carrier,
                    style: TextStyle(
                        fontSize: 12,
                        color: method.isActive ? _kSubtext : _kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: method.minDays == method.maxDays
                            ? '${method.maxDays}d'
                            : '${method.minDays}–${method.maxDays}d',
                      ),
                      const SizedBox(width: 6),
                      _InfoChip(
                        icon: Icons.payments_rounded,
                        label: _priceLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Switch(
                  value: method.isActive,
                  onChanged: onToggle,
                  activeThumbColor: _kText,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                GestureDetector(
                  onTap: onMoreTap,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 4),
                    child: Icon(Icons.more_vert_rounded,
                        color: _kMuted, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kSubtext),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: _kSubtext)),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    this.inputType = TextInputType.text,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType inputType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _kText,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, color: color)),
      onTap: onTap,
      minLeadingWidth: 24,
    );
  }
}
