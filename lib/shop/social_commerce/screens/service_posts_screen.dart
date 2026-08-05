import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

enum _ServiceStatus { active, draft }

class _ServicePost {
  final String name;
  final String category;
  final String priceRange;
  final int bookings;
  final double rating;
  final _ServiceStatus status;
  final IconData icon;
  const _ServicePost(this.name, this.category, this.priceRange, this.bookings,
      this.rating, this.status, this.icon);
}

/// Manage service offering posts — list, filter, create.
class ServicePostsScreen extends StatefulWidget {
  const ServicePostsScreen({super.key});

  @override
  State<ServicePostsScreen> createState() => _ServicePostsScreenState();
}

class _ServicePostsScreenState extends State<ServicePostsScreen> {
  int _filterIdx = 0;
  final List<String> _filters = ['All', 'Active', 'Draft'];

  final List<_ServicePost> _allServices = const [
    _ServicePost(
        'Hair Braiding & Styling',
        'Beauty',
        'TZS 15,000 – 45,000',
        38,
        4.8,
        _ServiceStatus.active,
        Icons.face_retouching_natural_rounded),
    _ServicePost(
        'Tailoring & Alterations',
        'Fashion',
        'TZS 8,000 – 60,000',
        24,
        4.6,
        _ServiceStatus.active,
        Icons.checkroom_rounded),
    _ServicePost(
        'Photography (Events)',
        'Creative',
        'TZS 100,000 / day',
        12,
        4.9,
        _ServiceStatus.active,
        Icons.camera_alt_rounded),
    _ServicePost(
        'Home Cleaning',
        'Household',
        'TZS 20,000 – 50,000',
        9,
        4.4,
        _ServiceStatus.active,
        Icons.cleaning_services_rounded),
    _ServicePost(
        'Private Tutoring (Math)',
        'Education',
        'TZS 10,000 / hr',
        0,
        0.0,
        _ServiceStatus.draft,
        Icons.school_rounded),
    _ServicePost(
        'Catering & Cooking',
        'Food',
        'TZS 50,000+',
        0,
        0.0,
        _ServiceStatus.draft,
        Icons.restaurant_rounded),
  ];

  List<_ServicePost> get _filtered {
    switch (_filterIdx) {
      case 1:
        return _allServices
            .where((s) => s.status == _ServiceStatus.active)
            .toList();
      case 2:
        return _allServices
            .where((s) => s.status == _ServiceStatus.draft)
            .toList();
      default:
        return _allServices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _filtered;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Service Posts',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kText),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _kText,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'Create Service',
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
        child: Column(
          children: [
            _buildFilterRow(),
            Expanded(
              child: services.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: _kText,
                      onRefresh: () async => await Future.delayed(
                          const Duration(milliseconds: 600)),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: services.length,
                        separatorBuilder: (_, i) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) =>
                            _ServiceCard(service: services[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, i) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final selected = _filterIdx == i;
            return GestureDetector(
              onTap: () => setState(() => _filterIdx = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? _kText : _kBg,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                      color: selected ? _kText : _kDivider),
                ),
                child: Center(
                  child: Text(
                    _filters[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? _kSurface : _kMuted,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_repair_service_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No service posts',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 6),
          Text(
            'Offer your services to\nthousands of buyers.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});
  final _ServicePost service;

  @override
  Widget build(BuildContext context) {
    final isActive = service.status == _ServiceStatus.active;
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kDivider),
            ),
            child: Icon(service.icon, size: 26, color: _kText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kText),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Draft',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? const Color(0xFF388E3C)
                                : _kMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  service.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 12, color: _kMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  service.priceRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kText),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.book_online_rounded,
                        size: 12, color: _kFaint),
                    const SizedBox(width: 3),
                    Text(
                      '${service.bookings} bookings',
                      style: const TextStyle(
                          fontSize: 11, color: _kFaint),
                    ),
                    if (isActive && service.rating > 0) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded,
                          size: 12, color: Color(0xFFFFC107)),
                      const SizedBox(width: 2),
                      Text(
                        service.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 11, color: _kFaint),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 20, color: _kMuted),
            onSelected: (_) {},
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'boost', child: Text('Boost')),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }
}
