// lib/fundi/pages/fundi_home_page.dart
import 'package:flutter/material.dart';
import '../models/fundi_models.dart';
import '../services/fundi_service.dart';
import '../widgets/fundi_card.dart';
import '../widgets/booking_card.dart';
import 'find_fundi_page.dart';
import 'fundi_profile_page.dart';
import 'my_bookings_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class FundiHomePage extends StatefulWidget {
  final int userId;
  const FundiHomePage({super.key, required this.userId});
  @override
  State<FundiHomePage> createState() => _FundiHomePageState();
}

class _FundiHomePageState extends State<FundiHomePage> {
  final FundiService _service = FundiService();

  List<Fundi> _nearbyFundis = [];
  List<FundiBooking> _activeBookings = [];
  bool _isLoading = true;
  bool _isFundi = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _service.findFundis(availableOnly: true, perPage: 5),
      _service.getMyBookings(userId: widget.userId, status: 'active'),
      _service.getMyFundiProfile(widget.userId),
    ]);

    if (mounted) {
      final fundisResult = results[0] as FundiListResult<Fundi>;
      final bookingsResult = results[1] as FundiListResult<FundiBooking>;
      final myFundiResult = results[2] as FundiResult<Fundi>;

      setState(() {
        _isLoading = false;
        if (fundisResult.success) _nearbyFundis = fundisResult.items;
        if (bookingsResult.success) _activeBookings = bookingsResult.items;
        _isFundi = myFundiResult.success && myFundiResult.data != null;
      });
    }
  }

  void _openFundi(Fundi fundi) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FundiProfilePage(userId: widget.userId, fundi: fundi)),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Quick actions
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.search_rounded,
                  label: 'Tafuta Fundi',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FindFundiPage(userId: widget.userId)),
                  ).then((_) {
                    if (mounted) _loadData();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.calendar_month_rounded,
                  label: 'Nafasi Zangu',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyBookingsPage(userId: widget.userId)),
                  ).then((_) {
                    if (mounted) _loadData();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: _isFundi ? Icons.engineering_rounded : Icons.how_to_reg_rounded,
                  label: _isFundi ? 'Akaunti Yangu' : 'Jiunge Fundi',
                  onTap: () {
                    // Registration page placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usajili wa Fundi utakuja hivi karibuni')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Service categories
          const Text(
            'Huduma',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ServiceCategory.values.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FindFundiPage(
                          userId: widget.userId,
                          initialCategory: cat,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: 70,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(cat.icon, size: 22, color: _kPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.displayName,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Active bookings
          if (_activeBookings.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nafasi Zinazoendelea', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyBookingsPage(userId: widget.userId)),
                  ),
                  child: const Text('Zote', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._activeBookings.take(3).map((booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BookingCard(booking: booking),
                )),
            const SizedBox(height: 16),
          ],

          // Nearby fundis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mafundi wa Karibu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FindFundiPage(userId: widget.userId)),
                ),
                child: const Text('Tazama Wote', style: TextStyle(fontSize: 13, color: _kSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_nearbyFundis.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Icon(Icons.engineering_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Hakuna fundi kwa sasa', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            )
          else
            ..._nearbyFundis.map((fundi) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FundiCard(fundi: fundi, onTap: () => _openFundi(fundi)),
                )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
