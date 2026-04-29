import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/beneficiary_org.dart';
import '../services/food_service.dart';
import 'beneficiary_profile_page.dart';
import 'register_beneficiary_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);

class BeneficiaryOrgsPage extends StatefulWidget {
  final int userId;
  /// When non-null, tapping an org pops with that org as the result.
  final bool pickerMode;
  const BeneficiaryOrgsPage({super.key, required this.userId, this.pickerMode = false});

  @override
  State<BeneficiaryOrgsPage> createState() => _BeneficiaryOrgsPageState();
}

class _BeneficiaryOrgsPageState extends State<BeneficiaryOrgsPage> {
  final FoodService _service = FoodService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<BeneficiaryOrg> _orgs = const [];
  bool _loading = true;
  BeneficiaryOrgType? _typeFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _service.listBeneficiaryOrgs(
      type: _typeFilter?.apiValue,
      q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) _orgs = res.items;
    });
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: Text(
          widget.pickerMode ? 'Chagua Shirika' : 'Mashirika ya Msaada',
          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
        ),
        actions: widget.pickerMode
            ? null
            : [
                IconButton(
                  tooltip: 'Sajili shirika',
                  icon: const Icon(Icons.add_rounded, color: _kPrimary),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterBeneficiaryPage(userId: widget.userId),
                      ),
                    );
                    if (mounted) _load();
                  },
                ),
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onQueryChanged,
                style: const TextStyle(color: _kPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Tafuta kwa jina...',
                  hintStyle: TextStyle(color: _kSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: _kSecondary, size: 20),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip(null, 'Zote'),
                ...BeneficiaryOrgType.values.map((t) => _chip(t, t.labelSwahili)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _orgs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Hamna mashirika', style: TextStyle(color: _kSecondary)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _orgs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _orgTile(_orgs[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BeneficiaryOrgType? t, String label) {
    final sel = _typeFilter == t;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        backgroundColor: _kCardBg,
        selectedColor: _kPrimary.withValues(alpha: 0.08),
        labelStyle: TextStyle(
          color: sel ? _kPrimary : _kSecondary,
          fontSize: 12,
          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
        ),
        side: BorderSide(color: _kPrimary.withValues(alpha: 0.08)),
        onSelected: (v) {
          setState(() => _typeFilter = v ? t : null);
          _load();
        },
      ),
    );
  }

  Widget _orgTile(BeneficiaryOrg org) {
    final photo = org.resolvedPhotoUrl;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (widget.pickerMode) {
          Navigator.pop(context, org);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BeneficiaryProfilePage(orgId: org.id, userId: widget.userId),
            ),
          );
          if (mounted) _load();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: photo.isEmpty
                    ? Container(
                        color: _kPrimary.withValues(alpha: 0.05),
                        child: const Icon(Icons.volunteer_activism_rounded, color: _kSecondary),
                      )
                    : CachedNetworkImage(
                        imageUrl: photo,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: _kPrimary.withValues(alpha: 0.05),
                          child: const Icon(Icons.volunteer_activism_rounded, color: _kSecondary),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          org.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary, fontSize: 14),
                        ),
                      ),
                      if (org.isVerified)
                        const Icon(Icons.verified_rounded, color: _kAccent, size: 16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    org.type.labelSwahili,
                    style: const TextStyle(color: _kSecondary, fontSize: 12),
                  ),
                  if (org.locationText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 12, color: _kSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            org.locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _kSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (org.populationServed != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Inahudumia watu ${org.populationServed}',
                      style: const TextStyle(color: _kSecondary, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
