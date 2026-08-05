// Driver Job Detail Screen — full details of a job before accepting.
// Returns the accepted TajiriDeliveryJob via Navigator.pop(job) on accept,
// or null on decline.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/tajiri_delivery_models.dart';
import '../services/driver_service.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kRed = Color(0xFFC62828);

class DriverJobDetailScreen extends StatefulWidget {
  final TajiriDeliveryJob job;
  final int userId;
  final String token;

  const DriverJobDetailScreen({
    super.key,
    required this.job,
    required this.userId,
    required this.token,
  });

  @override
  State<DriverJobDetailScreen> createState() => _DriverJobDetailScreenState();
}

class _DriverJobDetailScreenState extends State<DriverJobDetailScreen> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      final accepted = await DriverService.acceptJob(
        widget.token,
        widget.userId,
        widget.job.id,
      );
      if (!mounted) return;
      if (accepted != null) {
        Navigator.pop(context, accepted);
      } else {
        _showSnack('Could not accept job — try again');
        setState(() => _accepting = false);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Network error — please retry');
      setState(() => _accepting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, maxLines: 2, overflow: TextOverflow.ellipsis),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            Text(
              job.jobNumber,
              style: const TextStyle(fontSize: 12, color: _kTertiary),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kDivider),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Price highlight card
            _PriceCard(job: job),
            const SizedBox(height: 16),
            // Map preview
            if (job.pickupLat != null &&
                job.pickupLng != null &&
                job.dropoffLat != null &&
                job.dropoffLng != null)
              _MapPreview(
                pickupLat: job.pickupLat!,
                pickupLng: job.pickupLng!,
                dropoffLat: job.dropoffLat!,
                dropoffLng: job.dropoffLng!,
              ),
            const SizedBox(height: 16),
            // Pickup card
            _LocationCard(
              title: 'Pickup',
              name: job.pickupName,
              phone: job.pickupPhone,
              address: job.pickupAddress,
              iconColor: _kGreen,
            ),
            const SizedBox(height: 12),
            // Dropoff card
            _LocationCard(
              title: 'Dropoff',
              name: job.dropoffName,
              phone: job.dropoffPhone,
              address: job.dropoffAddress,
              iconColor: _kRed,
            ),
            const SizedBox(height: 12),
            // Package info
            _PackageInfoCard(job: job),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildActions(),
    );
  }

  Widget _buildActions() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _accepting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kDivider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _accepting ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _accepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Accept Job',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final TajiriDeliveryJob job;
  const _PriceCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery fee',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.priceFormatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Weight',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${job.weightKg.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;

  const _MapPreview({
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
  });

  String get _mapUrl {
    final center =
        '${((pickupLat + dropoffLat) / 2).toStringAsFixed(6)},${((pickupLng + dropoffLng) / 2).toStringAsFixed(6)}';
    const key = 'AIzaSyDToDgxzDtGb3ubCiLMmwRmyWNuR8972Hc';
    final markers =
        'markers=color:green%7C$pickupLat,$pickupLng&markers=color:red%7C$dropoffLat,$dropoffLng';
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$center&zoom=13&size=600x200&$markers&key=$key';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        _mapUrl,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: 160,
          color: _kDivider,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 36, color: _kTertiary),
                SizedBox(height: 8),
                Text(
                  'Map preview unavailable',
                  style: TextStyle(color: _kTertiary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 160,
            color: _kDivider,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _kPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String title;
  final String name;
  final String phone;
  final String address;
  final Color iconColor;

  const _LocationCard({
    required this.title,
    required this.name,
    required this.phone,
    required this.address,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_rounded, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTertiary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageInfoCard extends StatelessWidget {
  final TajiriDeliveryJob job;
  const _PackageInfoCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PACKAGE',
            style: TextStyle(
              fontSize: 11,
              color: _kTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Weight',
            value: '${job.weightKg.toStringAsFixed(1)} kg',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Declared value',
            value: job.itemValueTzs > 0
                ? 'TZS ${job.itemValueTzs.toStringAsFixed(0).replaceAllMapped(
                      RegExp(r'\B(?=(\d{3})+(?!\d))'),
                      (m) => ',',
                    )}'
                : '—',
          ),
          if (job.notes != null && job.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Notes', value: job.notes!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: _kPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
