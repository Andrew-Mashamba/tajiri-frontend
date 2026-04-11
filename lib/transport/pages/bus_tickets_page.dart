// lib/transport/pages/bus_tickets_page.dart
import 'package:flutter/material.dart';
import '../models/transport_models.dart';
import '../services/transport_service.dart';
import '../widgets/bus_route_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BusTicketsPage extends StatefulWidget {
  final int userId;
  const BusTicketsPage({super.key, required this.userId});
  @override
  State<BusTicketsPage> createState() => _BusTicketsPageState();
}

class _BusTicketsPageState extends State<BusTicketsPage> {
  final TransportService _service = TransportService();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  List<BusRoute> _routes = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _searchRoutes() async {
    if (_fromController.text.trim().isEmpty || _toController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka mji wa kuanzia na kuishia')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final result = await _service.searchBusRoutes(
      from: _fromController.text.trim(),
      to: _toController.text.trim(),
      date: _selectedDate,
    );

    if (mounted) {
      setState(() {
        _isSearching = false;
        if (result.success) _routes = result.items;
      });
    }
  }

  Future<void> _bookTicket(BusRoute route) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nunua Tiketi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${route.from} -> ${route.to} | ${route.company}',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Jina la Abiria',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Namba ya Simu',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Nunua'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await _service.bookBusTicket(
        userId: widget.userId,
        busRouteId: route.id,
        passengerName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        paymentMethod: 'wallet',
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tiketi imenunuliwa!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Imeshindwa kunua tiketi')),
          );
        }
      }
    }

    nameController.dispose();
    phoneController.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
        title: const Text('Tiketi za Basi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search form
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _fromController,
                  decoration: InputDecoration(
                    hintText: 'Kutoka (mfano: Dar es Salaam)',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.trip_origin_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _toController,
                  decoration: InputDecoration(
                    hintText: 'Kwenda (mfano: Arusha)',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.place_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                        const SizedBox(width: 10),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 14, color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _searchRoutes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Tafuta Basi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          // Results
          if (_hasSearched) ...[
            const SizedBox(height: 20),
            Text(
              'Matokeo (${_routes.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 10),
            if (_routes.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Hakuna basi kwa njia hii', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                  ],
                ),
              )
            else
              ..._routes.map((route) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BusRouteCard(
                      route: route,
                      onBook: route.hasSeats ? () => _bookTicket(route) : null,
                    ),
                  )),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
