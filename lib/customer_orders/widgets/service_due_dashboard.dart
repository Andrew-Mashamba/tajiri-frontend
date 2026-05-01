import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/customer_order.dart';
import '../services/customer_orders_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kWarn = Color(0xFFFF9800);
const Color _kOverdue = Color(0xFFE53935);

/// Spec §G.4 — service-due dashboard for customers.
///
/// Shows upcoming services based on completed orders + typical rebook cadences.
/// Hair: 4–6 weeks, Car service: 6 months, AC: 3 months, etc.
class ServiceDueDashboard extends StatefulWidget {
  final int userId;
  const ServiceDueDashboard({super.key, required this.userId});

  @override
  State<ServiceDueDashboard> createState() => _ServiceDueDashboardState();
}

class _ServiceDueDashboardState extends State<ServiceDueDashboard> {
  bool _loading = true;
  List<_ServiceDueItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final res = await CustomerOrdersService.list(
      userId: widget.userId,
      role: 'customer',
      status: 'completed',
      limit: 50,
    );

    if (!mounted) return;
    if (!res.success || res.items.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // Group by skill; keep the most recent completed order per skill.
    final latestBySkill = <String, CustomerOrder>{};
    for (final o in res.items) {
      final key = o.skillCategoryRaw ?? o.source.apiValue;
      final existing = latestBySkill[key];
      if (existing == null || o.createdAt.isAfter(existing.createdAt)) {
        latestBySkill[key] = o;
      }
    }

    final items = <_ServiceDueItem>[];
    for (final entry in latestBySkill.entries) {
      final order = entry.value;
      final cadence = _typicalCadence(order.skillCategoryRaw);
      if (cadence == null) continue;

      final dueDate = order.createdAt.add(cadence);
      final daysUntil = dueDate.difference(DateTime.now()).inDays;

      items.add(_ServiceDueItem(
        order: order,
        dueDate: dueDate,
        daysUntil: daysUntil,
        serviceName: _serviceLabel(order.skillCategoryRaw),
      ));
    }

    // Sort: overdue first, then closest due.
    items.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));

    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = items.where((i) => i.daysUntil <= 30).toList();
    });
  }

  static Duration? _typicalCadence(String? skill) {
    const map = {
      'hairstyling': Duration(days: 28),
      'barbering': Duration(days: 21),
      'nailTechnician': Duration(days: 14),
      'skincare': Duration(days: 30),
      'makeup': Duration(days: 7),
      'autoMechanic': Duration(days: 180),
      'autoElectrician': Duration(days: 180),
      'panelBeating': Duration(days: 365),
      'sprayPainting': Duration(days: 365),
      'plumbing': Duration(days: 180),
      'electrical': Duration(days: 365),
      'personalTraining': Duration(days: 7),
      'nutrition': Duration(days: 30),
      'medical': Duration(days: 30),
      'legal': Duration(days: 90),
      'accounting': Duration(days: 30),
      'taxAdvisory': Duration(days: 90),
      'eventPlanning': Duration(days: 180),
    };
    return map[skill];
  }

  static String _serviceLabel(String? skill) {
    const map = {
      'hairstyling': 'Hair styling',
      'barbering': 'Haircut',
      'nailTechnician': 'Nails',
      'skincare': 'Facial / Skincare',
      'makeup': 'Makeup',
      'autoMechanic': 'Car service',
      'autoElectrician': 'Electrical check',
      'panelBeating': 'Panel beating',
      'sprayPainting': 'Spray painting',
      'plumbing': 'Plumbing check',
      'electrical': 'Electrical check',
      'personalTraining': 'Gym session',
      'nutrition': 'Nutrition review',
      'medical': 'Health check',
      'legal': 'Legal review',
      'accounting': 'Bookkeeping',
      'taxAdvisory': 'Tax filing',
      'eventPlanning': 'Event planning',
    };
    return map[skill] ?? 'Service';
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
          ),
        ),
      );
    }

    if (_items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            isSw ? 'Huduma Zinazokaribia' : 'Upcoming Services',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _ServiceDueCard(item: _items[i], isSwahili: isSw),
          ),
        ),
      ],
    );
  }
}

class _ServiceDueItem {
  final CustomerOrder order;
  final DateTime dueDate;
  final int daysUntil;
  final String serviceName;
  const _ServiceDueItem({
    required this.order,
    required this.dueDate,
    required this.daysUntil,
    required this.serviceName,
  });
}

class _ServiceDueCard extends StatelessWidget {
  final _ServiceDueItem item;
  final bool isSwahili;

  const _ServiceDueCard({required this.item, required this.isSwahili});

  @override
  Widget build(BuildContext context) {
    final overdue = item.daysUntil < 0;
    final urgent = !overdue && item.daysUntil <= 7;
    final color = overdue ? _kOverdue : urgent ? _kWarn : _kAccent;

    String label;
    if (overdue) {
      label = isSwahili ? 'Imechelewa ${item.daysUntil.abs()} siku' : '${item.daysUntil.abs()} days overdue';
    } else if (item.daysUntil == 0) {
      label = isSwahili ? 'Leo' : 'Today';
    } else {
      label = isSwahili ? 'Siku ${item.daysUntil}' : '${item.daysUntil} days';
    }

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                item.serviceName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            item.order.partnerName ?? '',
            style: const TextStyle(fontSize: 11, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
