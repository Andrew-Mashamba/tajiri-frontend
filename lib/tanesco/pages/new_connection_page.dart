// lib/tanesco/pages/new_connection_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';
import '../services/tanesco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class NewConnectionPage extends StatefulWidget {
  const NewConnectionPage({super.key});
  @override
  State<NewConnectionPage> createState() => _NewConnectionPageState();
}

class _NewConnectionPageState extends State<NewConnectionPage> {
  final _addressCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  String _type = 'domestic';
  bool _submitting = false;
  ConnectionApplication? _submitted;
  List<ConnectionApplication> _myConnections = [];

  // Document checklist
  final Map<String, bool> _documents = {
    'national_id': false,
    'land_ownership': false,
    'building_permit': false,
  };

  static const _typeLabels = {
    'domestic': 'Nyumba / Domestic',
    'commercial': 'Biashara / Commercial',
    'industrial': 'Viwanda / Industrial',
  };

  static const _typeFees = {
    'domestic': 327150,
    'commercial': 455500,
    'industrial': 1250000,
  };

  static const _docLabels = {
    'national_id': 'Kitambulisho / National ID',
    'land_ownership': 'Hati ya Nyumba / Land Ownership',
    'building_permit': 'Kibali cha Ujenzi / Building Permit',
  };

  static const _statusSteps = ['applied', 'surveyed', 'approved', 'materials', 'connected'];
  @override
  void initState() { super.initState(); _loadConnections(); }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _regionCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    final result = await TanescoService.getMyConnections();
    if (!mounted) return;
    setState(() { if (result.success) _myConnections = result.items; });
  }

  Future<void> _submit() async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali ingiza anwani / Please enter address')));
      return;
    }
    final checkedDocs = _documents.entries.where((e) => e.value).map((e) => e.key).toList();
    if (checkedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali chagua nyaraka / Please select documents')));
      return;
    }

    setState(() => _submitting = true);
    final result = await TanescoService.applyConnection({
      'type': _type,
      'address': _addressCtrl.text.trim(),
      'region': _regionCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'documents': checkedDocs,
    });
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      setState(() => _submitted = result.data);
      _loadConnections();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kutuma')));
    }
  }

  int _statusIndex(String status) {
    final i = _statusSteps.indexOf(status);
    return i >= 0 ? i : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Muunganisho Mpya' : 'New Connection',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Existing connection applications
          if (_myConnections.isNotEmpty) ...[
            const Text('Maombi Yangu / My Applications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 8),
            ..._myConnections.map((c) => _ConnectionStatusCard(
              application: c,
              statusIndex: _statusIndex(c.status),
            )),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
          ],

          if (_submitted != null) ...[
            // Success view
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF4CAF50)),
                  const SizedBox(height: 12),
                  const Text('Ombi Limetumwa!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                  const Text('Application submitted successfully',
                      style: TextStyle(fontSize: 12, color: _kSecondary)),
                  if (_submitted!.referenceNumber != null) ...[
                    const SizedBox(height: 12),
                    Text('Ref: ${_submitted!.referenceNumber}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  ],
                  const SizedBox(height: 16),
                  _StatusTracker(currentIndex: _statusIndex(_submitted!.status)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48, width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _submitted = null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ombi Jipya / New Application'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Application form
            const Text('Aina ya Muunganisho / Connection Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            ..._typeLabels.entries.map((e) => RadioListTile<String>(
              title: Text(e.value, style: const TextStyle(fontSize: 13, color: _kPrimary)),
              subtitle: Text('TZS ${_typeFees[e.key]!.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary)),
              value: e.key, groupValue: _type,
              onChanged: (v) => setState(() => _type = v!),
              activeColor: _kPrimary, contentPadding: EdgeInsets.zero, dense: true,
            )),
            const SizedBox(height: 16),

            const Text('Mahali / Location',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            _buildField(_addressCtrl, 'Anwani / Address'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _buildField(_regionCtrl, 'Mkoa / Region')),
              const SizedBox(width: 8),
              Expanded(child: _buildField(_districtCtrl, 'Wilaya / District')),
            ]),
            const SizedBox(height: 16),

            const Text('Nyaraka / Documents',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 4),
            ..._docLabels.entries.map((e) => CheckboxListTile(
              title: Text(e.value, style: const TextStyle(fontSize: 13, color: _kPrimary)),
              value: _documents[e.key],
              onChanged: (v) => setState(() => _documents[e.key] = v ?? false),
              activeColor: _kPrimary, contentPadding: EdgeInsets.zero, dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            )),
            const SizedBox(height: 16),

            // Fee display
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: _kSecondary),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ada ya Muunganisho / Connection Fee',
                        style: TextStyle(fontSize: 11, color: _kSecondary)),
                    Text('TZS ${_typeFees[_type]!.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 48, width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Wasilisha Ombi / Submit Application',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      style: const TextStyle(fontSize: 14, color: _kPrimary),
    );
  }
}

class _StatusTracker extends StatelessWidget {
  final int currentIndex;
  const _StatusTracker({required this.currentIndex});

  static const _labels = ['Ombi', 'Ukaguzi', 'Kibali', 'Vifaa', 'Umeme'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final done = i <= currentIndex;
        final isLast = i == 4;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: done ? _kPrimary : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Center(child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600))),
                  ),
                  const SizedBox(height: 4),
                  Text(_labels[i], style: TextStyle(
                    fontSize: 8, color: done ? _kPrimary : _kSecondary,
                    fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
              if (!isLast) Expanded(
                child: Container(
                  height: 2, color: i < currentIndex ? _kPrimary : Colors.grey.shade300,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  final ConnectionApplication application;
  final int statusIndex;
  const _ConnectionStatusCard({required this.application, required this.statusIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(application.type.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
            ),
            const Spacer(),
            if (application.referenceNumber != null)
              Text(application.referenceNumber!,
                  style: const TextStyle(fontSize: 10, color: _kSecondary)),
          ]),
          const SizedBox(height: 8),
          Text(application.location,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          _StatusTracker(currentIndex: statusIndex),
        ],
      ),
    );
  }
}
