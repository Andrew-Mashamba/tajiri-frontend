// lib/ambulance/pages/insurance_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/local_storage_service.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';
import '../widgets/insurance_card_widget.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kGreen = Color(0xFF2E7D32);

class InsurancePage extends StatefulWidget {
  const InsurancePage({super.key});
  @override
  State<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends State<InsurancePage> {
  final AmbulanceService _service = AmbulanceService();
  final ImagePicker _picker = ImagePicker();
  List<InsuranceInfo> _insurances = [];
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isSaving = false;
  final TextEditingController _verifyCtrl = TextEditingController();
  InsuranceInfo? _verifyResult;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  @override
  void dispose() {
    _verifyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getInsuranceInfo();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) _insurances = result.items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _verifyInsurance() async {
    final policyNo = _verifyCtrl.text.trim();
    if (policyNo.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _verifyResult = null;
    });

    try {
      final result = await _service.verifyInsurance(policyNo);
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        if (result.success && result.data != null) {
          _verifyResult = result.data;
        }
      });
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili ? 'Haikupatikana' : 'Not found'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _addInsurance() async {
    final providerCtrl = TextEditingController();
    final policyCtrl = TextEditingController();
    final memberCtrl = TextEditingController();
    String? photoPath;
    String coverageType = 'Standard';

    final coverageTypes = ['Standard', 'Premium', 'Comprehensive', 'Basic'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(_isSwahili ? 'Ongeza Bima' : 'Add Insurance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: providerCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: _isSwahili ? 'Mtoa Bima' : 'Provider',
                    hintText: 'e.g. NHIF, AAR, Jubilee',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: policyCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText:
                        _isSwahili ? 'Nambari ya Sera' : 'Policy Number',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: memberCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: _isSwahili
                        ? 'Nambari ya Mwanachama'
                        : 'Member ID',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: coverageType,
                  decoration: InputDecoration(
                    labelText:
                        _isSwahili ? 'Aina ya Bima' : 'Coverage Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: coverageTypes
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => coverageType = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final img = await _picker.pickImage(
                          source: ImageSource.gallery, maxWidth: 1200);
                      if (img != null) {
                        setDialogState(() => photoPath = img.path);
                      }
                    },
                    icon: Icon(
                      photoPath != null
                          ? Icons.check_circle_rounded
                          : Icons.camera_alt_rounded,
                      size: 20,
                    ),
                    label: Text(
                      photoPath != null
                          ? (_isSwahili ? 'Picha imechaguliwa' : 'Photo selected')
                          : (_isSwahili ? 'Piga picha ya kadi' : 'Upload card photo'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Ghairi' : 'Cancel',
                  style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: Text(_isSwahili ? 'Hifadhi' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      providerCtrl.dispose();
      policyCtrl.dispose();
      memberCtrl.dispose();
      return;
    }

    final provider = providerCtrl.text.trim();
    final policy = policyCtrl.text.trim();
    final member = memberCtrl.text.trim();
    providerCtrl.dispose();
    policyCtrl.dispose();
    memberCtrl.dispose();

    if (provider.isEmpty || policy.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isSwahili
                ? 'Mtoa bima na nambari ya sera vinahitajika'
                : 'Provider and policy number are required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await _service.saveInsuranceInfo(
        provider: provider,
        policyNumber: policy,
        memberId: member.isNotEmpty ? member : null,
        coverageType: coverageType,
        cardPhotoPath: photoPath,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (result.success) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isSwahili ? 'Bima imehifadhiwa' : 'Insurance saved'),
              backgroundColor: _kPrimary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Bima' : 'Insurance',
          style:
              const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: _isSaving ? null : _addInsurance,
              icon: const Icon(Icons.add_rounded, color: _kPrimary),
              tooltip: _isSwahili ? 'Ongeza' : 'Add',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // NHIF Verification
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSwahili
                              ? 'Thibitisha Bima (NHIF)'
                              : 'Verify Insurance (NHIF)',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _verifyCtrl,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: _isSwahili
                                      ? 'Nambari ya sera'
                                      : 'Policy number',
                                  hintStyle: const TextStyle(
                                      fontSize: 13, color: _kSecondary),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 42,
                              child: FilledButton(
                                onPressed:
                                    _isVerifying ? null : _verifyInsurance,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _kPrimary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : Text(_isSwahili
                                        ? 'Thibitisha'
                                        : 'Verify'),
                              ),
                            ),
                          ],
                        ),
                        if (_verifyResult != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _kGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: _kGreen, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_verifyResult!.provider} - ${_verifyResult!.coverageType ?? "Active"}',
                                    style: const TextStyle(
                                        fontSize: 13, color: _kGreen),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Insurance cards
                  Text(
                    _isSwahili ? 'Kadi za Bima' : 'Insurance Cards',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (_insurances.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 48, color: _kSecondary),
                            const SizedBox(height: 12),
                            Text(
                              _isSwahili
                                  ? 'Hakuna bima iliyohifadhiwa'
                                  : 'No insurance cards saved',
                              style: const TextStyle(
                                  color: _kSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._insurances.map((ins) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InsuranceCardWidget(
                            insurance: ins,
                            isSwahili: _isSwahili,
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
