import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/location_models.dart';
import '../../services/local_storage_service.dart';
import '../../services/location_service.dart';
import '../services/tajirika_service.dart';

class DriverRegistrationPage extends StatefulWidget {
  const DriverRegistrationPage({super.key});

  @override
  State<DriverRegistrationPage> createState() => _DriverRegistrationPageState();
}

class _DriverRegistrationPageState extends State<DriverRegistrationPage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  static const int _totalSteps = 7;

  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1 — Personal Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  // Step 2 — Vehicle Type
  String _vehicleType = 'motorcycle';
  static const _vehicleTypes = [
    ('motorcycle', Icons.two_wheeler_rounded, 'Motorcycle', 'Pikipiki'),
    ('bicycle', Icons.pedal_bike_rounded, 'Bicycle', 'Baiskeli'),
    ('car', Icons.directions_car_rounded, 'Car / Taxi', 'Gari / Teksi'),
    ('van', Icons.airport_shuttle_rounded, 'Van / Pickup', 'Van / Pikap'),
  ];

  // Step 3 — Driver's License & Plate
  final _licenseNumberController = TextEditingController();
  final _plateController = TextEditingController();

  // Step 4 — NIDA
  final _nidaController = TextEditingController();

  // Step 5 — License Photo
  File? _licensePhoto;
  final _imagePicker = ImagePicker();

  // Step 6 — Service Area
  List<Region> _regions = [];
  List<District> _districts = [];
  List<Ward> _wards = [];
  Region? _selectedRegion;
  District? _selectedDistrict;
  Ward? _selectedWard;
  bool _isLoadingRegions = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;

  // Step 7 — Terms
  bool _termsAccepted = false;

  final _locationService = LocationService(baseUrl: ApiConfig.baseUrl);

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    _loadRegions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _licenseNumberController.dispose();
    _plateController.dispose();
    _nidaController.dispose();
    super.dispose();
  }

  Future<void> _prefillUserData() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final user = storage.getUser();
      if (!mounted) return;
      if (user != null) {
        _nameController.text =
            '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
        _phoneController.text = user.phoneNumber ?? '';
      }
    } catch (e) {
      debugPrint('[DriverRegistrationPage] prefill error: $e');
    }
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final regions = await _locationService.getRegions();
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingWards = false);
    }
  }

  bool _validateCurrentStep(bool isSwahili) {
    switch (_currentStep) {
      case 0:
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
      case 1:
        return true; // vehicle type always has a default
      case 2:
        if (_licenseNumberController.text.trim().isEmpty) {
          _showError(isSwahili
              ? 'Tafadhali ingiza namba ya leseni'
              : 'Please enter your driver\'s license number');
          return false;
        }
        if (_plateController.text.trim().isEmpty) {
          _showError(isSwahili
              ? 'Tafadhali ingiza namba ya usajili'
              : 'Please enter the vehicle plate number');
          return false;
        }
        return true;
      case 3:
        if (_nidaController.text.trim().isEmpty) {
          _showError(isSwahili
              ? 'Tafadhali ingiza namba ya NIDA'
              : 'Please enter your NIDA number');
          return false;
        }
        if (_nidaController.text.trim().length > 20) {
          _showError(isSwahili
              ? 'Namba ya NIDA isizidi tarakimu 20'
              : 'NIDA must not exceed 20 characters');
          return false;
        }
        return true;
      case 4:
        return true; // license photo optional
      case 5:
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
      case 6:
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
        content:
            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _nextStep() {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
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

  Future<void> _pickLicensePhoto() async {
    try {
      final picked =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (picked != null) setState(() => _licensePhoto = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      _showError('Error picking image: $e');
    }
  }

  Future<void> _submit() async {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
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
      final data = <String, dynamic>{
        'first_name': nameParts.first,
        'last_name':
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : (isSwahili
                ? 'Dereva wa Tajiri Delivery'
                : 'Tajiri Delivery driver'),
        'skills': ['deliveryDriver'],
        'vehicle_type': _vehicleType,
        'license_number': _licenseNumberController.text.trim(),
        'plate_number': _plateController.text.trim().toUpperCase(),
        'nida_number': _nidaController.text.trim(),
        'region_id': _selectedRegion!.id,
        'region': _selectedRegion!.name,
        'district_id': _selectedDistrict!.id,
        'district': _selectedDistrict!.name,
        if (_selectedWard != null) 'ward_id': _selectedWard!.id,
        if (_selectedWard != null) 'ward': _selectedWard!.name,
        'payout_method': 'wallet',
        'terms_accepted': true,
        'partner_type': 'delivery_driver',
      };

      final result =
          await TajirikaService.registerPartner(token, userId, data);
      if (!mounted) return;

      if (result.success) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSwahili
                  ? 'Usajili umefanikiwa! Utaarifu ndani ya saa 24.'
                  : 'Registration successful! You\'ll be verified within 24 hours.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pushReplacementNamed(context, '/delivery/driver/home');
      } else {
        _showError(result.message ??
            (isSwahili ? 'Imeshindwa kusajili' : 'Registration failed'));
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(isSwahili ? 'Hitilafu: $e' : 'Error: $e');
      setState(() => _isSubmitting = false);
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;

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
            isSwahili ? 'Jiunge — Dereva' : 'Become a Driver',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1PersonalInfo(isSwahili),
                    _buildStep2VehicleType(isSwahili),
                    _buildStep3LicensePlate(isSwahili),
                    _buildStep4Nida(isSwahili),
                    _buildStep5LicensePhoto(isSwahili),
                    _buildStep6ServiceArea(isSwahili),
                    _buildStep7Terms(isSwahili),
                  ],
                ),
              ),
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
                        borderRadius: BorderRadius.circular(12)),
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
                onPressed:
                    _isSubmitting ? null : (isLastStep ? _submit : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
          _buildStepHeading(
            isSwahili ? 'Taarifa Binafsi' : 'Personal Information',
            isSwahili
                ? 'Taarifa hizi zimetoka kwenye akaunti yako ya TAJIRI'
                : 'Pre-filled from your TAJIRI profile',
          ),
          const SizedBox(height: 24),
          _buildLabel(isSwahili ? 'Jina Kamili' : 'Full Name'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: isSwahili
                ? 'Jina la kwanza na la mwisho'
                : 'First and last name',
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
          _buildLabel(
            '${isSwahili ? 'Maelezo Mafupi' : 'Short Bio'} (${isSwahili ? 'si lazima' : 'optional'})',
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _bioController,
            hint: isSwahili
                ? 'e.g. Dereva mwenye uzoefu wa miaka 3...'
                : 'e.g. Experienced driver for 3 years...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2VehicleType(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeading(
            isSwahili ? 'Aina ya Gari' : 'Vehicle Type',
            isSwahili
                ? 'Chagua gari unalotumia kufanya deliveries'
                : 'Select the vehicle you use for deliveries',
          ),
          const SizedBox(height: 24),
          ..._vehicleTypes.map(
            (v) => _buildVehicleOption(
              value: v.$1,
              icon: v.$2,
              label: isSwahili ? v.$4 : v.$3,
              isSwahili: isSwahili,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOption({
    required String value,
    required IconData icon,
    required String label,
    required bool isSwahili,
  }) {
    final selected = _vehicleType == value;
    return GestureDetector(
      onTap: () => setState(() => _vehicleType = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kPrimary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 24,
                color: selected ? Colors.white : _kSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3LicensePlate(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeading(
            isSwahili
                ? 'Leseni na Namba ya Usajili'
                : 'License & Plate Number',
            isSwahili
                ? 'Namba hizi zitathibitishwa kabla ya uanzishaji'
                : 'These will be verified before activation',
          ),
          const SizedBox(height: 24),
          _buildLabel(
            isSwahili
                ? 'Namba ya Leseni ya Udereva'
                : 'Driver\'s License Number',
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _licenseNumberController,
            hint: isSwahili
                ? 'Ingiza namba ya leseni'
                : 'Enter license number',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(20),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabel(
            isSwahili
                ? 'Namba ya Usajili wa Gari'
                : 'Vehicle Plate Number',
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _plateController,
            hint: isSwahili ? 'e.g. T 123 ABC' : 'e.g. T 123 ABC',
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-z0-9\s]')),
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: _kSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSwahili
                        ? 'Plate number iandikwe kwa herufi kubwa. Mfano: T 123 ABC'
                        : 'Plate number will be auto-capitalised. Example: T 123 ABC',
                    style: const TextStyle(
                        color: _kSecondary, fontSize: 12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Nida(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeading(
            isSwahili ? 'Uthibitisho wa NIDA' : 'NIDA Verification',
            isSwahili
                ? 'Tunahitaji NIDA yako kwa usalama wa wateja'
                : 'Required for background check and customer safety',
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
        ],
      ),
    );
  }

  Widget _buildStep5LicensePhoto(bool isSwahili) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeading(
            isSwahili ? 'Picha ya Leseni' : 'License Photo',
            isSwahili
                ? 'Pakia picha ya leseni yako ya udereva (mbele)'
                : 'Upload a photo of your driver\'s license (front side)',
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickLicensePhoto,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _licensePhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        _licensePhoto!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.badge_rounded,
                            color: _kSecondary, size: 40),
                        const SizedBox(height: 10),
                        Text(
                          isSwahili
                              ? 'Bonyeza kupakia picha ya leseni'
                              : 'Tap to upload license photo',
                          style: const TextStyle(
                              color: _kSecondary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
          ),
          if (_licensePhoto != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: _pickLicensePhoto,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  isSwahili ? 'Badilisha Picha' : 'Change Photo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _nextStep,
              child: Text(
                isSwahili ? 'Ruka hatua hii' : 'Skip this step',
                style:
                    const TextStyle(color: _kSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
          _buildStepHeading(
            isSwahili ? 'Eneo la Kufanyia Kazi' : 'Operating Area',
            isSwahili
                ? 'Utapewa kazi za delivery katika eneo hili'
                : 'You\'ll receive delivery jobs in this area',
          ),
          const SizedBox(height: 24),
          _buildLabel(isSwahili ? 'Mkoa' : 'Region'),
          const SizedBox(height: 8),
          _isLoadingRegions
              ? _buildSmallLoader()
              : DropdownButtonFormField<Region>(
                  initialValue: _selectedRegion,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more_rounded,
                      color: _kSecondary),
                  decoration: _dropdownDecoration(
                    isSwahili ? 'Chagua mkoa' : 'Select region',
                    enabled: true,
                  ),
                  items: _regions
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.name,
                                style: const TextStyle(
                                    color: _kPrimary, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
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
          _buildLabel(isSwahili ? 'Wilaya' : 'District'),
          const SizedBox(height: 8),
          _isLoadingDistricts
              ? _buildSmallLoader()
              : DropdownButtonFormField<District>(
                  initialValue: _selectedDistrict,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more_rounded,
                      color: _kSecondary),
                  decoration: _dropdownDecoration(
                    _selectedRegion == null
                        ? (isSwahili
                            ? 'Chagua mkoa kwanza'
                            : 'Select region first')
                        : (isSwahili ? 'Chagua wilaya' : 'Select district'),
                    enabled: _selectedRegion != null,
                  ),
                  items: _districts
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d.name,
                                style: const TextStyle(
                                    color: _kPrimary, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
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
          _buildLabel(
            '${isSwahili ? 'Kata' : 'Ward'} (${isSwahili ? 'si lazima' : 'optional'})',
          ),
          const SizedBox(height: 8),
          _isLoadingWards
              ? _buildSmallLoader()
              : DropdownButtonFormField<Ward>(
                  initialValue: _selectedWard,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more_rounded,
                      color: _kSecondary),
                  decoration: _dropdownDecoration(
                    _selectedDistrict == null
                        ? (isSwahili
                            ? 'Chagua wilaya kwanza'
                            : 'Select district first')
                        : (isSwahili ? 'Chagua kata' : 'Select ward'),
                    enabled: _selectedDistrict != null,
                  ),
                  items: _wards
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Text(w.name,
                                style: const TextStyle(
                                    color: _kPrimary, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: _selectedDistrict == null
                      ? null
                      : (ward) =>
                          setState(() => _selectedWard = ward),
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
          _buildStepHeading(
            isSwahili
                ? 'Masharti ya Udereva'
                : 'Driver Terms & Conditions',
            null,
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
                isSwahili ? _termsSwahili : _termsEnglish,
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
            onTap: () =>
                setState(() => _termsAccepted = !_termsAccepted),
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
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      isSwahili
                          ? 'Nimesoma na kukubaliana na masharti ya udereva wa Tajiri Delivery'
                          : 'I have read and agree to the Tajiri Delivery driver terms',
                      style: const TextStyle(
                          color: _kPrimary, fontSize: 13),
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

  Widget _buildStepHeading(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: _kSecondary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

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
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 14),
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

  InputDecoration _dropdownDecoration(String hint,
      {required bool enabled}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: enabled ? Colors.white : Colors.grey.shade100,
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
    );
  }

  Widget _buildSmallLoader() {
    return const Padding(
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
    );
  }

  // ==================== TERMS TEXT ====================

  static const String _termsEnglish = '''
TAJIRI DELIVERY — DRIVER PARTNERSHIP AGREEMENT

By registering as a Tajiri Delivery Driver, you agree to:

1. ELIGIBILITY
You must hold a valid driver's license for the vehicle type you register with. Your NIDA details must be accurate. You must be 18 years of age or older.

2. DELIVERY STANDARDS
Accept and complete jobs promptly. Deliver items in the same condition received. Follow the route and communicate delays to buyers/sellers via the app.

3. VEHICLE MAINTENANCE
Your vehicle must be roadworthy, insured, and licensed at all times. TAJIRI may request proof of insurance upon request.

4. EARNINGS & PAYOUTS
Earnings are credited to your TAJIRI wallet per delivery. Payouts are processed daily after 6 PM. TAJIRI retains a platform commission as displayed in the app at time of job acceptance.

5. CONDUCT
You must treat senders and receivers with professionalism. Do not open, inspect, or photograph parcel contents. Never demand additional payment outside the platform.

6. SAFETY & LIABILITY
You are responsible for safe handling of deliveries. TAJIRI provides dispute resolution but is not liable for damages caused by driver negligence.

7. ACCOUNT SUSPENSION
Repeated cancellations, poor ratings, or misconduct will result in suspension. Fraud or misrepresentation will result in permanent removal and potential legal action.

8. AVAILABILITY
You control your own hours via the online/offline toggle. TAJIRI does not guarantee a minimum number of jobs per day.

9. TERMINATION
Either party may exit this agreement at any time. Outstanding earnings will be paid within 7 business days.
''';

  static const String _termsSwahili = '''
TAJIRI DELIVERY — MKATABA WA UDEREVA

Kwa kujisajili kama Dereva wa Tajiri Delivery, unakubali yafuatayo:

1. SIFA
Lazima uwe na leseni halali ya udereva kwa aina ya gari uliyosajili. Namba yako ya NIDA lazima iwe sahihi. Lazima uwe na umri wa miaka 18 au zaidi.

2. VIWANGO VYA DELIVERY
Kubali na kamilisha kazi haraka. Peleka bidhaa katika hali ile ile uliyopokea. Fuata njia na toa taarifa za kuchelewa kwa wanunuzi/wauzaji kupitia programu.

3. MATENGENEZO YA GARI
Gari lako lazima liwe salama, na bima, na usajili wakati wote. TAJIRI inaweza kuomba uthibitisho wa bima inapohitajika.

4. MAPATO & MALIPO
Mapato yanaingizwa kwenye pochi yako ya TAJIRI kwa kila delivery. Malipo yanashughulikiwa kila siku baada ya saa 12 usiku. TAJIRI inachukua kamisheni ya jukwaa kama inavyoonyeshwa kwenye programu wakati wa kukubali kazi.

5. MWENENDO
Lazima uwatendee wapelekaji na wapokeaji kwa heshima. Usifungue, ukague, au upige picha ya maudhui ya vifurushi. Kamwe usidai malipo ya ziada nje ya jukwaa.

6. USALAMA & DHIMA
Wewe unawajibika kwa ushughulikiaji salama wa deliveries. TAJIRI inatoa utatuzi wa migogoro lakini haihusiki na uharibifu unaosababishwa na uzembe wa dereva.

7. KUSIMAMISHWA KWA AKAUNTI
Kufuta mara kwa mara, ukadiriaji mbaya, au utovu wa nidhamu kutasababisha kusimamishwa. Udanganyifu au uwakilishi mbaya utasababisha kuondolewa milele na hatua za kisheria.

8. UPATIKANAJI
Unamiliki masaa yako mwenyewe kupitia kubonyeza online/offline. TAJIRI haihakikishii idadi ya chini ya kazi kwa siku.

9. KUSITISHWA
Pande zote mbili zinaweza kutoka katika mkataba huu wakati wowote. Mapato yanayosubiri yatalipwa ndani ya siku 7 za kazi.
''';
}
