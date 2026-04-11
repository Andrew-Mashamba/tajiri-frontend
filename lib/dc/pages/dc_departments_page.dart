// lib/dc/pages/dc_departments_page.dart
import 'package:flutter/material.dart';
import '../models/dc_models.dart';
import '../services/dc_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DcDepartmentsPage extends StatefulWidget {
  final int districtId;
  const DcDepartmentsPage({super.key, required this.districtId});

  @override
  State<DcDepartmentsPage> createState() => _DcDepartmentsPageState();
}

class _DcDepartmentsPageState extends State<DcDepartmentsPage> {
  List<Department> _departments = [];
  bool _loading = true;
  final _service = DcService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getDepartments(widget.districtId);
    if (mounted) {
      setState(() {
        _departments = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text('Idara za Wilaya',
            style: TextStyle(color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _departments.isEmpty
              ? const Center(child: Text('Hakuna idara', style: TextStyle(color: _kSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _departments.length,
                  itemBuilder: (_, i) => _buildDept(_departments[i]),
                ),
    );
  }

  Widget _buildDept(Department dept) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dept.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
          if (dept.headName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.person_rounded, size: 16, color: _kSecondary),
              const SizedBox(width: 6),
              Text(dept.headName, style: const TextStyle(fontSize: 13, color: _kSecondary)),
            ]),
          ],
          if (dept.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.phone_rounded, size: 16, color: _kSecondary),
              const SizedBox(width: 6),
              Text(dept.phone, style: const TextStyle(fontSize: 13, color: _kSecondary)),
            ]),
          ],
          if (dept.services.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: dept.services.map((s) => Chip(
                label: Text(s, style: const TextStyle(fontSize: 11)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
