import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../widgets/route_card.dart';
import '../widgets/booking_card.dart';
import '../widgets/city_search_field.dart';
import 'search_results_page.dart';
import 'my_bookings_page.dart';
import 'ticket_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TravelHomePage extends StatefulWidget {
  final int userId;
  const TravelHomePage({super.key, required this.userId});

  @override
  State<TravelHomePage> createState() => _TravelHomePageState();
}

class _TravelHomePageState extends State<TravelHomePage> {
  final TravelService _service = TravelService();
  bool _isLoading = true;

  City? _originCity;
  City? _destCity;
  DateTime _date = DateTime.now();
  int _passengers = 1;

  List<PopularRoute> _popularRoutes = [];
  List<TransportBooking> _upcomingBookings = [];
  final List<_RecentSearch> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getPopularRoutes(),
      _service.getBookings(widget.userId),
    ]);
    if (mounted) {
      final routesResult = results[0] as TransportListResult<PopularRoute>;
      final bookingsResult = results[1] as TransportListResult<TransportBooking>;
      setState(() {
        _isLoading = false;
        _popularRoutes = routesResult.items;
        _upcomingBookings = bookingsResult.items
            .where((b) => b.isUpcoming)
            .take(3)
            .toList();
      });
    }
  }

  Future<void> _pickOrigin() async {
    final city = await CitySearchField.show(context, title: 'Toka Wapi? / From');
    if (city != null && mounted) {
      setState(() => _originCity = city);
    }
  }

  Future<void> _pickDestination() async {
    final city = await CitySearchField.show(context, title: 'Unakwenda Wapi? / To');
    if (city != null && mounted) {
      setState(() => _destCity = city);
    }
  }

  void _swapCities() {
    setState(() {
      final temp = _originCity;
      _originCity = _destCity;
      _destCity = temp;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _kPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  void _doSearch() {
    if (_originCity == null || _destCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chagua mji wa kuondokea na mji wa kwenda / Select origin and destination')),
      );
      return;
    }

    _recentSearches.removeWhere(
      (r) => r.origin.code == _originCity!.code && r.destination.code == _destCity!.code,
    );
    _recentSearches.insert(0, _RecentSearch(origin: _originCity!, destination: _destCity!));
    if (_recentSearches.length > 5) _recentSearches.removeLast();

    final dateStr =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(
          origin: _originCity!,
          destination: _destCity!,
          date: dateStr,
          passengers: _passengers,
          userId: widget.userId,
        ),
      ),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  void _openMyBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyBookingsPage(userId: widget.userId),
      ),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  void _onBookingTap(TransportBooking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketPage(booking: booking),
      ),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  void _onRouteTap(PopularRoute route) {
    setState(() {
      _originCity = City(
        id: 0,
        name: route.origin.city,
        code: route.origin.code,
      );
      _destCity = City(
        id: 0,
        name: route.destination.city,
        code: route.destination.code,
      );
    });
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        color: _kPrimary,
        onRefresh: _loadData,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            _buildSearchForm(),
            if (_recentSearches.isNotEmpty) _buildRecentSearches(),
            if (!_isLoading && _popularRoutes.isNotEmpty) _buildPopularRoutes(),
            if (!_isLoading && _upcomingBookings.isNotEmpty) _buildUpcomingBookings(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safari',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Travel',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          if (!_isLoading) ...[
            _statBadge('${_popularRoutes.length}', 'Njia / Routes'),
            const SizedBox(width: 12),
            _statBadge('${_upcomingBookings.length}', 'Buking / Trips'),
          ],
        ],
      ),
    );
  }

  Widget _statBadge(String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _locationField(
            icon: Icons.circle_outlined,
            label: _originCity?.name ?? 'Toka Wapi?',
            subtitle: _originCity != null ? '${_originCity!.code} \u2022 From' : 'From',
            filled: _originCity != null,
            onTap: _pickOrigin,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: _swapCities,
              icon: const Icon(Icons.swap_vert_rounded, color: _kSecondary),
              tooltip: 'Badilisha / Swap',
            ),
          ),
          _locationField(
            icon: Icons.location_on_rounded,
            label: _destCity?.name ?? 'Unakwenda Wapi?',
            subtitle: _destCity != null ? '${_destCity!.code} \u2022 To' : 'To',
            filled: _destCity != null,
            onTap: _pickDestination,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatDate(_date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 18, color: _kSecondary),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _passengers > 1 ? () => setState(() => _passengers--) : null,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: _passengers > 1 ? _kPrimary : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '$_passengers',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _passengers < 9 ? () => setState(() => _passengers++) : null,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: _passengers < 9 ? _kPrimary : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _doSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tafuta Safari / Search',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationField({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: filled ? _kPrimary : Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
                      color: filled ? _kPrimary : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Utafutaji wa Hivi Karibuni',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 2),
          const Text(
            'Recent Searches',
            style: TextStyle(fontSize: 11, color: _kSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _recentSearches.map((r) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _originCity = r.origin;
                    _destCity = r.destination;
                  });
                },
                child: Chip(
                  label: Text(
                    '${r.origin.code} \u2192 ${r.destination.code}',
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularRoutes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Njia Maarufu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              Text('Popular Routes', style: TextStyle(fontSize: 12, color: _kSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _popularRoutes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => RouteCard(
              route: _popularRoutes[i],
              onTap: () => _onRouteTap(_popularRoutes[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safari Zijazo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    Text('Upcoming Trips', style: TextStyle(fontSize: 12, color: _kSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openMyBookings,
                child: const Row(
                  children: [
                    Text(
                      'My Trips',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kSecondary),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18, color: _kSecondary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ..._upcomingBookings.map((b) => BookingCard(
              booking: b,
              onTap: () => _onBookingTap(b),
            )),
      ],
    );
  }
}

class _RecentSearch {
  final City origin;
  final City destination;
  _RecentSearch({required this.origin, required this.destination});
}
