import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

class _ScheduledSession {
  final String title;
  final String date;
  final String time;
  final int productCount;
  final int estimatedViewers;
  const _ScheduledSession(this.title, this.date, this.time,
      this.productCount, this.estimatedViewers);
}

class _PastSession {
  final String title;
  final String date;
  final int views;
  final int productsSold;
  final String duration;
  const _PastSession(this.title, this.date, this.views,
      this.productsSold, this.duration);
}

/// Live shopping stream — launch, schedule and review sessions.
class LiveShoppingScreen extends StatefulWidget {
  const LiveShoppingScreen({super.key});

  @override
  State<LiveShoppingScreen> createState() => _LiveShoppingScreenState();
}

class _LiveShoppingScreenState extends State<LiveShoppingScreen> {
  bool _isLaunching = false;

  final List<_ScheduledSession> _scheduled = const [
    _ScheduledSession(
        'New Arrivals Drop', 'Sat 10 May 2026', '6:00 PM', 8, 300),
    _ScheduledSession(
        'Flash Sale Event', 'Sun 11 May 2026', '8:00 PM', 12, 500),
    _ScheduledSession(
        'Accessories Showcase', 'Mon 12 May 2026', '5:30 PM', 6, 200),
  ];

  final List<_PastSession> _past = const [
    _PastSession('Spring Collection Launch', '28 Apr 2026', 1240, 18, '42 min'),
    _PastSession('Easter Sale Stream', '14 Apr 2026', 890, 12, '35 min'),
    _PastSession('Kitenge Special', '2 Apr 2026', 2100, 27, '58 min'),
  ];

  Future<void> _goLive() async {
    setState(() => _isLaunching = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isLaunching = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live stream starting…')),
    );
  }

  void _scheduleSession() {
    final titleCtrl = TextEditingController();
    DateTime? pickedDate;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schedule Live Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Session title',
                  hintText: 'e.g. Flash Sale — New Arrivals',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: now.add(const Duration(days: 1)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 90)),
                  );
                  if (d != null) setModal(() => pickedDate = d);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFBDBDBD)), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF666666)),
                    const SizedBox(width: 10),
                    Text(
                      pickedDate == null ? 'Pick a date' : '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}',
                      style: TextStyle(color: pickedDate == null ? const Color(0xFF999999) : const Color(0xFF1A1A1A)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty || pickedDate == null) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Session "${titleCtrl.text.trim()}" scheduled for ${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}')),
                    );
                  },
                  child: const Text('Schedule Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 100), titleCtrl.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Live Shopping',
          style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kText),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _scheduleSession,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _kText,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'Schedule',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSurface),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kText,
          onRefresh: () async =>
              await Future.delayed(const Duration(milliseconds: 600)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPreviewArea(),
              const SizedBox(height: 20),
              _buildGoLiveButton(),
              const SizedBox(height: 28),
              _buildSectionHeader('Scheduled Sessions',
                  Icons.calendar_month_rounded),
              const SizedBox(height: 10),
              if (_scheduled.isEmpty)
                _EmptyCard(
                  icon: Icons.calendar_month_rounded,
                  message: 'No sessions scheduled',
                )
              else
                ..._scheduled.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ScheduledCard(session: s),
                    )),
              const SizedBox(height: 24),
              _buildSectionHeader(
                  'Past Sessions', Icons.history_rounded),
              const SizedBox(height: 10),
              if (_past.isEmpty)
                _EmptyCard(
                  icon: Icons.history_rounded,
                  message: 'No past sessions',
                )
              else
                ..._past.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PastSessionCard(session: s),
                    )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.live_tv_rounded, size: 56, color: Colors.white54),
                SizedBox(height: 10),
                Text(
                  'Camera preview',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                      letterSpacing: 0.4),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '● LIVE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoLiveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLaunching ? null : _goLive,
        icon: _isLaunching
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.live_tv_rounded, size: 20),
        label: Text(
          _isLaunching ? 'Starting…' : 'Go Live Now',
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kText,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kMuted,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _kText),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _kText),
        ),
      ],
    );
  }
}

class _ScheduledCard extends StatelessWidget {
  const _ScheduledCard({required this.session});
  final _ScheduledSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                size: 22, color: _kMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kText),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.date} · ${session.time}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_rounded,
                        size: 12, color: _kFaint),
                    const SizedBox(width: 3),
                    Text('${session.productCount} products',
                        style:
                            const TextStyle(fontSize: 11, color: _kFaint)),
                    const SizedBox(width: 10),
                    const Icon(Icons.people_rounded,
                        size: 12, color: _kFaint),
                    const SizedBox(width: 3),
                    Text('~${session.estimatedViewers} expected',
                        style:
                            const TextStyle(fontSize: 11, color: _kFaint)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18, color: _kMuted),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

class _PastSessionCard extends StatelessWidget {
  const _PastSessionCard({required this.session});
  final _PastSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_circle_rounded,
                size: 24, color: _kMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kText),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.date} · ${session.duration}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.visibility_rounded,
                        size: 12, color: _kFaint),
                    const SizedBox(width: 3),
                    Text('${session.views} views',
                        style:
                            const TextStyle(fontSize: 11, color: _kFaint)),
                    const SizedBox(width: 10),
                    const Icon(Icons.sell_rounded,
                        size: 12, color: _kFaint),
                    const SizedBox(width: 3),
                    Text('${session.productsSold} sold',
                        style:
                            const TextStyle(fontSize: 11, color: _kFaint)),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: _kText,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('View',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
