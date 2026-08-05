import 'package:flutter/material.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x0F000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

enum _MethodType { tajiriPay, card, wallet }

class _PaymentMethod {
  final String id;
  final _MethodType type;
  final String label;
  final String detail;
  final bool isDefault;

  const _PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.detail,
    this.isDefault = false,
  });

  _PaymentMethod copyWith({bool? isDefault}) {
    return _PaymentMethod(
      id: id,
      type: type,
      label: label,
      detail: detail,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Buyer's saved payment methods screen.
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _loading = true;
  final List<_PaymentMethod> _methods = [];

  static const _mockMethods = [
    _PaymentMethod(
      id: 'PM-001',
      type: _MethodType.tajiriPay,
      label: 'Tajiri Pay',
      detail: 'Your Tajiri wallet — instant & secure',
      isDefault: true,
    ),
    _PaymentMethod(
      id: 'PM-002',
      type: _MethodType.card,
      label: 'Visa Card',
      detail: '**** **** **** 7342',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _methods
        ..clear()
        ..addAll(_mockMethods);
    });
  }

  void _showMethodActions(_PaymentMethod method) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              method.label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kText),
            ),
            Text(
              method.detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
            const SizedBox(height: 16),
            if (!method.isDefault)
              _ActionTile(
                icon: Icons.star_outline_rounded,
                label: 'Set as Default',
                onTap: () {
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  setState(() {
                    for (var i = 0; i < _methods.length; i++) {
                      _methods[i] =
                          _methods[i].copyWith(isDefault: _methods[i].id == method.id);
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${method.label} set as default')),
                  );
                },
              ),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Remove',
              destructive: true,
              onTap: () {
                Navigator.pop(ctx);
                if (!mounted) return;
                setState(() =>
                    _methods.removeWhere((m) => m.id == method.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${method.label} removed')),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _showAddMethod() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _MethodTypeButton(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Tajiri Pay',
              subtitle: 'Your Tajiri wallet — instant & secure',
              onTap: () {
                Navigator.pop(ctx);
                if (!mounted) return;
                final alreadyHas = _methods.any((m) => m.type == _MethodType.tajiriPay);
                if (alreadyHas) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tajiri Pay is already added')),
                  );
                  return;
                }
                setState(() => _methods.add(_PaymentMethod(
                  id: 'PM-${DateTime.now().millisecondsSinceEpoch}',
                  type: _MethodType.tajiriPay,
                  label: 'Tajiri Pay',
                  detail: 'Your Tajiri wallet — instant & secure',
                  isDefault: _methods.isEmpty,
                )));
              },
            ),
            const SizedBox(height: 12),
            _MethodTypeButton(
              icon: Icons.credit_card_rounded,
              label: 'Debit / Credit Card',
              subtitle: 'Visa, Mastercard',
              onTap: () { Navigator.pop(ctx); _showCardForm(); },
            ),
          ],
        ),
      ),
    );
  }

  void _showCardForm() {
    final numCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Cardholder name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numCtrl,
              keyboardType: TextInputType.number,
              maxLength: 19,
              decoration: const InputDecoration(labelText: 'Card number', hintText: '•••• •••• •••• ••••', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final num = numCtrl.text.replaceAll(' ', '');
                  if (num.length >= 12) {
                    Navigator.pop(ctx);
                    setState(() => _methods.add(_PaymentMethod(
                      id: 'PM-${DateTime.now().millisecondsSinceEpoch}',
                      type: _MethodType.card,
                      label: nameCtrl.text.trim().isEmpty ? 'Card' : nameCtrl.text.trim(),
                      detail: '•••• ${num.substring(num.length - 4)}',
                      isDefault: _methods.isEmpty,
                    )));
                  }
                },
                child: const Text('Add Card'),
              ),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 100), () { numCtrl.dispose(); nameCtrl.dispose(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        title: const Text(
          'Payment Methods',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _kText),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _showAddMethod,
              style: TextButton.styleFrom(
                backgroundColor: _kText,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Add Method',
                  style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _kText))
            : _methods.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._methods.map((m) => _MethodCard(
                            method: m,
                            onTap: () => _showMethodActions(m),
                          )),
                      const SizedBox(height: 8),
                      _InfoNote(
                        icon: Icons.lock_outline_rounded,
                        text:
                            'Your payment information is encrypted and stored securely.',
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.credit_card_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No payment methods',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        Text('Add a method to start shopping.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _showAddMethod,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kText,
            foregroundColor: Colors.white,
            minimumSize: const Size(160, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Add Payment Method'),
        ),
      ]),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({required this.method, required this.onTap});
  final _PaymentMethod method;
  final VoidCallback onTap;

  IconData get _icon {
    switch (method.type) {
      case _MethodType.tajiriPay:
        return Icons.account_balance_wallet_rounded;
      case _MethodType.card:
        return Icons.credit_card_rounded;
      case _MethodType.wallet:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [_kCardShadow],
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 24, color: _kText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      method.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kText),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: 8),
                      _DefaultBadge(),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    method.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _kMuted),
                  ),
                ]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert_rounded, size: 20, color: _kFaint),
        ]),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _kText.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'Default',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: _kText),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFD32F2F) : _kText;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 22, color: color),
      title: Text(label,
          style: TextStyle(
              fontSize: 15, color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
      minLeadingWidth: 24,
    );
  }
}

class _MethodTypeButton extends StatelessWidget {
  const _MethodTypeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 24, color: _kText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: _kText), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: _kMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: _kMuted),
        ]),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: _kMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: _kMuted),
          ),
        ),
      ]),
    );
  }
}
