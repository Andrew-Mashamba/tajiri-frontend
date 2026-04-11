// lib/service_garage/pages/service_garage_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/service_garage_models.dart';
import '../services/service_garage_service.dart';
import '../widgets/garage_card.dart';
import 'garage_detail_page.dart';
import 'book_service_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class ServiceGarageHomePage extends StatefulWidget {
  final int userId;
  const ServiceGarageHomePage({super.key, required this.userId});
  @override
  State<ServiceGarageHomePage> createState() => _ServiceGarageHomePageState();
}

class _ServiceGarageHomePageState extends State<ServiceGarageHomePage> {
  List<Garage> _garages = [];
  List<ServiceBooking> _bookings = [];
  bool _isLoading = true;
  String? _serviceFilter;
  late final bool _isSwahili;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final gRes = await ServiceGarageService.getGarages(
      search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text.trim() : null,
      serviceType: _serviceFilter,
    );
    final bRes = await ServiceGarageService.getMyBookings();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (gRes.success) _garages = gRes.items;
      if (bRes.success) _bookings = bRes.items;
    });
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _loadData(),
            decoration: InputDecoration(
              hintText:
                  _isSwahili ? 'Tafuta gereji...' : 'Search garages...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: _kSecondary),
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        // Service filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip(null, _isSwahili ? 'Zote' : 'All'),
              const SizedBox(width: 6),
              _filterChip('maintenance',
                  _isSwahili ? 'Matengenezo' : 'Maintenance'),
              const SizedBox(width: 6),
              _filterChip('repair', _isSwahili ? 'Ukarabati' : 'Repair'),
              const SizedBox(width: 6),
              _filterChip('body_work',
                  _isSwahili ? 'Bodi' : 'Body Work'),
              const SizedBox(width: 6),
              _filterChip('electrical',
                  _isSwahili ? 'Umeme' : 'Electrical'),
              const SizedBox(width: 6),
              _filterChip('tires', _isSwahili ? 'Matairi' : 'Tires'),
            ]),
          ),
        ),
        // Content
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kPrimary))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _kPrimary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Active bookings
                      if (_bookings.any((b) => b.isActive)) ...[
                        Text(
                            _isSwahili
                                ? 'Miadi Yangu'
                                : 'My Bookings',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary)),
                        const SizedBox(height: 8),
                        ..._bookings
                            .where((b) => b.isActive)
                            .map((b) => _bookingTile(b)),
                        const SizedBox(height: 16),
                      ],

                      // Garages
                      Text(
                          _isSwahili
                              ? 'Gereji za Karibu'
                              : 'Nearby Garages',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary)),
                      const SizedBox(height: 8),
                      if (_garages.isEmpty)
                        _emptyState()
                      else
                        ..._garages.map((g) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GarageCard(
                                garage: g,
                                isSwahili: _isSwahili,
                                onTap: () =>
                                    _nav(GarageDetailPage(garage: g)),
                              ),
                            )),
                    ],
                  ),
                ),
        ),
    ]);
  }

  Widget _filterChip(String? value, String label) {
    final selected = _serviceFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _serviceFilter = value);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _kPrimary : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : _kSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _bookingTile(ServiceBooking b) {
    final statusColor = b.status == 'in_progress'
        ? Colors.blue
        : b.status == 'confirmed'
            ? const Color(0xFF4CAF50)
            : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.build_rounded, size: 20, color: statusColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.serviceType,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(
                '${b.garageName} | ${b.appointmentDate.day}/${b.appointmentDate.month}',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(b.statusLabel,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor)),
        ),
      ]),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(children: [
          const Icon(Icons.build_rounded, size: 48, color: _kSecondary),
          const SizedBox(height: 12),
          Text(
              _isSwahili
                  ? 'Hakuna gereji zilizopatikana'
                  : 'No garages found',
              style: const TextStyle(fontSize: 14, color: _kSecondary)),
        ]),
      ),
    );
  }
}
