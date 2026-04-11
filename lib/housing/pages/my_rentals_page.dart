// lib/housing/pages/my_rentals_page.dart
import 'package:flutter/material.dart';
import '../models/housing_models.dart';
import '../services/housing_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class MyRentalsPage extends StatefulWidget {
  final int userId;
  const MyRentalsPage({super.key, required this.userId});
  @override
  State<MyRentalsPage> createState() => _MyRentalsPageState();
}

class _MyRentalsPageState extends State<MyRentalsPage> {
  final HousingService _service = HousingService();
  List<MyRental> _rentals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyRentals(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _rentals = result.items;
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  void _showPaymentHistory(MyRental rental) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Historia ya Malipo',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary)),
              const SizedBox(height: 16),
              if (rental.payments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Hakuna malipo bado',
                        style: TextStyle(color: _kSecondary)),
                  ),
                )
              else
                ...rental.payments.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: p.status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    p.month ?? _fmtDate(p.date),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _kPrimary)),
                                if (p.reference != null)
                                  Text('Ref: ${p.reference}',
                                      style: const TextStyle(
                                          fontSize: 12, color: _kSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('TZS ${_fmtAmount(p.amount)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary)),
                              Text(p.status.displayName,
                                  style: TextStyle(
                                      fontSize: 11, color: p.status.color)),
                            ],
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Kodi Zangu',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kPrimary)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _rentals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_work_rounded,
                          size: 48, color: _kSecondary),
                      const SizedBox(height: 12),
                      const Text('Huna kodi bado',
                          style:
                              TextStyle(fontSize: 16, color: _kSecondary)),
                      const SizedBox(height: 6),
                      const Text('Panga nyumba kupitia Nyumba Tajiri',
                          style:
                              TextStyle(fontSize: 13, color: _kSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRentals,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rentals.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final r = _rentals[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _kPrimary.withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Icon(r.property.type.icon,
                                      color: _kPrimary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.property.title,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: _kPrimary),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis),
                                      Text(r.property.location,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _kSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Kodi ya Mwezi',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: _kSecondary)),
                                    Text(
                                        'TZS ${_fmtAmount(r.monthlyRent)}',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: _kPrimary)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    const Text('Mkataba',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: _kSecondary)),
                                    Text(
                                        '${_fmtDate(r.leaseStart)} - ${_fmtDate(r.leaseEnd)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: _kPrimary)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _showPaymentHistory(r),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _kPrimary,
                                      side: const BorderSide(
                                          color: _kPrimary, width: 1),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Historia',
                                        style: TextStyle(fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      // Future: navigate to payment page
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Malipo yataunganishwa na Wallet hivi karibuni')));
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _kPrimary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Lipa Kodi',
                                        style: TextStyle(fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
