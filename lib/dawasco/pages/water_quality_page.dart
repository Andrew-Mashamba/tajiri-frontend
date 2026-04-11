// lib/dawasco/pages/water_quality_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kGreen = Color(0xFF4CAF50);

class WaterQualityPage extends StatefulWidget {
  final String? wardId;
  const WaterQualityPage({super.key, this.wardId});
  @override
  State<WaterQualityPage> createState() => _WaterQualityPageState();
}

class _WaterQualityPageState extends State<WaterQualityPage> {
  List<WaterQualityReport> _reports = [];
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
      final result = await DawascoService.getWaterQuality(wardId: widget.wardId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.success) {
          _reports = result.items;
        } else {
          _error = result.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final hasUnsafe = _reports.any((r) => r.status == 'unsafe');

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Ubora wa Maji' : 'Water Quality',
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
                    // Safety advisory banner
                    if (hasUnsafe)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.warning_rounded, size: 22, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(sw ? 'Tahadhari ya Usalama' : 'Safety Advisory',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                    color: Colors.red)),
                            const SizedBox(height: 4),
                            Text(
                              sw ? 'Baadhi ya vigezo vya ubora wa maji viko nje ya kiwango salama. '
                                   'Chemsha maji kabla ya kunywa.'
                                 : 'Some water quality parameters are outside safe levels. '
                                   'Boil water before drinking.',
                              style: const TextStyle(fontSize: 12, color: _kPrimary),
                              maxLines: 4, overflow: TextOverflow.ellipsis,
                            ),
                          ])),
                        ]),
                      ),

                    if (_reports.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(child: Text(
                          sw ? 'Hakuna ripoti za ubora wa maji' : 'No water quality reports',
                          style: const TextStyle(color: _kSecondary, fontSize: 13),
                        )),
                      )
                    else
                      ..._reports.map((r) => _QualityCard(report: r, isSwahili: sw)),

                    const SizedBox(height: 32),
                  ]),
                ),
    );
  }
}

class _QualityCard extends StatelessWidget {
  final WaterQualityReport report;
  final bool isSwahili;
  const _QualityCard({required this.report, required this.isSwahili});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (report.status) {
      case 'unsafe':
        statusColor = Colors.red;
        statusLabel = isSwahili ? 'Hatari' : 'Unsafe';
        statusIcon = Icons.dangerous_rounded;
      case 'warning':
        statusColor = Colors.orange;
        statusLabel = isSwahili ? 'Tahadhari' : 'Warning';
        statusIcon = Icons.warning_rounded;
      default:
        statusColor = _kGreen;
        statusLabel = isSwahili ? 'Salama' : 'Safe';
        statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: 8),
          Expanded(child: Text(report.parameter.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(statusLabel,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _detail(isSwahili ? 'Eneo' : 'Area', report.area)),
          const SizedBox(width: 16),
          Expanded(child: _detail(isSwahili ? 'Thamani' : 'Value', report.value.toStringAsFixed(2))),
          const SizedBox(width: 16),
          Expanded(child: _detail(isSwahili ? 'Tarehe' : 'Date',
              '${report.testDate.day}/${report.testDate.month}/${report.testDate.year}')),
        ]),
        if (report.advisory != null) ...[
          const SizedBox(height: 8),
          Text(report.advisory!,
              style: TextStyle(fontSize: 11, color: statusColor, fontStyle: FontStyle.italic),
              maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }

  Widget _detail(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 9, color: _kSecondary)),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
  }
}
