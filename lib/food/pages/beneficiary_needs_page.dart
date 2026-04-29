import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../models/beneficiary_org.dart';
import '../services/food_service.dart';
import 'beneficiary_profile_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);

class BeneficiaryNeedsPage extends StatefulWidget {
  final int userId;
  final String? initialWard;
  const BeneficiaryNeedsPage({super.key, required this.userId, this.initialWard});

  @override
  State<BeneficiaryNeedsPage> createState() => _BeneficiaryNeedsPageState();
}

class _BeneficiaryNeedsPageState extends State<BeneficiaryNeedsPage> {
  final FoodService _service = FoodService();
  final TextEditingController _wardController = TextEditingController();
  BeneficiaryOrgType? _typeFilter;
  List<Map<String, dynamic>> _needs = const [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.initialWard != null) _wardController.text = widget.initialWard!;
    _load();
  }

  @override
  void dispose() {
    _wardController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final res = await _service.listBeneficiaryNeeds(
      ward: _wardController.text.trim().isEmpty ? null : _wardController.text.trim(),
      type: _typeFilter?.apiValue,
      limit: 100,
    );
    if (!mounted) return;
    if (res.success) {
      setState(() {
        _needs = res.items;
        _loading = false;
      });
    } else {
      setState(() {
        _loadError = res.message ?? 'Imeshindwa kupakia mahitaji';
        _loading = false;
      });
    }
  }

  void _openOrg(int orgId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeneficiaryProfilePage(orgId: orgId, userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          'Saidia Sasa',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _wardController,
              style: const TextStyle(color: _kPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tafuta kwa kata...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.location_on_outlined, color: _kSecondary, size: 20),
                suffixIcon: _wardController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, color: _kSecondary, size: 18),
                        onPressed: () {
                          _wardController.clear();
                          _load();
                        },
                      ),
                filled: true,
                fillColor: _kCardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _load(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('Zote', _typeFilter == null, () {
                  setState(() => _typeFilter = null);
                  _load();
                }),
                const SizedBox(width: 8),
                ...BeneficiaryOrgType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _filterChip(t.labelSwahili, _typeFilter == t, () {
                        setState(() => _typeFilter = t);
                        _load();
                      }),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : _kPrimary)),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: _kCardBg,
      selectedColor: _kPrimary,
      side: BorderSide(color: _kPrimary.withValues(alpha: selected ? 0 : 0.12)),
      showCheckmark: false,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: _kSecondary),
              const SizedBox(height: 12),
              Text(_loadError!, style: const TextStyle(fontSize: 13, color: _kSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Jaribu tena')),
            ],
          ),
        ),
      );
    }
    if (_needs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volunteer_activism_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Hakuna mahitaji ya wazi kwa sasa',
                style: TextStyle(fontSize: 13, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _needs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _needCard(_needs[i]),
      ),
    );
  }

  Widget _needCard(Map<String, dynamic> need) {
    final title = need['title']?.toString() ?? 'Hitaji';
    final desc = need['description']?.toString() ?? '';
    final portionsNeeded = _parseInt(need['portions_needed']) ?? 0;
    final portionsFulfilled = _parseInt(need['portions_fulfilled']) ?? 0;
    final remaining = (portionsNeeded - portionsFulfilled).clamp(0, portionsNeeded);
    final progress = portionsNeeded == 0 ? 0.0 : (portionsFulfilled / portionsNeeded).clamp(0.0, 1.0);
    final dueDateStr = need['due_date']?.toString();
    final dueDate = dueDateStr == null ? null : DateTime.tryParse(dueDateStr);
    final orgName = need['org_name']?.toString() ?? 'Shirika';
    final orgType = BeneficiaryOrgTypeX.fromString(need['org_type']?.toString());
    final orgWard = need['org_ward']?.toString() ?? '';
    final orgDistrict = need['org_district']?.toString() ?? '';
    final orgPhotoUrl = need['org_photo_url']?.toString();
    final orgId = _parseInt(need['org_id']) ?? 0;

    final photoUrl = (orgPhotoUrl == null || orgPhotoUrl.isEmpty)
        ? ''
        : (orgPhotoUrl.startsWith('http')
            ? (ApiConfig.sanitizeUrl(orgPhotoUrl) ?? '')
            : (ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$orgPhotoUrl') ?? ''));

    final locParts = [orgWard, orgDistrict].where((p) => p.trim().isNotEmpty).toList();
    final location = locParts.join(', ');

    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openOrg(orgId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: photoUrl.isEmpty
                          ? Container(
                              color: _kPrimary.withValues(alpha: 0.06),
                              child: const Icon(Icons.volunteer_activism_rounded, color: _kPrimary, size: 22),
                            )
                          : CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                color: _kPrimary.withValues(alpha: 0.06),
                                child: const Icon(Icons.volunteer_activism_rounded, color: _kPrimary, size: 22),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orgName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${orgType.labelSwahili}${location.isEmpty ? '' : ' • $location'}',
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: _kPrimary.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(_kAccent),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$portionsFulfilled / $portionsNeeded milo',
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                  ),
                  if (dueDate != null)
                    Text(
                      'Hadi ${dueDate.day}/${dueDate.month}',
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openOrg(orgId),
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Tazama shirika'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: BorderSide(color: _kPrimary.withValues(alpha: 0.18)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openOrg(orgId),
                      icon: const Icon(Icons.favorite_outline_rounded, size: 16),
                      label: Text(remaining > 0 ? 'Changia' : 'Imekamilika'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
