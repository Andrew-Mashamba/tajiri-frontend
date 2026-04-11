// lib/events/pages/event_map_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_strings.dart';
import '../../services/local_storage_service.dart';

class EventMapPage extends StatefulWidget {
  final String eventName;
  final String location;
  final double? lat;
  final double? lng;

  const EventMapPage({
    super.key,
    required this.eventName,
    required this.location,
    this.lat,
    this.lng,
  });

  @override
  State<EventMapPage> createState() => _EventMapPageState();
}

class _EventMapPageState extends State<EventMapPage> {
  late EventStrings _s;

  @override
  void initState() {
    super.initState();
    _s = const EventStrings(isSwahili: true);
    _initLang();
  }

  Future<void> _initLang() async {
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    if (mounted) setState(() { _s = EventStrings(isSwahili: lang == 'sw'); });
  }

  Future<void> _openInMaps() async {
    Uri uri;
    if (widget.lat != null && widget.lng != null) {
      final label = Uri.encodeComponent(widget.eventName);
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.lat},${widget.lng}&query_place_id=$label',
      );
    } else {
      final query = Uri.encodeComponent('${widget.eventName} ${widget.location}');
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_s.loadError),
            backgroundColor: const Color(0xFF1A1A1A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA);
    final fg = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1A1A1A);
    final surface = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        title: Text(_s.location, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Map placeholder
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: fg.withOpacity(0.08)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Grid pattern placeholder
                      CustomPaint(
                        painter: _MapGridPainter(color: fg.withOpacity(0.06)),
                        child: const SizedBox.expand(),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_rounded, size: 48, color: fg.withOpacity(0.35)),
                          const SizedBox(height: 8),
                          Text(
                            _s.location,
                            style: TextStyle(color: fg.withOpacity(0.4), fontSize: 13),
                          ),
                        ],
                      ),
                      if (widget.lat != null && widget.lng != null)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: fg.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.lat!.toStringAsFixed(4)}, ${widget.lng!.toStringAsFixed(4)}',
                              style: TextStyle(color: fg.withOpacity(0.5), fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Event name
              Text(
                widget.eventName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),

              // Location address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, size: 18, color: fg.withOpacity(0.55)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.location,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg.withOpacity(0.7), fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Open in Maps button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openInMaps,
                  icon: Icon(Icons.open_in_new_rounded, size: 18, color: bg),
                  label: Text(
                    'Open in Maps',
                    style: TextStyle(color: bg, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fg,
                    foregroundColor: bg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final Color color;
  const _MapGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => old.color != color;
}
