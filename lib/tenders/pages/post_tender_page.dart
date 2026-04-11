// Post (publish) a new tender -- for business owners
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tender_models.dart';
import '../services/tender_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kUrgent = Color(0xFFD32F2F);

class PostTenderPage extends StatefulWidget {
  const PostTenderPage({super.key});

  @override
  State<PostTenderPage> createState() => _PostTenderPageState();
}

class _PostTenderPageState extends State<PostTenderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  final _eligibilityController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactAddressController = TextEditingController();

  TenderCategory _selectedCategory = TenderCategory.other;
  DateTime? _closingDate;
  TimeOfDay? _closingTime;
  bool _isSubmitting = false;

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    _eligibilityController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _contactAddressController.dispose();
    super.dispose();
  }

  Future<void> _selectClosingDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _closingDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() => _closingDate = date);
    }
  }

  Future<void> _selectClosingTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _closingTime ?? const TimeOfDay(hour: 15, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() => _closingTime = time);
    }
  }

  Future<void> _submitTender() async {
    if (!_formKey.currentState!.validate()) return;
    if (_closingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isSwahili
                ? 'Tafadhali chagua tarehe ya kufungwa'
                : 'Please select a closing date'),
            backgroundColor: _kUrgent),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Map<String, String>? contact;
    if (_contactNameController.text.isNotEmpty ||
        _contactEmailController.text.isNotEmpty ||
        _contactPhoneController.text.isNotEmpty) {
      contact = {};
      if (_contactNameController.text.isNotEmpty) contact['name'] = _contactNameController.text;
      if (_contactEmailController.text.isNotEmpty) contact['email'] = _contactEmailController.text;
      if (_contactPhoneController.text.isNotEmpty) contact['phone'] = _contactPhoneController.text;
      if (_contactAddressController.text.isNotEmpty) contact['address'] = _contactAddressController.text;
    }

    final result = await TenderService.postTender(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      referenceNumber: _referenceController.text.trim().isNotEmpty ? _referenceController.text.trim() : null,
      category: _selectedCategory.valueEn,
      closingDate: _closingDate!.toIso8601String().split('T').first,
      closingTime: _closingTime != null
          ? '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')} EAT'
          : null,
      eligibility: _eligibilityController.text.trim().isNotEmpty ? _eligibilityController.text.trim() : null,
      contact: contact,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSwahili
                ? 'Zabuni imechapishwa!'
                : 'Tender published!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.error ??
                  (_isSwahili ? 'Imeshindwa kuchapisha' : 'Failed to publish')),
              backgroundColor: _kUrgent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isSwahili ? 'Chapisha Zabuni' : 'Post Tender',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: _kSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isSwahili
                          ? 'Chapisha zabuni yako ili waombaji waione kupitia TAJIRI'
                          : 'Publish your tender so applicants can find it via TAJIRI',
                      style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            _buildLabel(_isSwahili ? 'Kichwa cha Zabuni *' : 'Tender Title *'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _titleController,
              hint: _isSwahili
                  ? 'Mfano: Huduma ya Ulinzi wa Ofisi'
                  : 'e.g. Office Security Services',
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (_isSwahili ? 'Kichwa kinahitajika' : 'Title is required')
                  : null,
            ),
            const SizedBox(height: 18),

            // Description
            _buildLabel(_isSwahili ? 'Maelezo *' : 'Description *'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _descriptionController,
              hint: _isSwahili
                  ? 'Eleza mahitaji ya zabuni hii kwa undani...'
                  : 'Describe the tender requirements in detail...',
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (_isSwahili ? 'Maelezo yanahitajika' : 'Description is required')
                  : null,
            ),
            const SizedBox(height: 18),

            // Reference number
            _buildLabel(_isSwahili ? 'Nambari ya Rejea' : 'Reference Number'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _referenceController,
              hint: _isSwahili ? 'Mfano: TZ/T/2026/001' : 'e.g. TZ/T/2026/001',
            ),
            const SizedBox(height: 18),

            // Category
            _buildLabel(_isSwahili ? 'Aina ya Zabuni *' : 'Tender Category *'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: DropdownButtonFormField<TenderCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: InputBorder.none,
                ),
                items: TenderCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                        _isSwahili ? cat.label : cat.valueEn,
                        style: const TextStyle(fontSize: 14, color: _kPrimary)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
            ),
            const SizedBox(height: 18),

            // Closing date + time
            _buildLabel(_isSwahili ? 'Tarehe ya Kufungwa *' : 'Closing Date *'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _selectClosingDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                          const SizedBox(width: 10),
                          Text(
                            _closingDate != null
                                ? '${_closingDate!.day}/${_closingDate!.month}/${_closingDate!.year}'
                                : (_isSwahili ? 'Chagua tarehe' : 'Select date'),
                            style: TextStyle(
                              fontSize: 14,
                              color: _closingDate != null ? _kPrimary : _kSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _selectClosingTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 18, color: _kSecondary),
                          const SizedBox(width: 8),
                          Text(
                            _closingTime != null
                                ? '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}'
                                : (_isSwahili ? 'Saa' : 'Time'),
                            style: TextStyle(
                              fontSize: 14,
                              color: _closingTime != null ? _kPrimary : _kSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Eligibility
            _buildLabel(_isSwahili ? 'Vigezo vya Ushiriki' : 'Eligibility Criteria'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _eligibilityController,
              hint: _isSwahili
                  ? 'Mfano: Lazima awe amesajiliwa na BRELA...'
                  : 'e.g. Must be registered with BRELA...',
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Contact section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSwahili ? 'Mawasiliano' : 'Contact Details',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isSwahili
                        ? 'Weka maelezo ya mawasiliano kwa waombaji'
                        : 'Add contact information for applicants',
                    style: TextStyle(fontSize: 12, color: _kSecondary.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _contactNameController,
                    hint: _isSwahili ? 'Jina la anayewasiliana' : 'Contact person name',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _contactEmailController,
                    hint: _isSwahili ? 'Barua pepe' : 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _contactPhoneController,
                    hint: _isSwahili ? 'Simu' : 'Phone',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _contactAddressController,
                    hint: _isSwahili ? 'Anwani' : 'Address',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitTender,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isSwahili ? 'Chapisha Zabuni' : 'Publish Tender',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _kPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _kSecondary.withValues(alpha: 0.6), fontSize: 14),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: _kSecondary) : null,
        filled: true,
        fillColor: _kCardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kUrgent),
        ),
      ),
    );
  }
}
