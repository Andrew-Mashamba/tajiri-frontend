import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';
import '../widgets/verification_step_card.dart';

class VerificationStatusPage extends StatefulWidget {
  const VerificationStatusPage({super.key});

  @override
  State<VerificationStatusPage> createState() => _VerificationStatusPageState();
}

class _VerificationStatusPageState extends State<VerificationStatusPage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  VerificationStatus? _status;
  bool _isLoading = true;
  String? _token;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final storage = await LocalStorageService.getInstance();
      _token = storage.getAuthToken();
      _userId = storage.getUser()?.userId;
      if (_token == null || _userId == null) return;
      final status = await TajirikaService.getVerificationStatus(_token!, _userId!);
      if (!mounted) return;
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    if (_token == null || _userId == null) return;
    try {
      final status = await TajirikaService.getVerificationStatus(_token!, _userId!);
      if (!mounted) return;
      setState(() => _status = status);
    } catch (_) {}
  }

  Color _overallColor(String overall) {
    switch (overall) {
      case 'verified':
        return const Color(0xFF4CAF50);
      case 'partial':
      case 'submitted':
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _overallIcon(String overall) {
    switch (overall) {
      case 'verified':
        return Icons.verified_rounded;
      case 'partial':
      case 'submitted':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  String _overallLabel(String overall, bool isSwahili) {
    switch (overall) {
      case 'verified':
        return isSwahili ? 'Imethibitishwa' : 'Fully Verified';
      case 'partial':
      case 'submitted':
        return isSwahili ? 'Imethibitishwa Sehemu' : 'Partially Verified';
      default:
        return isSwahili ? 'Inasubiriwa' : 'Pending';
    }
  }

  // ==================== NIDA SUBMISSION ====================

  void _showNidaDialog(bool isSwahili) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSwahili ? 'Wasilisha NIDA' : 'Submit NIDA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSwahili
                    ? 'Ingiza namba yako ya NIDA yenye tarakimu 20'
                    : 'Enter your 20-digit NIDA number',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 20,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: isSwahili ? 'Namba ya NIDA' : 'NIDA Number',
                  hintStyle: const TextStyle(color: _kSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kPrimary),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _submitNida(controller.text.trim(), ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(isSwahili ? 'Wasilisha' : 'Submit'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitNida(String number, BuildContext sheetContext) async {
    if (number.length != 20) {
      final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSwahili
              ? 'Namba ya NIDA lazima iwe tarakimu 20'
              : 'NIDA number must be 20 digits'),
        ),
      );
      return;
    }
    Navigator.of(sheetContext).pop();
    if (_token == null || _userId == null) return;
    try {
      final result = await TajirikaService.submitNidaVerification(_token!, _userId!, number);
      if (!mounted) return;
      final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? (isSwahili ? 'Imewasilishwa' : 'Submitted successfully')
              : (result.message ?? (isSwahili ? 'Imeshindwa' : 'Failed'))),
        ),
      );
      if (result.success) _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ==================== TIN SUBMISSION ====================

  void _showTinDialog(bool isSwahili) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSwahili ? 'Wasilisha TIN' : 'Submit TIN',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSwahili
                    ? 'Ingiza namba yako ya TIN yenye tarakimu 9'
                    : 'Enter your 9-digit TIN number',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 9,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: isSwahili ? 'Namba ya TIN' : 'TIN Number',
                  hintStyle: const TextStyle(color: _kSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kPrimary),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _submitTin(controller.text.trim(), ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(isSwahili ? 'Wasilisha' : 'Submit'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitTin(String number, BuildContext sheetContext) async {
    if (number.length != 9) {
      final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSwahili
              ? 'Namba ya TIN lazima iwe tarakimu 9'
              : 'TIN number must be 9 digits'),
        ),
      );
      return;
    }
    Navigator.of(sheetContext).pop();
    if (_token == null || _userId == null) return;
    try {
      final result = await TajirikaService.submitTinVerification(_token!, _userId!, number);
      if (!mounted) return;
      final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? (isSwahili ? 'Imewasilishwa' : 'Submitted successfully')
              : (result.message ?? (isSwahili ? 'Imeshindwa' : 'Failed'))),
        ),
      );
      if (result.success) _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ==================== PROFESSIONAL LICENSE SUBMISSION ====================

  void _showProfessionalDialog(bool isSwahili) {
    String? selectedType;
    File? selectedFile;
    final types = [
      'engineering',
      'medical',
      'legal',
      'accounting',
      'teaching',
      'other',
    ];
    final typeLabels = isSwahili
        ? [
            'Uhandisi',
            'Tiba',
            'Sheria',
            'Uhasibu',
            'Ualimu',
            'Nyingine',
          ]
        : [
            'Engineering',
            'Medical',
            'Legal',
            'Accounting',
            'Teaching',
            'Other',
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSwahili ? 'Wasilisha Leseni' : 'Submit License',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSwahili
                        ? 'Chagua aina na pakia picha ya leseni'
                        : 'Select type and upload license image',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      hintText: isSwahili ? 'Aina ya Leseni' : 'License Type',
                      hintStyle: const TextStyle(color: _kSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kPrimary),
                      ),
                    ),
                    items: List.generate(types.length, (i) {
                      return DropdownMenuItem(
                        value: types[i],
                        child: Text(typeLabels[i]),
                      );
                    }),
                    onChanged: (val) {
                      setSheetState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1920,
                        maxHeight: 1920,
                      );
                      if (picked != null) {
                        setSheetState(() => selectedFile = File(picked.path));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.upload_file_rounded,
                              color: _kSecondary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            selectedFile != null
                                ? (isSwahili ? 'Picha imechaguliwa' : 'Image selected')
                                : (isSwahili ? 'Chagua picha ya leseni' : 'Select license image'),
                            style: TextStyle(
                              fontSize: 13,
                              color: selectedFile != null ? _kPrimary : _kSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (selectedType != null && selectedFile != null)
                          ? () => _submitProfessional(selectedType!, selectedFile!, ctx)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(isSwahili ? 'Wasilisha' : 'Submit'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitProfessional(
      String type, File file, BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    if (_token == null || _userId == null) return;
    try {
      final result =
          await TajirikaService.submitProfessionalLicense(_token!, _userId!, type, file);
      if (!mounted) return;
      final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? (isSwahili ? 'Imewasilishwa' : 'Submitted successfully')
              : (result.message ?? (isSwahili ? 'Imeshindwa' : 'Failed'))),
        ),
      );
      if (result.success) _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ==================== BACKGROUND CHECK SUBMISSION ====================

  void _showBackgroundDialog(bool isSwahili) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            isSwahili ? 'Ukaguzi wa Historia' : 'Background Check',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          content: Text(
            isSwahili
                ? 'Kwa kuwasilisha, unakubali ukaguzi wa historia yako ya jinai. Hii inaweza kuchukua siku 3-5 za kazi.'
                : 'By submitting, you consent to a criminal background check. This may take 3-5 business days.',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                foregroundColor: _kSecondary,
                minimumSize: const Size(48, 48),
              ),
              child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitBackground(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isSwahili ? 'Nakubali' : 'I Agree'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitBackground(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    if (_token == null || _userId == null) return;
    try {
      final result = await TajirikaService.submitBackgroundCheck(_token!, _userId!);
      if (!mounted) return;
      final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? (isSwahili ? 'Imewasilishwa' : 'Submitted successfully')
              : (result.message ?? (isSwahili ? 'Imeshindwa' : 'Failed'))),
        ),
      );
      if (result.success) _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isSwahili ? 'Hali ya Uthibitisho' : 'Verification Status',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _refresh,
                color: _kPrimary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverallBanner(isSwahili),
                      const SizedBox(height: 20),
                      Text(
                        isSwahili ? 'Hatua za Uthibitisho' : 'Verification Steps',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildVerificationCards(isSwahili),
                      const SizedBox(height: 24),
                      _buildPeerVouchingCard(isSwahili),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildOverallBanner(bool isSwahili) {
    final overall = _status?.overall ?? 'pending';
    final color = _overallColor(overall);
    final icon = _overallIcon(overall);
    final label = _overallLabel(overall, isSwahili);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Kamilisha hatua zote ili kuwa mshirika aliyethibitishwa'
                : 'Complete all steps to become a verified partner',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVerificationCards(bool isSwahili) {
    if (_status == null) return [];
    final items = _status!.asList;
    final actions = <VoidCallback?>[
      () => _showNidaDialog(isSwahili),
      () => _showTinDialog(isSwahili),
      () => _showProfessionalDialog(isSwahili),
      () => _showBackgroundDialog(isSwahili),
    ];
    return List.generate(items.length, (i) {
      return VerificationStepCard(
        item: items[i],
        isSwahili: isSwahili,
        onAction: actions[i],
      );
    });
  }

  Widget _buildPeerVouchingCard(bool isSwahili) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_rounded, color: _kPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                isSwahili ? 'Udhamini wa Wenzako' : 'Peer Vouching',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSwahili
                ? 'Mshirika aliyethibitishwa anaweza kukudhamini ili kuharakisha mchakato wako wa uthibitisho. Shiriki wasifu wako na mshirika unayemjua.'
                : 'A verified partner can vouch for you to speed up your verification process. Share your profile with a partner you know.',
            style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _kSecondary, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isSwahili
                      ? 'Udhamini wa wenzako unaongeza alama za imani yako'
                      : 'Peer vouching adds to your trust score',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
