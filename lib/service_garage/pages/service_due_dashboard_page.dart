import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/customer_vehicle.dart';
import '../services/customer_vehicle_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF1B5E20);
const Color _kAlert = Color(0xFFB71C1C);
const Color _kWarn = Color(0xFFE65100);

/// Spec line 547 — service-due dashboard. Aggregates upcoming maintenance
/// across all the customer's vehicles using `next_service_at_km`,
/// `next_service_at_date`, and `open_recalls` columns shipped earlier.
class ServiceDueDashboardPage extends StatefulWidget {
  final int userId;
  const ServiceDueDashboardPage({super.key, required this.userId});

  @override
  State<ServiceDueDashboardPage> createState() =>
      _ServiceDueDashboardPageState();
}

class _ServiceDueDashboardPageState extends State<ServiceDueDashboardPage> {
  bool _loading = true;
  List<CustomerVehicle> _vehicles = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await CustomerVehicleService.list(userId: widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) _vehicles = res.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    final dueSoon = _vehiclesWithDueService();
    final recalls = _vehicles.where((v) => v.openRecalls.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSw ? 'Huduma Inakaribia' : 'Service Due',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _summaryStrip(dueSoon.length, recalls.length, isSw),
                  const SizedBox(height: 12),
                  if (recalls.isNotEmpty) ...[
                    _sectionHeader(
                        isSw ? 'Recalls Wazi' : 'Open recalls', recalls.length),
                    const SizedBox(height: 6),
                    ...recalls.map(_recallCard),
                    const SizedBox(height: 12),
                  ],
                  if (dueSoon.isNotEmpty) ...[
                    _sectionHeader(
                        isSw ? 'Inakaribia' : 'Coming up', dueSoon.length),
                    const SizedBox(height: 6),
                    ...dueSoon.map(_dueCard),
                  ],
                  if (recalls.isEmpty && dueSoon.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 56, color: _kAccent),
                            const SizedBox(height: 12),
                            Text(
                              isSw
                                  ? 'Magari yako yote yako sawa.'
                                  : 'All vehicles up to date.',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  List<CustomerVehicle> _vehiclesWithDueService() {
    final now = DateTime.now();
    final list = <CustomerVehicle>[];
    for (final v in _vehicles) {
      final dateDue = v.nextServiceAtDate != null &&
          v.nextServiceAtDate!.isBefore(now.add(const Duration(days: 60)));
      final kmDue = v.nextServiceAtKm != null &&
          v.mileageKm != null &&
          (v.nextServiceAtKm! - v.mileageKm!) <= 1500;
      if (dateDue || kmDue) list.add(v);
    }
    list.sort((a, b) {
      final ad = a.nextServiceAtDate ?? DateTime(2099);
      final bd = b.nextServiceAtDate ?? DateTime(2099);
      return ad.compareTo(bd);
    });
    return list;
  }

  Widget _summaryStrip(int dueCount, int recallCount, bool isSw) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0D47A1).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statCell(
              '$dueCount',
              isSw ? 'Magari yanahitaji huduma' : 'Vehicles due soon',
              const Color(0xFF0D47A1),
            ),
          ),
          Container(
            height: 28,
            width: 1,
            color: const Color(0xFF0D47A1).withValues(alpha: 0.2),
          ),
          Expanded(
            child: _statCell(
              '$recallCount',
              isSw ? 'Recalls wazi' : 'Open recalls',
              recallCount > 0 ? _kAlert : const Color(0xFF0D47A1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.8),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _kPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _recallCard(CustomerVehicle v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border.all(color: _kAlert.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: _kAlert),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.displayLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _kAlert,
                  ),
                ),
                Text(
                  _isSwahili
                      ? 'Recalls wazi: ${v.openRecalls.length}'
                      : '${v.openRecalls.length} open recall${v.openRecalls.length > 1 ? "s" : ""}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
                Text(
                  v.openRecalls.take(2).join(', '),
                  style: const TextStyle(fontSize: 10, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dueCard(CustomerVehicle v) {
    final isSw = _isSwahili;
    final now = DateTime.now();
    String? subtitle;
    Color color = _kSecondary;
    if (v.nextServiceAtDate != null) {
      final days = v.nextServiceAtDate!.difference(now).inDays;
      if (days < 0) {
        subtitle = isSw
            ? 'Imepitwa siku ${-days}'
            : 'Overdue by ${-days} days';
        color = _kAlert;
      } else if (days < 14) {
        subtitle = isSw ? 'Siku $days zilizobaki' : '$days days left';
        color = _kWarn;
      } else {
        subtitle = isSw
            ? DateFormat('d MMM').format(v.nextServiceAtDate!.toLocal())
            : DateFormat('d MMM').format(v.nextServiceAtDate!.toLocal());
      }
    }
    String? kmInfo;
    if (v.nextServiceAtKm != null && v.mileageKm != null) {
      final delta = v.nextServiceAtKm! - v.mileageKm!;
      if (delta <= 0) {
        kmInfo = isSw
            ? 'Imepitwa km ${-delta}'
            : 'Overdue by ${-delta} km';
      } else {
        kmInfo = isSw
            ? '${NumberFormat('#,##0').format(delta)} km zilizobaki'
            : '${NumberFormat('#,##0').format(delta)} km left';
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_repeat_rounded, size: 20, color: _kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.displayLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                if (kmInfo != null)
                  Text(
                    kmInfo,
                    style: const TextStyle(fontSize: 10, color: _kSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
