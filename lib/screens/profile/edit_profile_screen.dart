import 'package:flutter/material.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/profile_models.dart';
import '../../models/registration_models.dart';
import '../../services/user_service.dart';
import '../../services/profile_service.dart';
import '../../services/local_storage_service.dart';

/// Edit profile form. Syncs to backend via PUT /api/users/phone/{phone} and local storage.
/// Navigation: Home → Profile → ⋮ menu or Edit profile → this screen.
class EditProfileScreen extends StatefulWidget {
  final int currentUserId;
  final FullProfile? initialProfile;

  const EditProfileScreen({
    super.key,
    required this.currentUserId,
    this.initialProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _profileService = ProfileService();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late TextEditingController _usernameController;
  late TextEditingController _interestsController;

  DateTime? _dateOfBirth;
  String? _gender;
  String? _relationshipStatus;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  FullProfile? _profile;

  static const _minTouchTargetHeight = 48.0;
  static const _primaryColor = Color(0xFF1A1A1A);
  static const _backgroundColor = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _bioController = TextEditingController();
    _usernameController = TextEditingController();
    _interestsController = TextEditingController();
    if (widget.initialProfile != null) {
      _applyProfile(widget.initialProfile!);
      _isLoading = false;
    } else {
      _loadProfile();
    }
  }

  void _applyProfile(FullProfile p) {
    _profile = p;
    _firstNameController.text = p.firstName;
    _lastNameController.text = p.lastName;
    _bioController.text = p.bio ?? '';
    _usernameController.text = p.username ?? '';
    _interestsController.text = p.interests?.join(', ') ?? '';
    _dateOfBirth = p.dateOfBirth;
    _gender = p.gender;
    _relationshipStatus = p.relationshipStatus;
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _profileService.getProfile(
      userId: widget.currentUserId,
      currentUserId: widget.currentUserId,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success && result.profile != null) {
        _applyProfile(result.profile!);
      } else {
        _error = result.message ?? (AppStringsScope.of(context)?.failedToLoadProfile ?? 'Failed to load profile');
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _usernameController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final interestsStr = _interestsController.text.trim();
    final interests = interestsStr.isEmpty
        ? <String>[]
        : interestsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      if (_dateOfBirth != null) 'date_of_birth': _dateOfBirth!.toIso8601String().split('T').first,
      if (_gender != null) 'gender': _gender,
      'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      'username': _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
      if (_relationshipStatus != null) 'relationship_status': _relationshipStatus,
      'interests': interests.isEmpty ? null : interests,
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _profile?.phoneNumber;
    if (phone == null || phone.isEmpty) {
      if (mounted) {
        final s = AppStringsScope.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s?.phoneUnknown ?? 'Phone number unknown')),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final payload = _buildPayload();
    final result = await _userService.updateProfileByPhone(phone, payload);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (!result.success) {
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (s?.saveFailed ?? 'Failed to save'))),
      );
      return;
    }

    final storage = await LocalStorageService.getInstance();
    final currentUser = storage.getUser();
    if (currentUser != null) {
      final updated = RegistrationState(
        userId: currentUser.userId,
        profilePhotoUrl: currentUser.profilePhotoUrl,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _gender == 'male'
            ? Gender.male
            : _gender == 'female'
                ? Gender.female
                : currentUser.gender,
        phoneNumber: currentUser.phoneNumber,
        isPhoneVerified: currentUser.isPhoneVerified,
        verificationId: currentUser.verificationId,
        location: currentUser.location,
        primarySchool: currentUser.primarySchool,
        secondarySchool: currentUser.secondarySchool,
        alevelEducation: currentUser.alevelEducation,
        postsecondaryEducation: currentUser.postsecondaryEducation,
        universityEducation: currentUser.universityEducation,
        currentEmployer: currentUser.currentEmployer,
      );
      await storage.updateUser(updated);
    }

    if (mounted) {
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.profileSaved ?? 'Profile saved')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: TajiriAppBar(title: s?.editProfile ?? 'Edit profile'),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loadProfile,
                              child: Text(s?.retry ?? 'Retry'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            _buildField(
                              context: context,
                              label: s?.firstName ?? 'First name',
                              controller: _firstNameController,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return s?.enterFirstName ?? 'Enter first name';
                                return null;
                              },
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              context: context,
                              label: s?.lastName ?? 'Last name',
                              controller: _lastNameController,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return s?.enterLastName ?? 'Enter last name';
                                return null;
                              },
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 16),
                            _buildDateOfBirthField(context, s),
                            const SizedBox(height: 16),
                            _buildGenderField(context, s),
                            const SizedBox(height: 16),
                            _buildField(
                              context: context,
                              label: s?.bioLabel ?? 'Bio',
                              controller: _bioController,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              context: context,
                              label: s?.usernameLabel ?? 'Username',
                              controller: _usernameController,
                            ),
                            const SizedBox(height: 16),
                            _buildRelationshipField(context, s),
                            const SizedBox(height: 16),
                            _buildField(
                              context: context,
                              label: s?.interestsLabel ?? 'Interests',
                              controller: _interestsController,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 56,
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                elevation: 2,
                                shadowColor: Colors.black.withOpacity(0.1),
                                child: InkWell(
                                  onTap: _isSaving ? null : _save,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text(
                                            s?.save ?? 'Save',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: _primaryColor,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          minLines: maxLines > 1 ? 2 : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField(BuildContext context, dynamic s) {
    final label = s?.dateOfBirth ?? 'Date of birth';
    final value = _dateOfBirth != null
        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
        : (s?.selectDate ?? 'Select date');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _minTouchTargetHeight,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 0,
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateOfBirth ?? DateTime(2000),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                );
                if (picked != null && mounted) setState(() => _dateOfBirth = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: _dateOfBirth != null ? _primaryColor : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField(BuildContext context, dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s?.gender ?? 'Gender',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _minTouchTargetHeight,
          child: DropdownButtonFormField<String>(
            value: _gender,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: [
              DropdownMenuItem(value: 'male', child: Text(s?.male ?? 'Male')),
              DropdownMenuItem(value: 'female', child: Text(s?.female ?? 'Female')),
            ],
            onChanged: (v) => setState(() => _gender = v),
          ),
        ),
      ],
    );
  }

  Widget _buildRelationshipField(BuildContext context, dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s?.relationshipStatus ?? 'Relationship status',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _minTouchTargetHeight,
          child: DropdownButtonFormField<String>(
            value: _relationshipStatus,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: [
              DropdownMenuItem(value: 'single', child: Text(s?.single ?? 'Single')),
              DropdownMenuItem(value: 'married', child: Text(s?.married ?? 'Married')),
              DropdownMenuItem(value: 'engaged', child: Text(s?.engaged ?? 'Engaged')),
              DropdownMenuItem(value: 'complicated', child: Text(s?.complicated ?? 'Complicated')),
            ],
            onChanged: (v) => setState(() => _relationshipStatus = v),
          ),
        ),
      ],
    );
  }
}
