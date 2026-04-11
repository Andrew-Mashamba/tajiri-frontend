import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../widgets/booking_card.dart';
import 'ticket_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class MyBookingsPage extends StatefulWidget {
  final int userId;
  const MyBookingsPage({super.key, required this.userId});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  final TravelService _service = TravelService();
  late final TabController _tabController;
  bool _isLoading = true;

  List<TransportBooking> _upcoming = [];
  List<TransportBooking> _past = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await _service.getBookings(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _upcoming = result.items.where((b) => b.isUpcoming).toList();
          _past = result.items.where((b) => b.isPast).toList();
        }
      });
    }
  }

  void _onBookingTap(TransportBooking booking) {
    if (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.completed) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TicketPage(booking: booking)),
      ).then((_) {
        if (mounted) _loadData();
      });
    } else if (booking.canCancel) {
      _showCancelDialog(booking);
    }
  }

  void _showCancelDialog(TransportBooking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Ghairi Safari? / Cancel Trip?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${booking.originCity} \u2192 ${booking.destinationCity}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              booking.bookingReference,
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Je, una uhakika unataka kughairi safari hii?',
              style: TextStyle(fontSize: 14, color: _kPrimary),
            ),
            const SizedBox(height: 2),
            const Text(
              'Are you sure you want to cancel this trip?',
              style: TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hapana / No',
              style: TextStyle(color: _kSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelBooking(booking);
            },
            child: Text(
              'Ghairi / Cancel',
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(TransportBooking booking) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.cancelBooking(booking.id);
    if (result.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Safari imeghairiwa / Trip cancelled')),
      );
      _loadData();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kughairi / Cancellation failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safiri Zangu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'My Bookings',
              style: TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          tabs: [
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Zijazo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Upcoming', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Zilizopita', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Past', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_upcoming, isUpcoming: true),
                _buildBookingsList(_past, isUpcoming: false),
              ],
            ),
    );
  }

  Widget _buildBookingsList(List<TransportBooking> bookings, {required bool isUpcoming}) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUpcoming ? Icons.flight_takeoff_rounded : Icons.history_rounded,
                size: 48,
                color: _kSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                isUpcoming ? 'Hakuna safari zijazo / No upcoming trips' : 'Hakuna safari zilizopita / No past trips',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isUpcoming ? 'No upcoming trips' : 'No past trips',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: bookings.length,
        itemBuilder: (_, i) => BookingCard(
          booking: bookings[i],
          onTap: () => _onBookingTap(bookings[i]),
        ),
      ),
    );
  }
}
