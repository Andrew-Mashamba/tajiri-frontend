// lib/tanesco/pages/tanesco_home_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';
import '../services/tanesco_service.dart';
import '../widgets/meter_card.dart';
import 'buy_tokens_page.dart';
import 'outage_center_page.dart';
import 'consumption_dashboard_page.dart';
import 'bills_page.dart';
import 'new_connection_page.dart';
import 'tariff_calculator_page.dart';
import 'energy_tips_page.dart';
import 'help_page.dart';
import 'my_meters_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class TanescoHomePage extends StatefulWidget {
  final int userId;
  const TanescoHomePage({super.key, required this.userId});
  @override
  State<TanescoHomePage> createState() => _TanescoHomePageState();
}

class _TanescoHomePageState extends State<TanescoHomePage> {
  List<Meter> _meters = [];
  List<Outage> _outages = [];
  List<TokenPurchase> _recentPurchases = [];
  List<PlannedMaintenance> _maintenance = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        TanescoService.getMyMeters(),
        TanescoService.getOutages(),
        TanescoService.getMaintenance(),
      ]);
      if (!mounted) return;

      final metersResult = results[0] as PaginatedResult<Meter>;
      final outagesResult = results[1] as PaginatedResult<Outage>;
      final maintenanceResult = results[2] as PaginatedResult<PlannedMaintenance>;

      setState(() {
        _loading = false;
        if (metersResult.success) _meters = metersResult.items;
        if (outagesResult.success) _outages = outagesResult.items;
        if (maintenanceResult.success) _maintenance = maintenanceResult.items;
      });

      // Load recent purchases for first meter
      if (_meters.isNotEmpty) {
        final histResult = await TanescoService.getTokenHistory(_meters.first.meterNumber);
        if (!mounted) return;
        if (histResult.success) setState(() => _recentPurchases = histResult.items);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  Future<void> _checkBalance(Meter meter) async {
    final messenger = ScaffoldMessenger.of(context);
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    try {
      final result = await TanescoService.checkBalance(meter.meterNumber);
      if (!mounted) return;
      if (result.success && result.data != null) {
        messenger.showSnackBar(SnackBar(
          content: Text(isSwahili
              ? 'Salio: ${result.data!.units.toStringAsFixed(1)} kWh'
              : 'Balance: ${result.data!.units.toStringAsFixed(1)} kWh')));
        _load();
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(result.message ?? (isSwahili ? 'Imeshindwa kuangalia salio' : 'Failed to check balance'))));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(isSwahili ? 'Imeshindwa kuangalia salio' : 'Failed to check balance')));
    }
  }

  List<Outage> get _activeOutages =>
      _outages.where((o) => o.status != 'fixed').toList();

  List<PlannedMaintenance> get _upcomingMaintenance =>
      _maintenance.where((m) => m.endDate.isAfter(DateTime.now())).toList();

  void _showAutoRechargeDialog(Meter meter) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    bool enabled = meter.autoRechargeEnabled;
    final thresholdCtrl = TextEditingController(
        text: meter.autoRechargeThreshold?.toStringAsFixed(0) ?? '');
    final amountCtrl = TextEditingController(
        text: meter.autoRechargeAmount?.toStringAsFixed(0) ?? '');
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Auto-Recharge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchListTile(
            title: Text(isSwahili ? 'Washa' : 'Enable', style: const TextStyle(fontSize: 13, color: _kPrimary)),
            value: enabled,
            activeColor: _kPrimary,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setDialogState(() => enabled = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: thresholdCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '10',
              labelText: isSwahili ? 'Kiwango cha chini (kWh)' : 'Threshold (kWh)',
              labelStyle: const TextStyle(fontSize: 12, color: _kSecondary),
              filled: true, fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            style: const TextStyle(fontSize: 14, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '10000',
              labelText: isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)',
              labelStyle: const TextStyle(fontSize: 12, color: _kSecondary),
              filled: true, fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            style: const TextStyle(fontSize: 14, color: _kPrimary),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(isSwahili ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary))),
          TextButton(onPressed: () async {
            final threshold = double.tryParse(thresholdCtrl.text.trim()) ?? 0;
            final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            final result = await TanescoService.setAutoRecharge(
                meter.meterNumber, threshold, amount, enabled);
            if (!mounted) return;
            if (result.success) {
              messenger.showSnackBar(SnackBar(
                  content: Text(isSwahili ? 'Auto-recharge imesasishwa' : 'Auto-recharge updated')));
              _load();
            } else {
              messenger.showSnackBar(SnackBar(
                  content: Text(result.message ?? (isSwahili ? 'Imeshindwa kusasisha' : 'Failed to update'))));
            }
          }, child: Text(isSwahili ? 'Hifadhi' : 'Save', style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))),
        ],
      ),
    ));
  }

  void _showSubmitReadingDialog(Meter meter) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final readingCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(isSwahili ? 'Tuma Usomaji' : 'Submit Reading',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: isSwahili ? 'Nambari ya Mita' : 'Meter Number',
            labelStyle: const TextStyle(fontSize: 12, color: _kSecondary),
            hintText: meter.meterNumber,
            filled: true, fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          controller: TextEditingController(text: meter.meterNumber),
          style: const TextStyle(fontSize: 14, color: _kSecondary),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: readingCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: isSwahili ? 'Usomaji wa sasa' : 'Current Reading',
            labelStyle: const TextStyle(fontSize: 12, color: _kSecondary),
            hintText: '0.0',
            filled: true, fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
        ),
        const SizedBox(height: 8),
        Text(isSwahili ? 'Picha ya mita itapatikana hivi karibuni' : 'Photo support coming soon',
            style: const TextStyle(fontSize: 11, color: _kSecondary)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary))),
        TextButton(onPressed: () async {
          final reading = double.tryParse(readingCtrl.text.trim());
          if (reading == null) return;
          Navigator.pop(ctx);
          final messenger = ScaffoldMessenger.of(context);
          final result = await TanescoService.submitMeterReading(
              meter.meterNumber, reading, null);
          if (!mounted) return;
          if (result.success) {
            messenger.showSnackBar(SnackBar(
                content: Text(isSwahili ? 'Usomaji umetumwa' : 'Reading submitted')));
          } else {
            messenger.showSnackBar(SnackBar(
                content: Text(result.message ?? (isSwahili ? 'Imeshindwa kutuma' : 'Failed to submit'))));
          }
        }, child: Text(isSwahili ? 'Tuma' : 'Submit', style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return RefreshIndicator(onRefresh: _load, color: _kPrimary,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Active outage banner
          if (_activeOutages.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OutageCenterPage())),
                child: Row(children: [
                  const Icon(Icons.flash_off_rounded, size: 20, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isSwahili ? 'Kukatika kwa umeme (${_activeOutages.length})' : 'Power outage (${_activeOutages.length})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(_activeOutages.first.location ?? (isSwahili ? 'Eneo lako' : 'Your area'),
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.red),
                ]),
              ),
            ),

          // Planned maintenance banner
          if (_upcomingMaintenance.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.engineering_rounded, size: 20, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isSwahili ? 'Matengenezo yaliyopangwa' : 'Planned maintenance',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${_upcomingMaintenance.first.area} - ${_upcomingMaintenance.first.description}',
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ),

          // Meter cards
          if (_meters.isNotEmpty)
            ...(_meters.take(2).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onLongPress: () => _showAutoRechargeDialog(m),
                child: MeterCardWidget(
                  meter: m,
                  onBuy: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => BuyTokensPage(meter: m)));
                    _load();
                  },
                  onCheckBalance: () => _checkBalance(m),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ConsumptionDashboardPage(meter: m))),
                ),
              ),
            )))
          else if (!_loading)
            Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Column(children: [
                const Icon(Icons.electric_bolt_rounded, size: 36, color: _kSecondary),
                const SizedBox(height: 8),
                Text(isSwahili ? 'Hakuna mita iliyounganishwa' : 'No meters connected',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                Text(isSwahili ? 'Ongeza mita yako kuanza' : 'Add your meter to get started', style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ])),
          const SizedBox(height: 16),

          // Quick actions grid - 2 rows of 4
          _buildActionGrid(),
          const SizedBox(height: 20),

          // Recent purchases
          if (_recentPurchases.isNotEmpty) ...[
            Text(isSwahili ? 'Manunuzi ya Hivi Karibuni' : 'Recent Purchases',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 8),
            ..._recentPurchases.take(3).map((p) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.electric_bolt_rounded, size: 16, color: _kPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TZS ${p.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  Text('${p.units.toStringAsFixed(1)} kWh - ${p.purchasedAt.day}/${p.purchasedAt.month}',
                      style: const TextStyle(fontSize: 11, color: _kSecondary)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.status == 'completed'
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(p.status == 'completed' ? 'OK' : p.status,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                          color: p.status == 'completed' ? const Color(0xFF4CAF50) : Colors.orange)),
                ),
              ]),
            )),
          ],

          if (_loading) const Padding(padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
          const SizedBox(height: 32),
        ]));
  }

  Widget _buildActionGrid() {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final actions = [
      _ActionItem(Icons.shopping_cart_rounded, isSwahili ? 'Nunua\nLUKU' : 'Buy\nTokens', () {
        if (_meters.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => BuyTokensPage(meter: _meters.first)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isSwahili ? 'Ongeza mita kwanza' : 'Add a meter first')));
        }
      }),
      _ActionItem(Icons.bar_chart_rounded, isSwahili ? 'Matumizi' : 'Usage', () {
        if (_meters.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => ConsumptionDashboardPage(meter: _meters.first)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isSwahili ? 'Ongeza mita kwanza' : 'Add a meter first')));
        }
      }),
      _ActionItem(Icons.flash_off_rounded, isSwahili ? 'Kukatika' : 'Outages', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OutageCenterPage()));
      }),
      _ActionItem(Icons.receipt_long_rounded, isSwahili ? 'Bili' : 'Bills', () {
        if (_meters.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => BillsPage(meter: _meters.first)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isSwahili ? 'Ongeza mita kwanza' : 'Add a meter first')));
        }
      }),
      _ActionItem(Icons.speed_rounded, isSwahili ? 'Mita' : 'Meters', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyMetersPage()));
      }),
      _ActionItem(Icons.edit_note_rounded, isSwahili ? 'Usomaji' : 'Reading', () {
        if (_meters.isNotEmpty) {
          _showSubmitReadingDialog(_meters.first);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isSwahili ? 'Ongeza mita kwanza' : 'Add a meter first')));
        }
      }),
      _ActionItem(Icons.add_circle_outline_rounded, isSwahili ? 'Muunganisho' : 'Connect', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConnectionPage()));
      }),
      _ActionItem(Icons.calculate_rounded, isSwahili ? 'Hesabu' : 'Calculator', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TariffCalculatorPage()));
      }),
      _ActionItem(Icons.lightbulb_outline_rounded, isSwahili ? 'Vidokezo' : 'Tips', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EnergyTipsPage()));
      }),
      _ActionItem(Icons.help_outline_rounded, isSwahili ? 'Msaada' : 'Help', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()));
      }),
    ];

    final rows = <Widget>[];
    for (int i = 0; i < actions.length; i += 4) {
      final rowItems = actions.sublist(i, i + 4 > actions.length ? actions.length : i + 4);
      final tiles = rowItems.map((a) => Expanded(child: _ActionTile(item: a))).toList();
      // Pad partial rows with empty Expanded to keep alignment
      while (tiles.length < 4) {
        tiles.add(const Expanded(child: SizedBox()));
      }
      if (i > 0) rows.add(const SizedBox(height: 8));
      rows.add(Row(children: tiles));
    }
    return Column(children: rows);
  }
}

class _ActionItem {
  final IconData icon; final String label; final VoidCallback onTap;
  _ActionItem(this.icon, this.label, this.onTap);
}

class _ActionTile extends StatelessWidget {
  final _ActionItem item;
  const _ActionTile({required this.item});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 20, color: _kPrimary),
            ),
            const SizedBox(height: 6),
            Text(item.label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    ),
  );
}
