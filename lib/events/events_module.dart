// lib/events/events_module.dart
import 'package:flutter/material.dart';
import 'pages/events_home_page.dart';
import 'services/event_cache_service.dart';
import 'services/event_database.dart';

class EventsModule extends StatefulWidget {
  final int userId;
  const EventsModule({super.key, required this.userId});

  @override
  State<EventsModule> createState() => _EventsModuleState();
}

class _EventsModuleState extends State<EventsModule> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      EventCacheService.instance.init(),
      EventDatabase.instance.database, // initialize SQLite
    ]);
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF1A1A1A),
        ),
      );
    }
    return EventsHomePage(userId: widget.userId);
  }
}
