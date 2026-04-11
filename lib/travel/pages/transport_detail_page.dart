import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import '../widgets/mode_icon.dart';
import 'passenger_info_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TransportDetailPage extends StatelessWidget {
  final TransportOption option;
  final int userId;
  final int passengers;

  const TransportDetailPage({
    super.key,
    required this.option,
    required this.userId,
    required this.passengers,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 60),
                color: _kPrimary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ModeIcon(mode: option.mode, size: 36, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      option.operator.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode + class badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ModeIcon(mode: option.mode, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              option.mode.displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (option.transportClass != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            option.transportClass!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _kSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Timeline: Departure → Duration → Arrival
                  _buildTimeline(),

                  const SizedBox(height: 24),

                  // Stations
                  _buildStations(),

                  const SizedBox(height: 20),

                  // Operator info
                  _sectionTitle('Mwendeshaji / Operator'),
                  const SizedBox(height: 8),
                  _infoRow('Jina / Name', option.operator.name),
                  if (option.operator.code != null)
                    _infoRow('Msimbo / Code', option.operator.code!),

                  const SizedBox(height: 20),

                  // Vehicle / mode-specific info
                  _buildVehicleInfo(),

                  // Amenities
                  if (option.amenities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle('Huduma / Amenities'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: option.amenities.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            a,
                            style: const TextStyle(fontSize: 13, color: _kPrimary),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Seats available
                  _buildSeatsIndicator(),

                  const SizedBox(height: 16),

                  // Provider
                  if (option.provider.isNotEmpty) ...[
                    _sectionTitle('Mtoa Huduma / Provider'),
                    const SizedBox(height: 8),
                    Text(
                      option.provider,
                      style: const TextStyle(fontSize: 14, color: _kSecondary),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PassengerInfoPage(
                      option: option,
                      userId: userId,
                      passengers: passengers,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Buking \u2014 ${option.price.formatted}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Departure
          Expanded(
            child: Column(
              children: [
                Text(
                  _formatTime(option.departure),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(option.departure),
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),

          // Duration
          Column(
            children: [
              Text(
                option.durationFormatted,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(height: 2, color: Colors.grey.shade300),
                    Icon(
                      ModeIcon.iconFor(option.mode),
                      size: 18,
                      color: _kPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (option.stops != null && option.stops! > 0)
                Text(
                  '${option.stops} stops',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                )
              else
                const Text(
                  'Direct',
                  style: TextStyle(fontSize: 11, color: _kSecondary),
                ),
            ],
          ),

          // Arrival
          Expanded(
            child: Column(
              children: [
                Text(
                  _formatTime(option.arrival),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(option.arrival),
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _stationRow(
            Icons.circle_outlined,
            option.origin.city,
            option.origin.station ?? option.origin.code,
            'Kuondoka / Departure',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(
              width: 1,
              height: 24,
              color: Colors.grey.shade300,
            ),
          ),
          _stationRow(
            Icons.location_on_rounded,
            option.destination.city,
            option.destination.station ?? option.destination.code,
            'Kufika / Arrival',
          ),
        ],
      ),
    );
  }

  Widget _stationRow(IconData icon, String city, String station, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              Text(
                '$station \u2022 $label',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo() {
    final items = <MapEntry<String, String>>[];

    if (option.flightNumber != null) {
      items.add(MapEntry('Nambari ya Ndege / Flight No.', option.flightNumber!));
    }
    if (option.baggageKg != null) {
      items.add(MapEntry('Mizigo / Baggage', '${option.baggageKg} kg'));
    }
    if (option.busType != null) {
      items.add(MapEntry('Aina ya Basi / Bus Type', option.busType!));
    }
    if (option.trainNumber != null) {
      items.add(MapEntry('Nambari ya Treni / Train No.', option.trainNumber!));
    }
    if (option.trainType != null) {
      items.add(MapEntry('Aina ya Treni / Train Type', option.trainType!));
    }
    if (option.vesselName != null) {
      items.add(MapEntry('Jina la Meli / Vessel', option.vesselName!));
    }
    if (option.vehicleInfo != null) {
      items.add(MapEntry('Gari / Vehicle', option.vehicleInfo!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Taarifa za Gari / Vehicle Info'),
        const SizedBox(height: 8),
        ...items.map((e) => _infoRow(e.key, e.value)),
      ],
    );
  }

  Widget _buildSeatsIndicator() {
    final seats = option.seatsAvailable;
    final Color seatColor;
    final String seatText;

    if (seats <= 0) {
      seatColor = Colors.red.shade700;
      seatText = 'Hakuna viti / No seats';
    } else if (seats <= 5) {
      seatColor = Colors.orange.shade700;
      seatText = 'Viti $seats tu vimebaki / Only $seats seats left';
    } else {
      seatColor = Colors.green.shade700;
      seatText = 'Viti $seats vinapatikana / $seats seats available';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: seatColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: seatColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_seat_rounded, color: seatColor, size: 20),
          const SizedBox(width: 10),
          Text(
            seatText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: seatColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _kPrimary,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
