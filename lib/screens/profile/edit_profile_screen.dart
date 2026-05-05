import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/profile_models.dart';
import '../../models/registration_models.dart';
import '../../services/user_service.dart';
import '../../services/profile_service.dart';
import '../../services/local_storage_service.dart';

/// Edit profile form. Syncs to backend via PUT /api/users/phone/{phone}
/// and the local Hive user object. Reachable from:
///   • Profile header → edit pencil (next to display name)
///   • Settings → Edit profile
///
/// Playbook compliance: monochrome, 48dp targets, no SnackBars (errors
/// surface as a dismissible inline banner at the top of the form),
/// `_rounded` icons, FilledButton primary save action, OutlinedButton
/// retry, BorderRadius.circular(12) on inputs.
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

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _usernameController;
  late final TextEditingController _interestsController;

  DateTime? _dateOfBirth;
  String? _gender;
  String? _relationshipStatus;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _screenError;   // full-screen load error
  String? _formError;     // transient banner at the top of the form
  FullProfile? _profile;

  static const double _kFieldHeight = 48.0;
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kTertiary = Color(0xFF999999);
  static const Color _kBackground = Color(0xFFFAFAFA);
  static const Color _kSurface = Colors.white;
  static const Color _kDanger = Color(0xFFD32F2F);

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
      _screenError = null;
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
        _screenError = result.message ??
            (AppStringsScope.of(context)?.failedToLoadProfile ??
                'Failed to load profile');
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
        : interestsStr
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    return {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      if (_dateOfBirth != null)
        'date_of_birth': _dateOfBirth!.toIso8601String().split('T').first,
      if (_gender != null) 'gender': _gender,
      'bio': _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      'username': _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
      if (_relationshipStatus != null)
        'relationship_status': _relationshipStatus,
      'interests': interests.isEmpty ? null : interests,
    };
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    final phone = _profile?.phoneNumber;
    if (phone == null || phone.isEmpty) {
      final s = AppStringsScope.of(context);
      setState(() {
        _formError = s?.phoneUnknown ?? 'Phone number unknown';
      });
      return;
    }

    setState(() => _isSaving = true);

    final payload = _buildPayload();
    final result = await _userService.updateProfileByPhone(phone, payload);

    if (!mounted) return;

    if (!result.success) {
      final s = AppStringsScope.of(context);
      setState(() {
        _isSaving = false;
        _formError = result.message ?? (s?.saveFailed ?? 'Failed to save');
      });
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

    ProfileService.invalidate(widget.currentUserId);
    if (mounted) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
    }
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(title: s?.editProfile ?? 'Edit profile'),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPrimary,
                ),
              )
            : _screenError != null
                ? _buildScreenError(s)
                : _buildForm(s),
      ),
    );
  }

  Widget _buildScreenError(dynamic s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _screenError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary, fontSize: 14),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadProfile,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: Text(s?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(dynamic s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AutofillGroup(
        child: Form(
        key: _formKey,
        // Validate only after the user has interacted with the form
        // (per playbook §2316 — don't show errors while still typing).
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              if (_formError != null) ...[
                _ErrorBanner(
                  message: _formError!,
                  onDismiss: () => setState(() => _formError = null),
                ),
                const SizedBox(height: 16),
              ],
              _buildField(
                label: s?.firstName ?? 'First name',
                controller: _firstNameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return s?.enterFirstName ?? 'Enter first name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: s?.lastName ?? 'Last name',
                controller: _lastNameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return s?.enterLastName ?? 'Enter last name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              _buildDateOfBirthField(s),
              const SizedBox(height: 16),
              _buildGenderField(s),
              const SizedBox(height: 16),
              _buildField(
                label: s?.bioLabel ?? 'Bio',
                controller: _bioController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: s?.usernameLabel ?? 'Username',
                controller: _usernameController,
                autofillHints: const [AutofillHints.username],
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              _buildRelationshipField(s),
              const SizedBox(height: 16),
              _buildField(
                label: s?.interestsLabel ?? 'Interests',
                controller: _interestsController,
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              _buildSaveButton(s),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSaveButton(dynamic s) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: _isSaving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(s?.save ?? 'Save'),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          minLines: maxLines > 1 ? 2 : null,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          keyboardType: keyboardType,
          textInputAction: textInputAction ??
              (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 14, color: _kPrimary),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: _kTertiary, fontSize: 14),
      filled: true,
      fillColor: _kSurface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kDanger, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kDanger, width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 12, color: _kDanger),
    );
  }

  Widget _buildDateOfBirthField(dynamic s) {
    final label = s?.dateOfBirth ?? 'Date of birth';
    final hasValue = _dateOfBirth != null;
    final value = hasValue
        ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/'
            '${_dateOfBirth!.month.toString().padLeft(2, '0')}/'
            '${_dateOfBirth!.year}'
        : (s?.selectDate ?? 'Select date');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _pickDateOfBirth,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints:
                  const BoxConstraints(minHeight: _kFieldHeight),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: _kSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: hasValue ? _kPrimary : _kTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: _kTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
            surface: _kSurface,
            onSurface: _kPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Widget _buildGenderField(dynamic s) {
    return _buildDropdownField<String>(
      label: s?.gender ?? 'Gender',
      value: _gender,
      onChanged: (v) => setState(() => _gender = v),
      items: [
        DropdownMenuItem(value: 'male', child: Text(s?.male ?? 'Male')),
        DropdownMenuItem(value: 'female', child: Text(s?.female ?? 'Female')),
      ],
    );
  }

  Widget _buildRelationshipField(dynamic s) {
    return _buildDropdownField<String>(
      label: s?.relationshipStatus ?? 'Relationship status',
      value: _relationshipStatus,
      onChanged: (v) => setState(() => _relationshipStatus = v),
      items: [
        DropdownMenuItem(value: 'single', child: Text(s?.single ?? 'Single')),
        DropdownMenuItem(value: 'married', child: Text(s?.married ?? 'Married')),
        DropdownMenuItem(value: 'engaged', child: Text(s?.engaged ?? 'Engaged')),
        DropdownMenuItem(
            value: 'complicated',
            child: Text(s?.complicated ?? 'Complicated')),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required ValueChanged<T?> onChanged,
    required List<DropdownMenuItem<T>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: _inputDecoration(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _kSecondary),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
          dropdownColor: _kSurface,
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Inline error banner shown at the top of the form when a save
/// attempt fails. Replaces SnackBars (playbook §99).
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  static const Color _kDanger = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: _kDanger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDanger.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: _kDanger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: _kDanger,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18, color: _kDanger),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
