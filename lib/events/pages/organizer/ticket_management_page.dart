// lib/events/pages/organizer/ticket_management_page.dart
import 'package:flutter/material.dart';
import '../../models/event_enums.dart';
import '../../models/event_strings.dart';
import '../../models/event_ticket.dart';
import '../../models/promo_code.dart';
import '../../services/ticket_service.dart';
import '../../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TicketManagementPage extends StatefulWidget {
  final int eventId;

  const TicketManagementPage({super.key, required this.eventId});

  @override
  State<TicketManagementPage> createState() => _TicketManagementPageState();
}

class _TicketManagementPageState extends State<TicketManagementPage> {
  final _ticketService = TicketService();
  late EventStrings _strings;
  List<TicketTier> _tiers = [];
  List<PromoCode> _promos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _ticketService.getEventTiers(eventId: widget.eventId),
      _ticketService.getPromoCodes(eventId: widget.eventId),
    ]);
    if (!mounted) return;
    setState(() {
      _tiers = results[0] as List<TicketTier>;
      _promos = results[1] as List<PromoCode>;
      _loading = false;
    });
  }

  Future<void> _deleteTier(int tierId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Tier'),
        content: const Text('Are you sure you want to delete this ticket tier?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await _ticketService.deleteTier(tierId: tierId);
    if (!mounted) return;
    if (result.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to delete tier')));
    }
  }

  void _showAddTierDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Ticket Tier', style: TextStyle(color: _kPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(controller: nameCtrl, label: 'Name'),
            const SizedBox(height: 12),
            _DialogField(controller: priceCtrl, label: 'Price', inputType: TextInputType.number),
            const SizedBox(height: 12),
            _DialogField(controller: qtyCtrl, label: 'Total Quantity', inputType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _ticketService.createTier(
                eventId: widget.eventId,
                name: nameCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                totalQuantity: int.tryParse(qtyCtrl.text.trim()) ?? 0,
              );
              if (!mounted) return;
              if (result.success) { _load(); } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed')));
              }
            },
            child: const Text('Add', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAddPromoDialog() {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    PromoType selectedType = PromoType.percentage;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Promo Code', style: TextStyle(color: _kPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(controller: codeCtrl, label: 'Code'),
              const SizedBox(height: 12),
              DropdownButton<PromoType>(
                value: selectedType,
                isExpanded: true,
                items: PromoType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.apiValue))).toList(),
                onChanged: (v) => setSt(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              _DialogField(controller: valueCtrl, label: 'Value', inputType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await _ticketService.createPromoCode(
                  eventId: widget.eventId,
                  code: codeCtrl.text.trim(),
                  type: selectedType,
                  value: double.tryParse(valueCtrl.text.trim()) ?? 0,
                );
                if (!mounted) return;
                if (result.success) { _load(); } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed')));
                }
              },
              child: const Text('Add', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(_strings.ticketManagement, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : RefreshIndicator(
              color: _kPrimary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader(label: _strings.ticketTiers, onAdd: _showAddTierDialog),
                  const SizedBox(height: 12),
                  if (_tiers.isEmpty)
                    const _EmptyHint('No ticket tiers yet.')
                  else
                    ..._tiers.map((t) => _TierCard(tier: t, onDelete: () => _deleteTier(t.id))),
                  const SizedBox(height: 24),
                  _SectionHeader(label: _strings.promoCodes, onAdd: _showAddPromoDialog),
                  const SizedBox(height: 12),
                  if (_promos.isEmpty)
                    const _EmptyHint('No promo codes yet.')
                  else
                    ..._promos.map((p) => _PromoCard(promo: p)),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final VoidCallback onAdd;
  const _SectionHeader({required this.label, required this.onAdd});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary))),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(6)),
          child: const Row(children: [Icon(Icons.add_rounded, size: 16, color: Colors.white), SizedBox(width: 4), Text('Add', style: TextStyle(fontSize: 12, color: Colors.white))]),
        ),
      ),
    ],
  );
}

class _TierCard extends StatelessWidget {
  final TicketTier tier;
  final VoidCallback onDelete;
  const _TierCard({required this.tier, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 4),
                Text('${tier.currency} ${tier.price.toStringAsFixed(0)}  ·  ${tier.soldQuantity}/${tier.totalQuantity} sold', style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromoCode promo;
  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Row(
        children: [
          const Icon(Icons.discount_rounded, size: 18, color: _kSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(promo.code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                Text('${promo.type.apiValue}  ·  ${promo.usedCount}/${promo.maxUses ?? '∞'} used', style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: promo.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(promo.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, color: promo.isActive ? Colors.green : _kSecondary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType inputType;
  const _DialogField({required this.controller, required this.label, this.inputType = TextInputType.text});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: inputType,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text, style: const TextStyle(color: _kSecondary, fontSize: 13)),
  );
}
