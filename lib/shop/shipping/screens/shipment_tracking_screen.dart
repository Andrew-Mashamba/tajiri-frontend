import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);
const Color _kMuted = Color(0xFF999999);

class _TrackingStep {
  final String label;
  final String description;
  final IconData icon;
  DateTime? completedAt;
  bool isActive;

  _TrackingStep({
    required this.label,
    required this.description,
    required this.icon,
    this.completedAt,
    this.isActive = false,
  });
}

class ShipmentTrackingScreen extends StatefulWidget {
  const ShipmentTrackingScreen({
    super.key,
    this.orderId,
    this.trackingNumber,
  });

  final String? orderId;
  final String? trackingNumber;

  @override
  State<ShipmentTrackingScreen> createState() =>
      _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState extends State<ShipmentTrackingScreen> {
  final _trackingCtrl = TextEditingController();
  bool _loading = false;
  bool _hasResult = false;
  List<_TrackingStep> _steps = [];
  String _carrier = '';
  String _trackingId = '';
  String _estimatedDelivery = '';

  @override
  void initState() {
    super.initState();
    if (widget.trackingNumber != null) {
      _trackingCtrl.text = widget.trackingNumber!;
      _doTrack();
    } else if (widget.orderId != null) {
      _trackingCtrl.text = widget.orderId!;
      _doTrack();
    }
  }

  @override
  void dispose() {
    _trackingCtrl.dispose();
    super.dispose();
  }

  Future<void> _doTrack() async {
    final input = _trackingCtrl.text.trim();
    if (input.isEmpty) return;
    setState(() {
      _loading = true;
      _hasResult = false;
    });
    // Simulate network lookup
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _loading = false;
      _hasResult = true;
      _carrier = 'DHL Express Tanzania';
      _trackingId = input.toUpperCase();
      _estimatedDelivery =
          '${now.add(const Duration(days: 2)).day}/${now.add(const Duration(days: 2)).month}/${now.year}';
      _steps = [
        _TrackingStep(
          label: 'Order Placed',
          description: 'Your order was received',
          icon: Icons.shopping_bag_rounded,
          completedAt: now.subtract(const Duration(hours: 48)),
        ),
        _TrackingStep(
          label: 'Confirmed',
          description: 'Seller confirmed your order',
          icon: Icons.check_circle_rounded,
          completedAt: now.subtract(const Duration(hours: 46)),
        ),
        _TrackingStep(
          label: 'Processing',
          description: 'Item is being prepared',
          icon: Icons.inventory_2_rounded,
          completedAt: now.subtract(const Duration(hours: 24)),
        ),
        _TrackingStep(
          label: 'Shipped',
          description: 'Package picked up by carrier',
          icon: Icons.local_shipping_rounded,
          completedAt: now.subtract(const Duration(hours: 6)),
        ),
        _TrackingStep(
          label: 'Out for Delivery',
          description: 'Package is on the way',
          icon: Icons.directions_bike_rounded,
          isActive: true,
        ),
        _TrackingStep(
          label: 'Delivered',
          description: 'Package delivered to recipient',
          icon: Icons.home_rounded,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Track Shipment',
            style: TextStyle(
                color: _kText, fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 20),
              if (_loading) _buildLoader(),
              if (!_loading && _hasResult) ...[
                _buildDetailsCard(),
                const SizedBox(height: 20),
                const Text(
                  'Tracking Timeline',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kText),
                ),
                const SizedBox(height: 12),
                _buildTimeline(),
              ],
              if (!_loading && !_hasResult && _trackingCtrl.text.isEmpty)
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Tracking Number',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kSubtext),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trackingCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g. TZS-ORDER-1234',
                      hintStyle:
                          TextStyle(color: _kMuted, fontSize: 14),
                      prefixIcon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: _kMuted,
                          size: 20),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kText),
                      ),
                    ),
                    onSubmitted: (_) => _doTrack(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _doTrack,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: _kText,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Track',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: _kText),
            SizedBox(height: 16),
            Text('Fetching tracking info…',
                style: TextStyle(fontSize: 13, color: _kSubtext)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping_rounded,
                      color: _kSubtext, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _carrier,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _trackingId,
                        style:
                            const TextStyle(fontSize: 12, color: _kSubtext),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _DetailItem(
                    label: 'Status',
                    value: 'Out for Delivery',
                    valueColor: const Color(0xFF1565C0)),
                const SizedBox(width: 24),
                _DetailItem(
                    label: 'Est. Delivery', value: _estimatedDelivery),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: List.generate(_steps.length, (i) {
            final step = _steps[i];
            final isLast = i == _steps.length - 1;
            final isDone = step.completedAt != null;
            final isActive = step.isActive;

            return _TimelineStep(
              step: step,
              isDone: isDone,
              isActive: isActive,
              isLast: isLast,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.track_changes_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Track your shipment',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('Enter a tracking number to see live status',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  final _TrackingStep step;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color lineColor =
        isDone ? _kText : Colors.grey.shade200;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDone
                        ? _kText
                        : isActive
                            ? const Color(0xFF1565C0).withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(
                            color: const Color(0xFF1565C0), width: 2)
                        : null,
                  ),
                  child: Icon(
                    step.icon,
                    size: 18,
                    color: isDone
                        ? Colors.white
                        : isActive
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade400,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDone || isActive ? _kText : _kMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDone ? _kSubtext : _kMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (step.completedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(step.completedAt!),
                      style: const TextStyle(
                          fontSize: 11, color: _kMuted),
                    ),
                  ],
                  if (isActive) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'In Progress',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $h:$m';
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    this.valueColor = _kText,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: _kMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
