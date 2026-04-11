import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/location_models.dart';
import '../../services/local_storage_service.dart';
import '../../services/location_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';
import '../widgets/skill_category_chip.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  static const int _totalSteps = 7;

  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Personal Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  // Step 2: Skills
  final Set<SkillCategory> _selectedSkills = {};

  // Step 3: ID Verification
  final _nidaController = TextEditingController();
  final _tinController = TextEditingController();

  // Step 4: Professional License
  File? _licenseFile;
  String _licenseType = 'VETA';
  final List<String> _licenseTypes = [
    'VETA',
    'TLS',
    'Medical Council',
    'BRELA',
    'Other',
  ];

  // Step 5: Portfolio
  final List<File> _portfolioFiles = [];
  final List<String> _portfolioCaptions = [];

  // Step 6: Service Area (from database)
  List<Region> _regions = [];
  List<District> _districts = [];
  List<Ward> _wards = [];
  Region? _selectedRegion;
  District? _selectedDistrict;
  Ward? _selectedWard;
  bool _isLoadingRegions = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;

  // Step 7: Terms
  bool _termsAccepted = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    _loadRegions();
  }

  Future<void> _prefillUserData() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final user = storage.getUser();
      if (!mounted) return;
      if (user != null) {
        final firstName = user.firstName ?? '';
        final lastName = user.lastName ?? '';
        _nameController.text = '$firstName $lastName'.trim();
        _phoneController.text = user.phoneNumber ?? '';
      }
    } catch (e) {
      debugPrint('[RegistrationPage] prefill error: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _nidaController.dispose();
    _tinController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep(bool isSwahili) {
    switch (_currentStep) {
      case 0: // Personal Info
        if (_nameController.text.trim().isEmpty) {
          _showError(isSwahili
              ? 'Tafadhali ingiza jina lako'
              : 'Please enter your name');
          return false;
        }
        if (_phoneController.text.trim().isEmpty) {
          _showError(isSwahili
              ? 'Tafadhali ingiza namba ya simu'
              : 'Please enter your phone number');
          return false;
        }
        return true;

      case 1: // Skills
        if (_selectedSkills.isEmpty) {
          _showError(isSwahili
              ? 'Chagua angalau ujuzi mmoja'
              : 'Select at least one skill');
          return false;
        }
        return true;

      case 2: // ID Verification
        if (_nidaController.text.trim().isEmpty) {
          _showError(isSwahili
              ? 'Tafadhali ingiza namba ya NIDA'
              : 'Please enter your NIDA number');
          return false;
        }
        if (_nidaController.text.trim().length > 20) {
          _showError(isSwahili
              ? 'Namba ya NIDA isizidi tarakimu 20'
              : 'NIDA number must not exceed 20 digits');
          return false;
        }
        if (_tinController.text.trim().isNotEmpty &&
            _tinController.text.trim().length != 9) {
          _showError(isSwahili
              ? 'Namba ya TIN iwe tarakimu 9'
              : 'TIN number must be 9 digits');
          return false;
        }
        return true;

      case 3: // License (optional — can skip)
        return true;

      case 4: // Portfolio (optional — can skip)
        return true;

      case 5: // Service Area
        if (_selectedRegion == null) {
          _showError(isSwahili
              ? 'Tafadhali chagua mkoa'
              : 'Please select a region');
          return false;
        }
        if (_selectedDistrict == null) {
          _showError(isSwahili
              ? 'Tafadhali chagua wilaya'
              : 'Please select a district');
          return false;
        }
        return true;

      case 6: // Terms
        if (!_termsAccepted) {
          _showError(isSwahili
              ? 'Tafadhali kubali masharti'
              : 'Please accept the terms');
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _nextStep() {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    if (!_validateCurrentStep(isSwahili)) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    if (!_validateCurrentStep(isSwahili)) return;

    setState(() => _isSubmitting = true);

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (!mounted) return;

      if (token == null || token.isEmpty || userId == null) {
        _showError(isSwahili
            ? 'Haujaingia — tafadhali ingia tena'
            : 'Not logged in — please log in again');
        setState(() => _isSubmitting = false);
        return;
      }

      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final data = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'skills': _selectedSkills.map((s) => s.name).toList(),
        'nida_number': _nidaController.text.trim(),
        if (_tinController.text.trim().isNotEmpty)
          'tin_number': _tinController.text.trim(),
        if (_licenseFile != null) 'license_type': _licenseType,
        'region_id': _selectedRegion!.id,
        'region': _selectedRegion!.name,
        'district_id': _selectedDistrict!.id,
        'district': _selectedDistrict!.name,
        if (_selectedWard != null) 'ward_id': _selectedWard!.id,
        if (_selectedWard != null) 'ward': _selectedWard!.name,
        'payout_method': 'wallet',
        'terms_accepted': true,
      };

      final result = await TajirikaService.registerPartner(token, userId, data);
      if (!mounted) return;

      if (result.success) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSwahili
                  ? 'Usajili umefanikiwa!'
                  : 'Registration successful!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError(result.message ??
            (isSwahili ? 'Imeshindwa kusajili' : 'Registration failed'));
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(isSwahili
          ? 'Hitilafu: $e'
          : 'Error: $e');
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickLicenseFile() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (picked != null) {
        setState(() => _licenseFile = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error picking file: $e');
    }
  }

  Future<void> _pickPortfolioImage() async {
    if (_portfolioFiles.length >= 10) {
      final s = AppStringsScope.of(context);
      final isSwahili = s?.isSwahili ?? false;
      _showError(isSwahili
          ? 'Upeo wa picha 10 umefikiwa'
          : 'Maximum of 10 photos reached');
      return;
    }
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          _portfolioFiles.add(File(picked.path));
          _portfolioCaptions.add('');
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error picking image: $e');
    }
  }

  // ==================== LOCATION LOADING ====================

  final _locationService = LocationService(baseUrl: ApiConfig.baseUrl);

  Future<void> _loadRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final regions = await _locationService.getRegions();
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRegions = false);
    }
  }

  Future<void> _loadDistricts(int regionId) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _wards = [];
      _selectedDistrict = null;
      _selectedWard = null;
    });
    try {
      final districts = await _locationService.getDistricts(regionId);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _loadWards(int districtId) async {
    setState(() {
      _isLoadingWards = true;
      _wards = [];
      _selectedWard = null;
    });
    try {
      final wards = await _locationService.getWards(districtId);
      if (!mounted) return;
      setState(() {
        _wards = wards;
        _isLoadingWards = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingWards = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isSwahili ? 'Jiunge na Tajirika' : 'Join Tajirika',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSwahili
                        ? 'Hatua ${_currentStep + 1} ya $_totalSteps'
                        : 'Step ${_currentStep + 1} of $_totalSteps',
                    style: const TextStyle(
                      color: _kSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_kPrimary),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1PersonalInfo(isSwahili),
                  _buildStep2Skills(isSwahili),
                  _buildStep3IdVerification(isSwahili),
                  _buildStep4License(isSwahili),
                  _buildStep5Portfolio(isSwahili),
                  _buildStep6ServiceArea(isSwahili),
                  _buildStep7Terms(isSwahili),
                ],
              ),
            ),

            // Bottom buttons
            _buildBottomButtons(isSwahili),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildBottomButtons(bool isSwahili) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _prevStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isSwahili ? 'Rudi' : 'Back',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : (isLastStep ? _submit : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isLastStep
                            ? (isSwahili ? 'Wasilisha' : 'Submit')
                            : (isSwahili ? 'Endelea' : 'Next'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP BUILDERS ====================

  Widget _buildStep1PersonalInfo(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Taarifa Binafsi' : 'Personal Information',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Taarifa hizi zimetoka kwenye akaunti yako ya TAJIRI'
                : 'This info is pre-filled from your TAJIRI profile',
            style: const TextStyle(color: _kSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          _buildLabel(isSwahili ? 'Jina Kamili' : 'Full Name'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: isSwahili ? 'Jina la kwanza na la mwisho' : 'First and last name',
          ),
          const SizedBox(height: 16),
          _buildLabel(isSwahili ? 'Namba ya Simu' : 'Phone Number'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: '0712345678',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _buildLabel(isSwahili ? 'Maelezo Mafupi' : 'Short Bio'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _bioController,
            hint: isSwahili
                ? 'Eleza ujuzi wako kwa ufupi...'
                : 'Briefly describe your skills...',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Skills(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Chagua Ujuzi' : 'Select Your Skills',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Chagua ujuzi unaotoa. Angalau mmoja unahitajika.'
                : 'Choose the skills you offer. At least one is required.',
            style: const TextStyle(color: _kSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SkillCategory.values.map((category) {
              final selected = _selectedSkills.contains(category);
              return SkillCategoryChip(
                category: category,
                selected: selected,
                isSwahili: isSwahili,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedSkills.remove(category);
                    } else {
                      _selectedSkills.add(category);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedSkills.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              isSwahili ? 'Moduli zinazohusika:' : 'Related modules:',
              style: const TextStyle(
                color: _kSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedSkills
                  .map((s) => s.domainModule)
                  .toSet()
                  .map((module) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          module,
                          style: const TextStyle(
                            color: _kSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3IdVerification(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Uthibitisho wa Kitambulisho' : 'ID Verification',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Tunahitaji NIDA yako kwa usalama wa wateja'
                : 'We need your NIDA for customer safety',
            style: const TextStyle(color: _kSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          _buildLabel(isSwahili ? 'Namba ya NIDA' : 'NIDA Number'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nidaController,
            hint: isSwahili ? 'Ingiza namba ya NIDA' : 'Enter NIDA number',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(20),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabel(
            '${isSwahili ? 'Namba ya TIN' : 'TIN Number'} (${isSwahili ? 'si lazima' : 'optional'})',
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _tinController,
            hint: isSwahili ? 'Ingiza namba ya TIN' : 'Enter TIN number',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep4License(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Leseni ya Kitaalamu' : 'Professional License',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Pakia leseni yako ya kitaalamu ikiwa unayo'
                : 'Upload your professional license if you have one',
            style: const TextStyle(color: _kSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          _buildLabel(isSwahili ? 'Aina ya Leseni' : 'License Type'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _licenseType,
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded,
                    color: _kSecondary),
                items: _licenseTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(
                                color: _kPrimary, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _licenseType = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel(isSwahili ? 'Hati ya Leseni' : 'License Document'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickLicenseFile,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: _licenseFile == null
                      ? BorderStyle.solid
                      : BorderStyle.solid,
                ),
              ),
              child: _licenseFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        _licenseFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.upload_file_rounded,
                            color: _kSecondary, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          isSwahili
                              ? 'Bonyeza kupakia leseni'
                              : 'Tap to upload license',
                          style: const TextStyle(
                            color: _kSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _nextStep,
              child: Text(
                isSwahili ? 'Ruka hatua hii' : 'Skip this step',
                style: const TextStyle(color: _kSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Portfolio(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Kazi Zilizopita' : 'Portfolio',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Pakia hadi picha 10 za kazi zako zilizopita'
                : 'Upload up to 10 photos of your past work',
            style: const TextStyle(color: _kSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (_portfolioFiles.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _portfolioFiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildPortfolioItem(index, isSwahili);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (_portfolioFiles.length < 10)
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickPortfolioImage,
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                label: Text(
                  isSwahili ? 'Ongeza Picha' : 'Add Photo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_portfolioFiles.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _nextStep,
                child: Text(
                  isSwahili ? 'Ruka hatua hii' : 'Skip this step',
                  style: const TextStyle(color: _kSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolioItem(int index, bool isSwahili) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(11)),
            child: Image.file(
              _portfolioFiles[index],
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      if (index < _portfolioCaptions.length) {
                        _portfolioCaptions[index] = value;
                      }
                    },
                    decoration: InputDecoration(
                      hintText: isSwahili ? 'Maelezo...' : 'Caption...',
                      hintStyle: const TextStyle(
                          color: _kSecondary, fontSize: 12),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      isDense: true,
                    ),
                    style:
                        const TextStyle(color: _kPrimary, fontSize: 13),
                    maxLines: 1,
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade400, size: 20),
                    onPressed: () {
                      setState(() {
                        _portfolioFiles.removeAt(index);
                        _portfolioCaptions.removeAt(index);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep6ServiceArea(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Eneo la Huduma' : 'Service Area',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Wateja watakutafuta katika eneo hili'
                : 'Customers will find you in this area',
            style: const TextStyle(color: _kSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // Region dropdown
          _buildLabel(isSwahili ? 'Mkoa' : 'Region'),
          const SizedBox(height: 8),
          _isLoadingRegions
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                      ),
                    ),
                  ),
                )
              : DropdownButtonFormField<Region>(
                  initialValue: _selectedRegion,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more_rounded,
                      color: _kSecondary),
                  decoration: InputDecoration(
                    hintText: isSwahili ? 'Chagua mkoa' : 'Select region',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _kPrimary, width: 1.5),
                    ),
                  ),
                  items: _regions
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                  color: _kPrimary, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (region) {
                    if (region != null) {
                      setState(() => _selectedRegion = region);
                      _loadDistricts(region.id);
                    }
                  },
                ),
          const SizedBox(height: 16),

          // District dropdown
          _buildLabel(isSwahili ? 'Wilaya' : 'District'),
          const SizedBox(height: 8),
          _isLoadingDistricts
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                      ),
                    ),
                  ),
                )
              : DropdownButtonFormField<District>(
                  initialValue: _selectedDistrict,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more_rounded,
                      color: _kSecondary),
                  decoration: InputDecoration(
                    hintText: _selectedRegion == null
                        ? (isSwahili
                            ? 'Chagua mkoa kwanza'
                            : 'Select region first')
                        : (isSwahili ? 'Chagua wilaya' : 'Select district'),
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: _selectedRegion == null
                        ? Colors.grey.shade100
                        : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _kPrimary, width: 1.5),
                    ),
                  ),
                  items: _districts
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              d.name,
                              style: const TextStyle(
                                  color: _kPrimary, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: _selectedRegion == null
                      ? null
                      : (district) {
                          if (district != null) {
                            setState(() => _selectedDistrict = district);
                            _loadWards(district.id);
                          }
                        },
                ),
          const SizedBox(height: 16),

          // Ward dropdown
          _buildLabel(
            '${isSwahili ? 'Kata' : 'Ward'} (${isSwahili ? 'si lazima' : 'optional'})',
          ),
          const SizedBox(height: 8),
          _isLoadingWards
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                      ),
                    ),
                  ),
                )
              : DropdownButtonFormField<Ward>(
                  initialValue: _selectedWard,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more_rounded,
                      color: _kSecondary),
                  decoration: InputDecoration(
                    hintText: _selectedDistrict == null
                        ? (isSwahili
                            ? 'Chagua wilaya kwanza'
                            : 'Select district first')
                        : (isSwahili ? 'Chagua kata' : 'Select ward'),
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: _selectedDistrict == null
                        ? Colors.grey.shade100
                        : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _kPrimary, width: 1.5),
                    ),
                  ),
                  items: _wards
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Text(
                              w.name,
                              style: const TextStyle(
                                  color: _kPrimary, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: _selectedDistrict == null
                      ? null
                      : (ward) {
                          setState(() => _selectedWard = ward);
                        },
                ),
        ],
      ),
    );
  }

  Widget _buildStep7Terms(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Masharti ya Ushirikiano' : 'Partnership Terms',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Container(
            height: 320,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SingleChildScrollView(
              child: Text(
                isSwahili ? _termsTextSwahili : _termsTextEnglish,
                style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _termsAccepted = !_termsAccepted),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Checkbox(
                    value: _termsAccepted,
                    onChanged: (v) =>
                        setState(() => _termsAccepted = v ?? false),
                    activeColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      isSwahili
                          ? 'Nimesoma na kukubaliana na masharti ya ushirikiano wa Tajirika'
                          : 'I have read and agree to the Tajirika partnership terms',
                      style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SHARED HELPERS ====================

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _kPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(color: _kPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
    );
  }

  // ==================== TERMS TEXT ====================

  static const String _termsTextEnglish = '''
TAJIRI TAJIRIKA PARTNERSHIP AGREEMENT

By registering as a Tajirika Partner, you agree to the following terms:

1. SERVICE QUALITY
You commit to providing high-quality professional services to all clients connected through the TAJIRI platform. Work must meet industry standards and be completed within agreed timelines.

2. VERIFICATION & IDENTITY
All information provided during registration must be accurate and truthful. TAJIRI reserves the right to verify your identity, qualifications, and work history. Providing false information may result in permanent account suspension.

3. PRICING & PAYMENTS
Service pricing is set by you but must be fair and transparent. TAJIRI charges a platform fee on completed jobs. Payments are processed through your chosen payout method within 3-5 business days of job completion.

4. CUSTOMER CONDUCT
You must treat all clients with respect and professionalism. Harassment, discrimination, or unsafe practices will result in immediate removal from the platform.

5. RATINGS & REVIEWS
Clients will rate your services after each job. Your tier status (Mwanafunzi, Mtaalamu, Bingwa) is based on your performance metrics including ratings, completion rate, and response time.

6. CANCELLATIONS
Repeated cancellations or no-shows may affect your standing and visibility on the platform. Communicate promptly if you cannot fulfill a booking.

7. INSURANCE & LIABILITY
You are responsible for your own professional liability insurance where applicable. TAJIRI provides dispute resolution but is not liable for damages arising from your services.

8. DATA PRIVACY
Your personal information is protected under our privacy policy. Client contact information shared for job purposes must not be used for unsolicited communication.

9. TERMINATION
Either party may terminate this partnership at any time. Pending payments will be settled within 14 business days of termination.
''';

  static const String _termsTextSwahili = '''
MKATABA WA USHIRIKIANO WA TAJIRI TAJIRIKA

Kwa kujisajili kama Mshirika wa Tajirika, unakubali masharti yafuatayo:

1. UBORA WA HUDUMA
Unajitolea kutoa huduma za kitaalamu za hali ya juu kwa wateja wote unaounganishwa nao kupitia jukwaa la TAJIRI. Kazi lazima ikidhi viwango vya sekta na ikamilishwe ndani ya muda uliokubaliwa.

2. UTHIBITISHO & UTAMBULISHO
Taarifa zote ulizotoa wakati wa usajili lazima ziwe sahihi na za kweli. TAJIRI ina haki ya kuthibitisha utambulisho wako, sifa zako, na historia ya kazi yako. Kutoa taarifa za uongo kunaweza kusababisha kusimamishwa kwa akaunti yako milele.

3. BEI & MALIPO
Bei ya huduma inawekwa na wewe lakini lazima iwe ya haki na wazi. TAJIRI inachaji ada ya jukwaa kwa kazi zilizokamilika. Malipo yanashughulikiwa kupitia njia yako ya malipo uliyochagua ndani ya siku 3-5 za kazi baada ya kukamilisha kazi.

4. MWENENDO KWA WATEJA
Lazima uwatendee wateja wote kwa heshima na utaalamu. Unyanyasaji, ubaguzi, au mazoea yasiyo salama yatasababisha kuondolewa mara moja kutoka kwenye jukwaa.

5. UKADIRIAJI & MAONI
Wateja watakadiri huduma zako baada ya kila kazi. Hali yako ya daraja (Mwanafunzi, Mtaalamu, Bingwa) inategemea vigezo vyako vya utendaji ikiwa ni pamoja na ukadiriaji, kiwango cha kukamilisha, na muda wa kujibu.

6. KUFUTA
Kufuta mara kwa mara au kutokuja kunaweza kuathiri msimamo wako na uonekano kwenye jukwaa. Wasiliana haraka ikiwa huwezi kutimiza uhifadhi.

7. BIMA & DHIMA
Wewe ndiye unayehusika na bima yako ya dhima ya kitaalamu pale inapohitajika. TAJIRI inatoa utatuzi wa migogoro lakini haihusiki na uharibifu unaotokana na huduma zako.

8. FARAGHA YA DATA
Taarifa zako binafsi zinalindwa chini ya sera yetu ya faragha. Taarifa za mawasiliano ya mteja zilizoshirikiwa kwa madhumuni ya kazi hazitumiki kwa mawasiliano yasiyo ya kawaida.

9. KUSITISHWA
Pande zote mbili zinaweza kusitisha ushirikiano huu wakati wowote. Malipo yanayosubiri yatashughulikiwa ndani ya siku 14 za kazi baada ya kusitishwa.
''';
}
