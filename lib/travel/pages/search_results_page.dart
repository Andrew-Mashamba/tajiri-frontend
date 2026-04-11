import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../widgets/transport_option_card.dart';
import '../widgets/mode_icon.dart';
import 'transport_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SearchResultsPage extends StatefulWidget {
  final City origin;
  final City destination;
  final String date;
  final int passengers;
  final int userId;

  const SearchResultsPage({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
    required this.passengers,
    required this.userId,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TravelService _service = TravelService();
  bool _isLoading = true;
  String? _error;

  List<TransportOption> _allResults = [];
  List<TransportOption> _filteredResults = [];

  TransportMode? _filterMode;
  _SortBy _sortBy = _SortBy.price;

  String? _cheapestId;
  String? _fastestId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _service.search(
      origin: widget.origin.code,
      destination: widget.destination.code,
      date: widget.date,
      passengers: widget.passengers,
      preferredMode: _filterMode?.name,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _allResults = result.items;
          _identifyBadges();
          _applyFilters();
        } else {
          _error = result.message;
          _allResults = [];
          _filteredResults = [];
        }
      });
    }
  }

  void _identifyBadges() {
    if (_allResults.isEmpty) return;
    TransportOption cheapest = _allResults.first;
    TransportOption fastest = _allResults.first;
    for (final opt in _allResults) {
      if (opt.price.amount < cheapest.price.amount) cheapest = opt;
      if (opt.duration < fastest.duration) fastest = opt;
    }
    _cheapestId = cheapest.id;
    _fastestId = fastest.id;
  }

  void _applyFilters() {
    var list = List<TransportOption>.from(_allResults);

    if (_filterMode != null) {
      list = list.where((o) => o.mode == _filterMode).toList();
    }

    switch (_sortBy) {
      case _SortBy.price:
        list.sort((a, b) => a.price.amount.compareTo(b.price.amount));
        break;
      case _SortBy.duration:
        list.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case _SortBy.departure:
        list.sort((a, b) => a.departure.compareTo(b.departure));
        break;
    }

    _filteredResults = list;
  }

  void _setFilter(TransportMode? mode) {
    setState(() {
      _filterMode = mode;
      _applyFilters();
    });
  }

  void _setSort(_SortBy sort) {
    setState(() {
      _sortBy = sort;
      _applyFilters();
    });
  }

  void _onOptionTap(TransportOption option) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransportDetailPage(
          option: option,
          userId: widget.userId,
          passengers: widget.passengers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.origin.code} \u2192 ${widget.destination.code}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '${widget.date} \u2022 ${widget.passengers} Abiria / Passengers',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSortRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(null, 'Zote', 'All'),
            const SizedBox(width: 8),
            _filterChip(TransportMode.bus, 'Basi', 'Bus'),
            const SizedBox(width: 8),
            _filterChip(TransportMode.flight, 'Ndege', 'Flight'),
            const SizedBox(width: 8),
            _filterChip(TransportMode.train, 'Treni', 'Train'),
            const SizedBox(width: 8),
            _filterChip(TransportMode.ferry, 'Feri', 'Ferry'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(TransportMode? mode, String label, String subtitle) {
    final selected = _filterMode == mode;
    return GestureDetector(
      onTap: () => _setFilter(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mode != null) ...[
              ModeIcon(mode: mode, size: 16, color: selected ? Colors.white : _kSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Text('Sort:', style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(width: 8),
          _sortChip(_SortBy.price, 'Bei', 'Price'),
          const SizedBox(width: 6),
          _sortChip(_SortBy.duration, 'Muda', 'Duration'),
          const SizedBox(width: 6),
          _sortChip(_SortBy.departure, 'Kuondoka', 'Departure'),
          const Spacer(),
          if (!_isLoading)
            Text(
              '${_filteredResults.length} results',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
        ],
      ),
    );
  }

  Widget _sortChip(_SortBy sort, String label, String subtitle) {
    final selected = _sortBy == sort;
    return GestureDetector(
      onTap: () => _setSort(sort),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _kPrimary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? _kPrimary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? _kPrimary : _kSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 14, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Jaribu Tena / Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: _kSecondary),
              const SizedBox(height: 12),
              const Text(
                'Hakuna safari zilizopatikana',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'No trips found',
                style: TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Jaribu tarehe tofauti au njia nyingine ya usafiri\nTry a different date or transport mode',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _filteredResults.length,
      itemBuilder: (_, i) {
        final opt = _filteredResults[i];
        return TransportOptionCard(
          option: opt,
          isCheapest: opt.id == _cheapestId,
          isFastest: opt.id == _fastestId,
          onTap: () => _onOptionTap(opt),
        );
      },
    );
  }
}

enum _SortBy { price, duration, departure }
