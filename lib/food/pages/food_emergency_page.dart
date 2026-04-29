import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../models/food_emergency.dart';
import '../services/food_service.dart';
import 'beneficiary_profile_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kEmergency = Color(0xFFD32F2F);

class FoodEmergencyPage extends StatefulWidget {
  final int emergencyId;
  final int userId;
  const FoodEmergencyPage({
    super.key,
    required this.emergencyId,
    required this.userId,
  });

  @override
  State<FoodEmergencyPage> createState() => _FoodEmergencyPageState();
}

class _FoodEmergencyPageState extends State<FoodEmergencyPage> {
  final FoodService _service = FoodService();
  FoodEmergency? _emergency;
  List<Map<String, dynamic>> _orgs = const [];
  List<Map<String, dynamic>> _needs = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.getFoodEmergency(widget.emergencyId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      final data = res.data!;
      setState(() {
        _loading = false;
        _emergency = FoodEmergency.fromJson(
          (data['emergency'] as Map).cast<String, dynamic>(),
        );
        _orgs = ((data['orgs'] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
        _needs = ((data['needs'] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      });
    } else {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Imeshindwa kupakia';
      });
    }
  }

  void _openOrg(int orgId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeneficiaryProfilePage(
          orgId: orgId,
          userId: widget.userId,
        ),
      ),
    ).then((_) {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kEmergency,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dharura ya Chakula',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kEmergency))
            : _error != null
                ? _errorState()
                : _body(),
      ),
    );
  }

  Widget _errorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
              const SizedBox(height: 12),
              Text(
                _error ?? '',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _load,
                child: const Text('Jaribu tena'),
              ),
            ],
          ),
        ),
      );

  Widget _body() {
    final e = _emergency!;
    return RefreshIndicator(
      onRefresh: _load,
      color: _kEmergency,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(e),
          const SizedBox(height: 20),
          if (_needs.isNotEmpty) ...[
            _sectionTitle('Mahitaji ya haraka (${_needs.length})'),
            const SizedBox(height: 10),
            ..._needs.map(_needCard),
            const SizedBox(height: 20),
          ],
          if (_orgs.isNotEmpty) ...[
            _sectionTitle('Mashirika yaliyoathirika (${_orgs.length})'),
            const SizedBox(height: 10),
            ..._orgs.map(_orgCard),
            const SizedBox(height: 20),
          ],
          if (_orgs.isEmpty && _needs.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: _kSecondary),
                  SizedBox(height: 10),
                  Text(
                    'Hakuna mahitaji bado katika eneo hili',
                    style: TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(FoodEmergency e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kEmergency,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  e.severity.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (e.description != null && e.description!.isNotEmpty)
            Text(
              e.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                e.scopeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (e.activatedAt != null)
                Text(
                  _fmtDate(e.activatedAt!),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      );

  Widget _needCard(Map<String, dynamic> need) {
    final orgId = int.tryParse('${need['org_id'] ?? ''}') ?? 0;
    final title = need['title']?.toString() ?? 'Hitaji';
    final orgName = need['org_name']?.toString() ?? '';
    final portionsNeeded = int.tryParse('${need['portions_needed'] ?? 0}') ?? 0;
    final portionsFulfilled = int.tryParse('${need['portions_fulfilled'] ?? 0}') ?? 0;
    final progress = portionsNeeded > 0 ? (portionsFulfilled / portionsNeeded).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kEmergency.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
          if (orgName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(orgName, style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(_kEmergency),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$portionsFulfilled / $portionsNeeded sehemu',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
              const Spacer(),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kEmergency,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  onPressed: orgId == 0 ? null : () => _openOrg(orgId),
                  child: const Text('Changia sasa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orgCard(Map<String, dynamic> org) {
    final id = int.tryParse('${org['id'] ?? 0}') ?? 0;
    final name = org['name']?.toString() ?? 'Shirika';
    final type = org['type']?.toString() ?? '';
    final ward = org['ward']?.toString() ?? '';
    final photo = _resolvePhoto(org['photo_url']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: id == 0 ? null : () => _openOrg(id),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photo,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade200,
                        ),
                        errorWidget: (_, _, _) => Container(
                          width: 56,
                          height: 56,
                          color: _kPrimary.withValues(alpha: 0.06),
                          child: const Icon(Icons.volunteer_activism_rounded, color: _kSecondary),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: _kPrimary.withValues(alpha: 0.06),
                        child: const Icon(Icons.volunteer_activism_rounded, color: _kSecondary),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [if (type.isNotEmpty) type, if (ward.isNotEmpty) ward].join(' • '),
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _resolvePhoto(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    final storage = ApiConfig.storageUrl;
    return '$storage/$raw';
  }

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }
}
