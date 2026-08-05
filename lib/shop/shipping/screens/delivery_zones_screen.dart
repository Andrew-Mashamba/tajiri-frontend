import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);
const Color _kMuted = Color(0xFF999999);

class _DeliveryZone {
  final String id;
  String name;
  String coverage;
  double fee;
  int minDays;
  int maxDays;
  bool isActive;

  _DeliveryZone({
    required this.id,
    required this.name,
    required this.coverage,
    required this.fee,
    required this.minDays,
    required this.maxDays,
    this.isActive = true,
  });
}

class DeliveryZonesScreen extends StatefulWidget {
  const DeliveryZonesScreen({super.key});

  @override
  State<DeliveryZonesScreen> createState() => _DeliveryZonesScreenState();
}

class _DeliveryZonesScreenState extends State<DeliveryZonesScreen> {
  bool _loading = true;
  List<_DeliveryZone> _zones = [];

  @override
  void initState() {
    super.initState();
    _loadMock();
  }

  Future<void> _loadMock() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _zones = [
        _DeliveryZone(
          id: '1',
          name: 'Dar es Salaam',
          coverage: 'All Dar es Salaam regions',
          fee: 3000,
          minDays: 1,
          maxDays: 2,
          isActive: true,
        ),
        _DeliveryZone(
          id: '2',
          name: 'Upcountry',
          coverage: 'Dodoma, Morogoro, Iringa & more',
          fee: 8000,
          minDays: 3,
          maxDays: 5,
          isActive: true,
        ),
        _DeliveryZone(
          id: '3',
          name: 'Islands (Zanzibar)',
          coverage: 'Unguja & Pemba',
          fee: 12000,
          minDays: 2,
          maxDays: 4,
          isActive: false,
        ),
      ];
    });
  }

  void _showAddSheet() => _showZoneSheet(null);

  void _showZoneSheet(_DeliveryZone? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final coverageCtrl =
        TextEditingController(text: existing?.coverage ?? '');
    final feeCtrl =
        TextEditingController(text: existing?.fee.toStringAsFixed(0) ?? '');
    final minDaysCtrl =
        TextEditingController(text: existing?.minDays.toString() ?? '');
    final maxDaysCtrl =
        TextEditingController(text: existing?.maxDays.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                          color: _kText,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Text(
                    existing == null ? 'Add Delivery Zone' : 'Edit Zone',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kText),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SheetField(controller: nameCtrl, label: 'Zone Name'),
              const SizedBox(height: 12),
              _SheetField(
                  controller: coverageCtrl, label: 'Coverage Area'),
              const SizedBox(height: 12),
              _SheetField(
                controller: feeCtrl,
                label: 'Delivery Fee (TZS)',
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SheetField(
                        controller: minDaysCtrl,
                        label: 'Min Days',
                        inputType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetField(
                        controller: maxDaysCtrl,
                        label: 'Max Days',
                        inputType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final fee =
                        double.tryParse(feeCtrl.text.trim()) ?? 0;
                    final minD =
                        int.tryParse(minDaysCtrl.text.trim()) ?? 1;
                    final maxD =
                        int.tryParse(maxDaysCtrl.text.trim()) ?? 3;
                    Navigator.pop(ctx);
                    setState(() {
                      if (existing != null) {
                        existing.name = name;
                        existing.coverage = coverageCtrl.text.trim();
                        existing.fee = fee;
                        existing.minDays = minD;
                        existing.maxDays = maxD;
                      } else {
                        _zones.add(_DeliveryZone(
                          id:
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          coverage: coverageCtrl.text.trim(),
                          fee: fee,
                          minDays: minD,
                          maxDays: maxD,
                        ));
                      }
                    });
                  },
                  child: Text(
                    existing == null ? 'Add Zone' : 'Save Changes',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      coverageCtrl.dispose();
      feeCtrl.dispose();
      minDaysCtrl.dispose();
      maxDaysCtrl.dispose();
    });
  }

  void _showActions(_DeliveryZone zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _ActionItem(
              icon: Icons.edit_rounded,
              label: 'Edit Zone',
              onTap: () {
                Navigator.pop(ctx);
                _showZoneSheet(zone);
              },
            ),
            _ActionItem(
              icon: zone.isActive
                  ? Icons.toggle_off_rounded
                  : Icons.toggle_on_rounded,
              label: zone.isActive ? 'Disable Zone' : 'Enable Zone',
              onTap: () {
                Navigator.pop(ctx);
                setState(() => zone.isActive = !zone.isActive);
              },
            ),
            _ActionItem(
              icon: Icons.delete_rounded,
              label: 'Delete Zone',
              color: const Color(0xFFD32F2F),
              onTap: () {
                Navigator.pop(ctx);
                setState(
                    () => _zones.removeWhere((z) => z.id == zone.id));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No delivery zones configured',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('Add zones to define where you deliver',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Delivery Zones',
            style: TextStyle(
                color: _kText, fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _showAddSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _kText,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+ Add Zone',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kText,
          onRefresh: _loadMock,
          child: _loading
              ? _buildShimmer()
              : _zones.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _zones.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _ZoneCard(
                        zone: _zones[i],
                        onMoreTap: () => _showActions(_zones[i]),
                        onToggle: (v) =>
                            setState(() => _zones[i].isActive = v),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.onMoreTap,
    required this.onToggle,
  });

  final _DeliveryZone zone;
  final VoidCallback onMoreTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Text(
                    zone.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: zone.isActive,
                  onChanged: onToggle,
                  activeThumbColor: _kText,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                GestureDetector(
                  onTap: onMoreTap,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.more_vert_rounded,
                        color: _kMuted, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 14, color: _kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    zone.coverage,
                    style: const TextStyle(
                        fontSize: 12, color: _kSubtext),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.payments_rounded,
                  label: 'TZS ${zone.fee.toStringAsFixed(0)}',
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: '${zone.minDays}–${zone.maxDays} days',
                ),
                const Spacer(),
                if (!zone.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Inactive',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _kSubtext),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _kSubtext),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    this.inputType = TextInputType.text,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType inputType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _kText,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, color: color)),
      onTap: onTap,
      minLeadingWidth: 24,
    );
  }
}
