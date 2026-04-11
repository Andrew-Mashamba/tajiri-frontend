// lib/nightlife/pages/venue_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/nightlife_models.dart';
import '../services/nightlife_service.dart';
import '../widgets/event_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class VenueDetailPage extends StatefulWidget {
  final Venue venue;
  const VenueDetailPage({super.key, required this.venue});
  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  List<NightlifeEvent> _events = [];
  bool _isLoading = true;
  bool _isSwahili = true;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final r = await NightlifeService.getVenueEvents(widget.venue.id);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _events = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia matukio'
                : 'Failed to load events')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.venue;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(v.name,
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Image
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              image: v.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(v.imageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: v.imageUrl == null
                ? const Center(
                    child: Icon(Icons.nightlife_rounded,
                        size: 48, color: _kSecondary))
                : null,
          ),
          const SizedBox(height: 16),

          // Info
          Row(
            children: [
              Expanded(
                child: Text(v.name,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary)),
              ),
              if (v.isOpen)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_isSwahili ? 'Wazi' : 'Open',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_rounded,
                size: 16, color: _kSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(v.address,
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text('${v.rating.toStringAsFixed(1)} (${v.reviewCount})',
                style: const TextStyle(fontSize: 13, color: _kPrimary)),
          ]),

          if (v.description != null) ...[
            const SizedBox(height: 12),
            Text(v.description!,
                style: const TextStyle(
                    fontSize: 14, color: _kPrimary, height: 1.5)),
          ],

          if (v.phone != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: v.phone);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              icon: const Icon(Icons.phone_rounded, size: 16),
              label: Text(_isSwahili ? 'Piga Simu' : 'Call'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Events
          Text(
            _isSwahili ? 'Matukio' : 'Events',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
          else if (_events.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: Text(
                  _isSwahili ? 'Hakuna matukio' : 'No upcoming events',
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                ),
              ),
            )
          else
            ..._events.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NightlifeEventCard(
                      event: e, isSwahili: _isSwahili),
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
