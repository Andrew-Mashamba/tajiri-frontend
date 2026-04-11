// lib/dawasco/pages/new_connection_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kGreen = Color(0xFF4CAF50);

class NewConnectionPage extends StatefulWidget {
  const NewConnectionPage({super.key});
  @override
  State<NewConnectionPage> createState() => _NewConnectionPageState();
}

class _NewConnectionPageState extends State<NewConnectionPage> {
  String _type = 'domestic';
  final _locationCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  bool _submitting = false;
  bool _checkingStatus = false;
  final _appIdCtrl = TextEditingController();
  ConnectionApplication? _existingApp;

  // Document checklist
  final Map<String, bool> _documents = {
    'id_copy': false,
    'ownership_proof': false,
    'building_permit': false,
  };

  @override
  void dispose() {
    _locationCtrl.dispose();
    _wardCtrl.dispose();
    _appIdCtrl.dispose();
    super.dispose();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  String _docLabel(String key, bool sw) {
    switch (key) {
      case 'id_copy': return sw ? 'Nakala ya Kitambulisho' : 'ID Copy';
      case 'ownership_proof': return sw ? 'Uthibitisho wa Umiliki' : 'Ownership Proof';
      case 'building_permit': return sw ? 'Kibali cha Ujenzi' : 'Building Permit';
      default: return key;
    }
  }

  String _typeLabel(String type, bool sw) {
    switch (type) {
      case 'domestic': return sw ? 'Nyumbani' : 'Domestic';
      case 'commercial': return sw ? 'Biashara' : 'Commercial';
      case 'institutional': return sw ? 'Taasisi' : 'Institutional';
      default: return type;
    }
  }

  String _connectionFee(String type) {
    switch (type) {
      case 'domestic': return 'TZS 300,000';
      case 'commercial': return 'TZS 500,000';
      case 'institutional': return 'TZS 750,000';
      default: return 'TZS ---';
    }
  }

  Future<void> _apply() async {
    final sw = _sw;
    if (_locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw ? 'Weka eneo / anwani' : 'Enter location / address')));
      return;
    }
    if (_wardCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw ? 'Weka kata' : 'Enter ward')));
      return;
    }
    final checkedDocs = _documents.entries.where((e) => e.value).map((e) => e.key).toList();
    if (checkedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw ? 'Chagua angalau nyaraka moja' : 'Select at least one document')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await DawascoService.applyConnection({
        'type': _type,
        'location': _locationCtrl.text.trim(),
        'ward': _wardCtrl.text.trim(),
        'documents': checkedDocs,
      });
      if (!mounted) return;
      setState(() => _submitting = false);
      final messenger = ScaffoldMessenger.of(context);
      if (result.success) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw ? 'Maombi yamewasilishwa!' : 'Application submitted!')));
        Navigator.pop(context, true);
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(result.message ?? (sw ? 'Imeshindwa' : 'Failed'))));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _checkStatus() async {
    final id = int.tryParse(_appIdCtrl.text.trim());
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_sw ? 'Weka namba ya maombi' : 'Enter application ID')));
      return;
    }
    setState(() => _checkingStatus = true);
    try {
      final result = await DawascoService.getConnectionStatus(id);
      if (!mounted) return;
      setState(() {
        _checkingStatus = false;
        if (result.success) _existingApp = result.data;
      });
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.message ?? (_sw ? 'Hazijapatikana' : 'Not found'))));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _checkingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final statusSteps = ['pending', 'reviewing', 'approved', 'connected'];
    final statusLabels = sw
        ? ['Inasubiri', 'Inakaguliwa', 'Imeidhinishwa', 'Imeunganishwa']
        : ['Pending', 'Reviewing', 'Approved', 'Connected'];

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Muunganisho Mpya' : 'New Connection',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Check existing application
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Angalia Hali ya Maombi' : 'Check Application Status',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(
                controller: _appIdCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: sw ? 'Namba ya maombi' : 'Application ID',
                  hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                  filled: true, fillColor: _kBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 14, color: _kPrimary),
              )),
              const SizedBox(width: 8),
              SizedBox(height: 48, child: ElevatedButton(
                onPressed: _checkingStatus ? null : _checkStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _checkingStatus
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(sw ? 'Angalia' : 'Check', style: const TextStyle(color: Colors.white, fontSize: 13)),
              )),
            ]),
            if (_existingApp != null) ...[
              const SizedBox(height: 14),
              _buildStatusTracker(statusSteps, statusLabels, _existingApp!.status),
              const SizedBox(height: 8),
              Text('${sw ? 'Aina' : 'Type'}: ${_typeLabel(_existingApp!.type, sw)}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
        const SizedBox(height: 20),

        // New application form
        Text(sw ? 'Omba Muunganisho Mpya' : 'Apply for New Connection',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 16),

        // Connection type
        Text(sw ? 'Aina ya Muunganisho' : 'Connection Type',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: ['domestic', 'commercial', 'institutional'].map((t) =>
            ChoiceChip(
              label: Text(_typeLabel(t, sw),
                  style: TextStyle(fontSize: 12, color: _type == t ? Colors.white : _kPrimary)),
              selected: _type == t,
              onSelected: (_) => setState(() => _type = t),
              selectedColor: _kPrimary,
              backgroundColor: Colors.white,
            ),
        ).toList()),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${sw ? 'Ada ya muunganisho' : 'Connection fee'}: ${_connectionFee(_type)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary)),
        ),
        const SizedBox(height: 16),

        // Location
        Text(sw ? 'Anwani / Eneo' : 'Address / Location',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _locationCtrl,
          decoration: InputDecoration(
            hintText: sw ? 'Anwani kamili' : 'Full address',
            hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _wardCtrl,
          decoration: InputDecoration(
            hintText: sw ? 'Kata' : 'Ward',
            hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
        ),
        const SizedBox(height: 16),

        // Documents checklist
        Text(sw ? 'Nyaraka Zinazohitajika' : 'Required Documents',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        ..._documents.keys.map((key) => CheckboxListTile(
          value: _documents[key],
          onChanged: (v) => setState(() => _documents[key] = v ?? false),
          title: Text(_docLabel(key, sw), style: const TextStyle(fontSize: 13, color: _kPrimary)),
          activeColor: _kPrimary,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        )),
        const SizedBox(height: 24),

        SizedBox(
          height: 48, width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(sw ? 'Wasilisha Maombi' : 'Submit Application',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildStatusTracker(List<String> steps, List<String> labels, String current) {
    final currentIdx = steps.indexOf(current).clamp(0, steps.length - 1);
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final beforeIdx = i ~/ 2;
          return Expanded(child: Container(
            height: 2,
            color: beforeIdx < currentIdx ? _kGreen : _kPrimary.withValues(alpha: 0.15),
          ));
        }
        final idx = i ~/ 2;
        final done = idx <= currentIdx;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: done ? _kGreen.withValues(alpha: 0.15) : _kPrimary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: idx == currentIdx ? Border.all(color: _kGreen, width: 2) : null,
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 14, color: _kGreen)
                : Center(child: Text('${idx + 1}', style: TextStyle(fontSize: 10, color: _kPrimary.withValues(alpha: 0.4)))),
          ),
          const SizedBox(height: 4),
          Text(labels[idx], style: TextStyle(fontSize: 8, color: done ? _kPrimary : _kSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]);
      }),
    );
  }
}
