import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);
const Color _kMuted = Color(0xFF999999);

class _WarehouseLocation {
  final String id;
  String name;
  String address;
  String contact;
  bool isDefault;

  _WarehouseLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
    this.isDefault = false,
  });
}

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  bool _loading = true;
  List<_WarehouseLocation> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  Future<void> _loadMockData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _locations = [
        _WarehouseLocation(
          id: '1',
          name: 'Main Warehouse',
          address: 'Kariakoo Market, Dar es Salaam',
          contact: '+255 712 345 678',
          isDefault: true,
        ),
        _WarehouseLocation(
          id: '2',
          name: 'Mwanza Branch',
          address: 'Mwanza City Centre, Mwanza',
          contact: '+255 754 987 654',
        ),
      ];
    });
  }

  void _showAddSheet() {
    _showLocationSheet(null);
  }

  void _showEditSheet(_WarehouseLocation loc) {
    _showLocationSheet(loc);
  }

  void _showLocationSheet(_WarehouseLocation? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final contactCtrl = TextEditingController(text: existing?.contact ?? '');

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
                  existing == null ? 'Add Warehouse' : 'Edit Warehouse',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kText),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SheetField(controller: nameCtrl, label: 'Warehouse Name'),
            const SizedBox(height: 12),
            _SheetField(controller: addressCtrl, label: 'Address'),
            const SizedBox(height: 12),
            _SheetField(
                controller: contactCtrl,
                label: 'Contact Number',
                inputType: TextInputType.phone),
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
                  final address = addressCtrl.text.trim();
                  final contact = contactCtrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() {
                    if (existing != null) {
                      existing.name = name;
                      existing.address = address;
                      existing.contact = contact;
                    } else {
                      _locations.add(_WarehouseLocation(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        address: address,
                        contact: contact,
                      ));
                    }
                  });
                },
                child: Text(
                  existing == null ? 'Add Location' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      addressCtrl.dispose();
      contactCtrl.dispose();
    });
  }

  void _showActions(_WarehouseLocation loc) {
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
              label: 'Edit Location',
              onTap: () {
                Navigator.pop(ctx);
                _showEditSheet(loc);
              },
            ),
            if (!loc.isDefault)
              _ActionItem(
                icon: Icons.star_rounded,
                label: 'Set as Default',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    for (final l in _locations) {
                      l.isDefault = l.id == loc.id;
                    }
                  });
                },
              ),
            if (!loc.isDefault)
              _ActionItem(
                icon: Icons.delete_rounded,
                label: 'Delete Location',
                color: const Color(0xFFD32F2F),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _locations.removeWhere((l) => l.id == loc.id));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
              height: 160,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Container(
              height: 100,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 12),
          Container(
              height: 100,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Warehouses',
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
                  '+ Add Location',
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
          onRefresh: () async => _loadMockData(),
          child: _loading
              ? _buildShimmer()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMapPlaceholder(),
                      const SizedBox(height: 20),
                      const Text(
                        'Your Locations',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kText),
                      ),
                      const SizedBox(height: 10),
                      if (_locations.isEmpty) _buildEmpty(),
                      ..._locations
                          .map((loc) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _LocationCard(
                                  location: loc,
                                  onMoreTap: () => _showActions(loc),
                                ),
                              ))
                          ,
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Warehouse Locations Map',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            '${_locations.length} location${_locations.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.warehouse_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No locations added',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('Tap "+ Add Location" to get started',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.onMoreTap,
  });
  final _WarehouseLocation location;
  final VoidCallback onMoreTap;

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warehouse_rounded,
                  color: _kSubtext, size: 22),
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
                          location.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (location.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kText,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: _kMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location.address,
                          style: const TextStyle(
                              fontSize: 12, color: _kSubtext),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 14, color: _kMuted),
                      const SizedBox(width: 4),
                      Text(
                        location.contact,
                        style:
                            const TextStyle(fontSize: 12, color: _kSubtext),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onMoreTap,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.more_vert_rounded,
                    color: _kMuted, size: 20),
              ),
            ),
          ],
        ),
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
      title:
          Text(label, style: TextStyle(fontSize: 14, color: color)),
      onTap: onTap,
      minLeadingWidth: 24,
    );
  }
}
