// lib/hair_nails/pages/my_bookings_page.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';
import '../services/hair_nails_service.dart';
import '../widgets/booking_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class MyBookingsPage extends StatefulWidget {
  final int userId;
  const MyBookingsPage({super.key, required this.userId});
  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> with SingleTickerProviderStateMixin {
  final HairNailsService _service = HairNailsService();
  late TabController _tabCtrl;

  List<Booking> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyBookings(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _allBookings = result.items;
      });
    }
  }

  List<Booking> get _upcoming => _allBookings.where((b) => b.isUpcoming).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  List<Booking> get _past => _allBookings.where((b) => b.isPast).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  Future<void> _cancelBooking(Booking booking) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Futa Miadi?', style: TextStyle(color: _kPrimary)),
        content: Text('Una uhakika unataka kufuta miadi ya ${booking.serviceName} katika ${booking.salonName}?', style: const TextStyle(color: _kSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hapana', style: TextStyle(color: _kSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ndio, Futa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _service.cancelBooking(booking.id);
      if (result.success) {
        messenger.showSnackBar(const SnackBar(content: Text('Miadi imefutwa'), backgroundColor: _kPrimary));
        _loadBookings();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa kufuta'), backgroundColor: Colors.red));
      }
    }
  }

  void _rateBooking(Booking booking) {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: _kBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _kSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Toa Tathmini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 4),
              Text('${booking.serviceName} — ${booking.salonName}', style: const TextStyle(fontSize: 13, color: _kSecondary)),
              const SizedBox(height: 16),

              // Star rating
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) => GestureDetector(
                        onTap: () => setSheetState(() => selectedRating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            i < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 36,
                            color: i < selectedRating ? Colors.amber : _kSecondary.withValues(alpha: 0.4),
                          ),
                        ),
                      )),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Andika maoni yako (si lazima)...',
                  hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                  filled: true,
                  fillColor: _kCardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: selectedRating == 0 || submitting
                      ? null
                      : () async {
                          setSheetState(() => submitting = true);
                          final result = await _service.rateBooking(
                            bookingId: booking.id,
                            rating: selectedRating,
                            comment: commentCtrl.text.isNotEmpty ? commentCtrl.text : null,
                          );
                          if (context.mounted) {
                            if (result.success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Asante kwa tathmini yako!'), backgroundColor: _kPrimary));
                              _loadBookings();
                            } else {
                              setSheetState(() => submitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa'), backgroundColor: Colors.red));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: _kSecondary,
                  ),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Tuma Tathmini', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Miadi Yangu', style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2.5,
          tabs: [
            Tab(text: 'Inayokuja (${_upcoming.length})'),
            Tab(text: 'Zilizopita (${_past.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  // Upcoming
                  _upcoming.isEmpty
                      ? const Center(child: Text('Hakuna miadi inayokuja', style: TextStyle(color: _kSecondary)))
                      : RefreshIndicator(
                          onRefresh: _loadBookings,
                          color: _kPrimary,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _upcoming.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final b = _upcoming[i];
                              return BookingCard(booking: b, onCancel: () => _cancelBooking(b));
                            },
                          ),
                        ),

                  // Past
                  _past.isEmpty
                      ? const Center(child: Text('Hakuna miadi zilizopita', style: TextStyle(color: _kSecondary)))
                      : RefreshIndicator(
                          onRefresh: _loadBookings,
                          color: _kPrimary,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _past.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final b = _past[i];
                              return BookingCard(
                                booking: b,
                                onRate: b.status == BookingStatus.completed ? () => _rateBooking(b) : null,
                              );
                            },
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
