import 'package:flutter/material.dart';
import '../models/event_enums.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class EventFilterSheet extends StatefulWidget {
  final EventCategory? category;
  final EventPriceFilter? price;
  final String? dateFilter;
  final ValueChanged<Map<String, dynamic>> onApply;
  const EventFilterSheet({super.key, this.category, this.price, this.dateFilter, required this.onApply});

  @override
  State<EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends State<EventFilterSheet> {
  EventCategory? _category;
  EventPriceFilter _price = EventPriceFilter.all;
  String? _dateFilter;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _price = widget.price ?? EventPriceFilter.all;
    _dateFilter = widget.dateFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Chuja / Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 16),
          const Text('Bei / Price', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: EventPriceFilter.values.map((p) {
              final labels = {'all': 'Zote', 'free': 'Bure', 'paid': 'Lipia'};
              final isSelected = p == _price;
              return GestureDetector(
                onTap: () => setState(() => _price = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: isSelected ? _kPrimary : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                  child: Text(labels[p.name] ?? p.name, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : _kPrimary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Wakati / Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: {'today': 'Leo', 'tomorrow': 'Kesho', 'this_weekend': 'Wikendi', 'this_week': 'Wiki Hii', 'this_month': 'Mwezi Huu'}.entries.map((e) {
              final isSelected = e.key == _dateFilter;
              return GestureDetector(
                onTap: () => setState(() => _dateFilter = _dateFilter == e.key ? null : e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: isSelected ? _kPrimary : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                  child: Text(e.value, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : _kPrimary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply({'category': _category, 'price': _price, 'date_filter': _dateFilter});
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Tumia / Apply', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
