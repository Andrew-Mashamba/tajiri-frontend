// lib/dawasco/pages/tariff_info_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TariffInfoPage extends StatefulWidget {
  const TariffInfoPage({super.key});
  @override
  State<TariffInfoPage> createState() => _TariffInfoPageState();
}

class _TariffInfoPageState extends State<TariffInfoPage> {
  List<WaterTariff> _tariffs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await DawascoService.getTariffs();
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.success) {
          _tariffs = result.items;
        } else {
          _error = result.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  String _tierLabel(String tier, bool sw) {
    switch (tier) {
      case 'domestic': return sw ? 'Nyumbani' : 'Domestic';
      case 'commercial': return sw ? 'Biashara' : 'Commercial';
      case 'institutional': return sw ? 'Taasisi' : 'Institutional';
      default: return tier;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    // Group tariffs by tier
    final Map<String, List<WaterTariff>> grouped = {};
    for (final t in _tariffs) {
      grouped.putIfAbsent(t.tier, () => []).add(t);
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Bei za Maji' : 'Water Tariffs',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: _kSecondary, fontSize: 13),
                      maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: Text(sw ? 'Jaribu tena' : 'Retry',
                      style: const TextStyle(color: _kPrimary))),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    // Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded, size: 20, color: _kPrimary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          sw ? 'Bei za maji zinategemea aina ya muunganisho na kiwango cha matumizi.'
                              : 'Water tariffs are based on connection type and consumption tier.',
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 3, overflow: TextOverflow.ellipsis,
                        )),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    if (_tariffs.isEmpty)
                      Center(child: Text(sw ? 'Hakuna bei zinazopatikana' : 'No tariffs available',
                          style: const TextStyle(color: _kSecondary, fontSize: 13)))
                    else
                      ...grouped.entries.map((entry) {
                        final tier = entry.key;
                        final rates = entry.value;
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_tierLabel(tier, sw),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: Column(children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.06),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Row(children: [
                                  Expanded(flex: 2, child: Text(sw ? 'Kiwango (m\u00B3)' : 'Tier (m\u00B3)',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary))),
                                  Expanded(flex: 2, child: Text(sw ? 'Bei/m\u00B3' : 'Rate/m\u00B3',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                                      textAlign: TextAlign.right)),
                                ]),
                              ),
                              ...rates.map((r) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: _kPrimary.withValues(alpha: 0.06))),
                                ),
                                child: Row(children: [
                                  Expanded(flex: 2, child: Text(
                                    '${r.minM3.toStringAsFixed(0)} - ${r.maxM3 > 99999 ? '\u221E' : r.maxM3.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  )),
                                  Expanded(flex: 2, child: Text(
                                    'TZS ${r.ratePerM3.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                                    textAlign: TextAlign.right,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  )),
                                ]),
                              )),
                              if (rates.isNotEmpty && rates.first.standingCharge != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text(sw ? 'Ada ya kudumu' : 'Standing charge',
                                        style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                    Text('TZS ${rates.first.standingCharge!.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                                  ]),
                                ),
                            ]),
                          ),
                          const SizedBox(height: 20),
                        ]);
                      }),

                    // Standing charge explanation
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(sw ? 'Kuhusu Ada ya Kudumu' : 'About Standing Charge',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          sw ? 'Ada ya kudumu ni malipo ya kila mwezi yanayolipwa bila kujali kiwango cha matumizi. '
                               'Hii inasaidia kudumisha miundombinu ya maji.'
                              : 'The standing charge is a fixed monthly fee paid regardless of consumption. '
                                'This helps maintain water infrastructure.',
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 5, overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Minimum charge info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(sw ? 'Malipo ya Chini' : 'Minimum Charge',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          sw ? 'Kuna malipo ya chini kwa kila mwezi hata kama matumizi yako ni sifuri. '
                               'Angalia bei za daraja la kwanza hapo juu.'
                              : 'There is a minimum monthly charge even if your consumption is zero. '
                                'See the first tier rates above.',
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 5, overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
    );
  }
}
