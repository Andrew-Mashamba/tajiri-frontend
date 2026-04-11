// lib/housing/pages/property_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/housing_models.dart';
import '../services/housing_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class PropertyDetailPage extends StatefulWidget {
  final Property property;
  final int userId;
  const PropertyDetailPage(
      {super.key, required this.property, required this.userId});
  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  final HousingService _service = HousingService();
  late Property _property;
  int _currentPhoto = 0;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _refreshDetail();
  }

  Future<void> _refreshDetail() async {
    final result = await _service.getPropertyDetail(_property.id);
    if (mounted && result.success && result.data != null) {
      setState(() => _property = result.data!);
    }
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final result = await _service.applyForProperty(
      userId: widget.userId,
      propertyId: _property.id,
    );
    if (mounted) {
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.success
                ? 'Ombi limetumwa!'
                : (result.message ?? 'Ombi limeshindwa'))),
      );
    }
  }

  Future<void> _callAgent() async {
    if (_property.agentPhone == null) return;
    final uri = Uri.parse('tel:${_property.agentPhone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsAppAgent() async {
    if (_property.agentPhone == null) return;
    final phone = _property.agentPhone!.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
        'Habari, nahitaji maelezo zaidi kuhusu: ${_property.title}');
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        slivers: [
          // Photo gallery
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _kPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: _property.photos.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          itemCount: _property.photos.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPhoto = i),
                          itemBuilder: (_, i) => Image.network(
                            _property.photos[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _kPrimary.withValues(alpha: 0.1),
                              child: const Icon(Icons.image_rounded,
                                  size: 48, color: _kSecondary),
                            ),
                          ),
                        ),
                        if (_property.photos.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _property.photos.length,
                                (i) => Container(
                                  width: i == _currentPhoto ? 20 : 8,
                                  height: 8,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: i == _currentPhoto
                                        ? Colors.white
                                        : Colors.white54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: _kPrimary.withValues(alpha: 0.1),
                      child: const Icon(Icons.home_rounded,
                          size: 64, color: _kSecondary)),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + price
                  Text(_property.title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary)),
                  const SizedBox(height: 4),
                  Text(_property.priceFormatted,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary)),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: _kSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _property.address ?? _property.location,
                          style: const TextStyle(
                              fontSize: 14, color: _kSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Details row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (_property.bedrooms != null)
                          _DetailChip(
                              icon: Icons.bed_rounded,
                              label: '${_property.bedrooms}',
                              subtitle: 'Vyumba'),
                        if (_property.bathrooms != null)
                          _DetailChip(
                              icon: Icons.bathtub_rounded,
                              label: '${_property.bathrooms}',
                              subtitle: 'Bafu'),
                        if (_property.areaSqm != null)
                          _DetailChip(
                              icon: Icons.square_foot_rounded,
                              label:
                                  '${_property.areaSqm!.toStringAsFixed(0)} m\u00B2',
                              subtitle: 'Eneo'),
                        _DetailChip(
                            icon: _property.type.icon,
                            label: _property.type.displayName,
                            subtitle: _property.type.subtitle),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (_property.description != null &&
                      _property.description!.isNotEmpty) ...[
                    const Text('Maelezo',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const SizedBox(height: 8),
                    Text(_property.description!,
                        style:
                            const TextStyle(fontSize: 14, color: _kSecondary, height: 1.5)),
                    const SizedBox(height: 16),
                  ],

                  // Amenities
                  if (_property.amenities.isNotEmpty) ...[
                    const Text('Huduma',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _property.amenities.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(a.icon, size: 16, color: _kPrimary),
                              const SizedBox(width: 6),
                              Text(a.displayName,
                                  style: const TextStyle(
                                      fontSize: 12, color: _kPrimary)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Agent info
                  if (_property.agentName != null) ...[
                    const Text('Wakala',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: _kPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_property.agentName!,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _kPrimary)),
                                if (_property.agentPhone != null)
                                  Text(_property.agentPhone!,
                                      style: const TextStyle(
                                          fontSize: 13, color: _kSecondary)),
                              ],
                            ),
                          ),
                          if (_property.agentPhone != null) ...[
                            IconButton(
                              onPressed: _callAgent,
                              icon: const Icon(Icons.phone_rounded,
                                  color: _kPrimary),
                            ),
                            IconButton(
                              onPressed: _whatsAppAgent,
                              icon: const Icon(Icons.chat_rounded,
                                  color: _kPrimary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Apply button
                  if (_property.isAvailable)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _applying ? null : _apply,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _applying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                _property.priceFrequency ==
                                        PriceFrequency.sale
                                    ? 'Wasiliana Kununua'
                                    : 'Omba Kupanga',
                                style: const TextStyle(fontSize: 16)),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  const _DetailChip(
      {required this.icon, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: _kPrimary),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        Text(subtitle,
            style: const TextStyle(fontSize: 11, color: _kSecondary)),
      ],
    );
  }
}
