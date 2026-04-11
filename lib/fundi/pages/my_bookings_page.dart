// lib/fundi/pages/my_bookings_page.dart
import 'package:flutter/material.dart';
import '../models/fundi_models.dart';
import '../services/fundi_service.dart';
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
  final FundiService _service = FundiService();
  late TabController _tabController;

  List<FundiBooking> _activeBookings = [];
  List<FundiBooking> _pastBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    final activeResult = await _service.getMyBookings(userId: widget.userId, status: 'active');
    final pastResult = await _service.getMyBookings(userId: widget.userId, status: 'completed');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (activeResult.success) _activeBookings = activeResult.items;
        if (pastResult.success) _pastBookings = pastResult.items;
      });
    }
  }

  Widget _buildBookingList(List<FundiBooking> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.engineering_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMessage, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => BookingCard(booking: bookings[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nafasi Zangu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Zinazoendelea'),
            Tab(text: 'Zilizopita'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(_activeBookings, 'Hakuna nafasi zinazoendelea'),
                _buildBookingList(_pastBookings, 'Hakuna nafasi zilizopita'),
              ],
            ),
    );
  }
}
