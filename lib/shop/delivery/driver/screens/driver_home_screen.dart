// Driver Home Screen — the main screen for TAJIRI delivery drivers.
// Shows online/offline toggle and a live list of available nearby jobs.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/tajiri_delivery_models.dart';
import '../services/driver_service.dart';
import 'driver_active_delivery_screen.dart';
import 'driver_job_detail_screen.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kOnline = Color(0xFF2E7D32);
const Color _kOnlineBg = Color(0xFFE8F5E9);

class DriverHomeScreen extends StatefulWidget {
  final int userId;
  final String token;

  const DriverHomeScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = false;
  bool _togglingOnline = false;

  List<TajiriDeliveryJob> _availableJobs = [];
  bool _loadingJobs = false;
  String? _jobError;

  Timer? _refreshTimer;

  // ─── Driver profile (loaded lazily from active job or earnings) ──
  final String _driverName = 'Driver';
  final double _driverRating = 5.0;
  final int _totalDeliveries = 0;

  @override
  void initState() {
    super.initState();
    _checkActiveJob();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ─── Lifecycle ──────────────────────────────────────────────────

  Future<void> _checkActiveJob() async {
    final active = await DriverService.getActiveJob(widget.token, widget.userId);
    if (!mounted) return;
    if (active != null && active.isActive) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => DriverActiveDeliveryScreen(
            job: active,
            userId: widget.userId,
            token: widget.token,
          ),
        ),
      );
      if (!mounted) return;
      if (result == true) _checkActiveJob();
    }
  }

  Future<void> _toggleOnline() async {
    if (_togglingOnline) return;
    setState(() => _togglingOnline = true);

    final success = _isOnline
        ? await DriverService.goOffline(widget.token, widget.userId)
        : await DriverService.goOnline(widget.token, widget.userId);

    if (!mounted) return;
    if (success) {
      setState(() => _isOnline = !_isOnline);
      if (_isOnline) {
        _startRefresh();
      } else {
        _refreshTimer?.cancel();
        setState(() => _availableJobs = []);
      }
    } else {
      _showSnack('Could not update status — check connection');
    }
    setState(() => _togglingOnline = false);
  }

  void _startRefresh() {
    _fetchJobs();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchJobs(),
    );
  }

  Future<void> _fetchJobs() async {
    if (!mounted || !_isOnline) return;
    setState(() {
      _loadingJobs = true;
      _jobError = null;
    });
    try {
      final jobs =
          await DriverService.getAvailableJobs(widget.token, widget.userId);
      if (!mounted) return;
      setState(() {
        _availableJobs = jobs;
        _loadingJobs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingJobs = false;
        _jobError = 'Could not load jobs';
      });
    }
  }

  Future<void> _openJobDetail(TajiriDeliveryJob job) async {
    final accepted = await Navigator.push<TajiriDeliveryJob?>(
      context,
      MaterialPageRoute(
        builder: (_) => DriverJobDetailScreen(
          job: job,
          userId: widget.userId,
          token: widget.token,
        ),
      ),
    );
    if (!mounted) return;
    if (accepted != null) {
      // Driver accepted → go to active delivery
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => DriverActiveDeliveryScreen(
            job: accepted,
            userId: widget.userId,
            token: widget.token,
          ),
        ),
      );
      if (!mounted) return;
      if (result == true) _fetchJobs();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, maxLines: 2, overflow: TextOverflow.ellipsis),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── UI ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _OnlineToggleCard(
              isOnline: _isOnline,
              loading: _togglingOnline,
              onTap: _toggleOnline,
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _kSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _driverName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
              const SizedBox(width: 2),
              Text(
                _driverRating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                '$_totalDeliveries deliveries',
                style: const TextStyle(fontSize: 12, color: _kTertiary),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_isOnline)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kPrimary),
            onPressed: _fetchJobs,
            tooltip: 'Refresh jobs',
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kDivider),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isOnline) {
      return _OfflineEmptyState(onGoOnline: _toggleOnline);
    }

    if (_loadingJobs && _availableJobs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    if (_jobError != null && _availableJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_jobError!, style: const TextStyle(color: _kSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _fetchJobs, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_availableJobs.isEmpty) {
      return const _NoJobsEmptyState();
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _fetchJobs,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _availableJobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _JobCard(
          job: _availableJobs[i],
          onTap: () => _openJobDetail(_availableJobs[i]),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
            label: const Text('My Earnings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kDivider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // TODO: push EarningsScreen
            },
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

class _OnlineToggleCard extends StatelessWidget {
  final bool isOnline;
  final bool loading;
  final VoidCallback onTap;

  const _OnlineToggleCard({
    required this.isOnline,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isOnline ? _kOnlineBg : const Color(0xFFF5F5F5);
    final textColor = isOnline ? _kOnline : _kPrimary;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOnline ? _kOnline.withValues(alpha: 0.3) : _kDivider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? _kOnline : _kTertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOnline ? 'Online ●' : 'Go Online',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPrimary,
                ),
              )
            else
              Icon(
                isOnline
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                size: 36,
                color: isOnline ? _kOnline : _kTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _OfflineEmptyState extends StatelessWidget {
  final VoidCallback onGoOnline;
  const _OfflineEmptyState({required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.motorcycle_rounded,
              size: 72,
              color: _kTertiary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Go online to receive\ndelivery jobs',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toggle the switch above to start\nreceiving nearby delivery requests.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _kSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoJobsEmptyState extends StatelessWidget {
  const _NoJobsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: _kTertiary),
            SizedBox(height: 16),
            Text(
              'No jobs nearby right now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'New jobs appear automatically.\nPull down to refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _kSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final TajiriDeliveryJob job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price + vehicle row
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job.priceFormatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${job.weightKg.toStringAsFixed(1)} kg',
                    style:
                        const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  const Spacer(),
                  Text(
                    job.jobNumber,
                    style:
                        const TextStyle(fontSize: 12, color: _kTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Route
              _RouteRow(
                icon: Icons.radio_button_on_rounded,
                iconColor: _kOnline,
                label: 'Pickup',
                address: job.pickupAddress,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: SizedBox(
                  height: 12,
                  child: VerticalDivider(
                    width: 1,
                    color: _kDivider,
                    thickness: 1,
                  ),
                ),
              ),
              _RouteRow(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFFC62828),
                label: 'Dropoff',
                address: job.dropoffAddress,
              ),
              const SizedBox(height: 14),
              // Accept button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View & Accept',
                    style: TextStyle(fontWeight: FontWeight.w600),
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

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _kTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _kPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
