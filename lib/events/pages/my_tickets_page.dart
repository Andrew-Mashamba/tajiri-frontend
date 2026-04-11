// lib/events/pages/my_tickets_page.dart
import 'package:flutter/material.dart';
import '../models/event_enums.dart';
import '../models/event_strings.dart';
import '../models/event_ticket.dart';
import '../services/ticket_service.dart';
import '../widgets/ticket_card.dart';
import 'ticket_detail_page.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MyTicketsPage extends StatefulWidget {
  final int userId;
  const MyTicketsPage({super.key, required this.userId});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage>
    with SingleTickerProviderStateMixin {
  final TicketService _service = TicketService();
  late TabController _tabController;
  late EventStrings _strings;

  // Per-tab state: all / upcoming / past
  final Map<TicketFilter, List<EventTicket>> _tickets = {
    TicketFilter.all: [],
    TicketFilter.upcoming: [],
    TicketFilter.past: [],
  };
  final Map<TicketFilter, bool> _loading = {
    TicketFilter.all: true,
    TicketFilter.upcoming: false,
    TicketFilter.past: false,
  };
  final Map<TicketFilter, int> _currentPage = {
    TicketFilter.all: 1,
    TicketFilter.upcoming: 1,
    TicketFilter.past: 1,
  };
  final Map<TicketFilter, bool> _hasMore = {
    TicketFilter.all: true,
    TicketFilter.upcoming: true,
    TicketFilter.past: true,
  };
  final ScrollController _scrollController = ScrollController();

  static const _filters = [TicketFilter.all, TicketFilter.upcoming, TicketFilter.past];

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTickets(TicketFilter.all);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final filter = _filters[_tabController.index];
    if (_tickets[filter]!.isEmpty && _loading[filter] != true) {
      _loadTickets(filter);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final filter = _filters[_tabController.index];
      if (_hasMore[filter] == true && _loading[filter] != true) {
        _loadMore(filter);
      }
    }
  }

  Future<void> _loadTickets(TicketFilter filter, {bool refresh = false}) async {
    if (refresh) {
      _currentPage[filter] = 1;
      _hasMore[filter] = true;
    }
    setState(() => _loading[filter] = true);
    final result = await _service.getMyTickets(
      filter: filter == TicketFilter.all ? null : filter,
      page: _currentPage[filter]!,
    );
    if (mounted) {
      setState(() {
        _loading[filter] = false;
        if (result.success) {
          if (refresh) {
            _tickets[filter] = result.items;
          } else {
            _tickets[filter]!.addAll(result.items);
          }
          _hasMore[filter] = result.currentPage < result.lastPage;
        }
      });
    }
  }

  Future<void> _loadMore(TicketFilter filter) async {
    _currentPage[filter] = _currentPage[filter]! + 1;
    await _loadTickets(filter);
  }

  void _openTicket(EventTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketDetailPage(userId: widget.userId, ticket: ticket),
      ),
    ).then((_) {
      if (mounted) {
        final filter = _filters[_tabController.index];
        _loadTickets(filter, refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_strings.myTickets,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
            const Text('My Tickets',
                style: TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: _strings.all),
            Tab(text: _strings.upcoming),
            Tab(text: _strings.past),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _filters.map((filter) => _buildTab(filter)).toList(),
      ),
    );
  }

  Widget _buildTab(TicketFilter filter) {
    final isLoading = _loading[filter] == true;
    final tickets = _tickets[filter]!;

    if (isLoading && tickets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(_strings.noTickets,
                style: const TextStyle(color: _kSecondary, fontSize: 15)),
            const Text('No tickets yet',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadTickets(filter, refresh: true),
      color: _kPrimary,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length + (_hasMore[filter] == true ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == tickets.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kPrimary)),
            );
          }
          return TicketCard(
            ticket: tickets[i],
            onTap: () => _openTicket(tickets[i]),
          );
        },
      ),
    );
  }
}
