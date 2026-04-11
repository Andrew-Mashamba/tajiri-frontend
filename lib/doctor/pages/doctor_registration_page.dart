// lib/doctor/pages/doctor_registration_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/doctor_models.dart';
import '../services/doctor_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class DoctorRegistrationPage extends StatefulWidget {
  final int userId;
  const DoctorRegistrationPage({super.key, required this.userId});
  @override
  State<DoctorRegistrationPage> createState() => _DoctorRegistrationPageState();
}

class _DoctorRegistrationPageState extends State<DoctorRegistrationPage> {
  final DoctorService _service = DoctorService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mctController = TextEditingController();
  final _nidaController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _locationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();

  MedicalSpecialty _selectedSpecialty = MedicalSpecialty.generalPractice;

  File? _mctCertificate;
  File? _medicalDegree;
  File? _nationalId;
  File? _specialistCertificate;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mctController.dispose();
    _nidaController.dispose();
    _hospitalController.dispose();
    _locationController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<File?> _pickDocument(String label) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      dialogTitle: label,
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mctCertificate == null || _medicalDegree == null || _nationalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali pakia nyaraka zote zinazohitajika')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final request = DoctorRegistrationRequest(
      fullName: _nameController.text.trim(),
      mctRegistrationNumber: _mctController.text.trim(),
      specialty: _selectedSpecialty.name,
      hospital: _hospitalController.text.trim().isNotEmpty ? _hospitalController.text.trim() : null,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
      consultationFee: double.tryParse(_feeController.text.trim()) ?? 0,
      bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      nidaNumber: _nidaController.text.trim(),
    );

    final result = await _service.registerAsDoctor(
      userId: widget.userId,
      request: request,
      mctCertificate: _mctCertificate!,
      medicalDegree: _medicalDegree!,
      nationalId: _nationalId!,
      specialistCertificate: _specialistCertificate,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ombi lako limetumwa! Uthibitisho utachukua siku 1-3.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kusajili'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Daktari Tajiri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Program info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text('Doctor Tajiri', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Jiunge na programu ya Daktari Tajiri kutoa huduma za mashauriano ya mtandaoni. '
                    'Uthibitisho wa MCT unahitajika.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Personal info
            _buildSectionTitle('Taarifa Binafsi'),
            _buildField(controller: _nameController, label: 'Jina Kamili *', hint: 'Dk. Juma Hassan'),
            _buildField(controller: _mctController, label: 'Namba ya MCT *', hint: 'MCT-XXXX'),
            _buildField(controller: _nidaController, label: 'Namba ya NIDA *', hint: '19XXXXXXXXXX-XXXXX-XXXXX-XX'),
            const SizedBox(height: 8),

            // Specialty
            const Text('Taaluma *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MedicalSpecialty>(
                  value: _selectedSpecialty,
                  isExpanded: true,
                  items: MedicalSpecialty.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text('${s.displayName} (${s.subtitle})'),
                    );
                  }).toList(),
                  onChanged: (v) { if (v != null) setState(() => _selectedSpecialty = v); },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Professional info
            _buildSectionTitle('Taarifa za Kitaalamu'),
            _buildField(controller: _hospitalController, label: 'Hospitali / Kliniki', hint: 'Muhimbili National Hospital'),
            _buildField(controller: _locationController, label: 'Mahali', hint: 'Dar es Salaam'),
            _buildField(controller: _experienceController, label: 'Miaka ya Uzoefu *', hint: '5', keyboardType: TextInputType.number),
            _buildField(controller: _feeController, label: 'Ada ya Mashauriano (TZS) *', hint: '15000', keyboardType: TextInputType.number),
            _buildField(controller: _bioController, label: 'Kuhusu Wewe', hint: 'Maelezo mafupi...', maxLines: 3),

            // Documents
            _buildSectionTitle('Nyaraka Zinazohitajika'),
            const SizedBox(height: 8),
            _DocumentUpload(
              label: 'Cheti cha MCT *',
              file: _mctCertificate,
              onPick: () async {
                final f = await _pickDocument('Cheti cha MCT');
                if (f != null) setState(() => _mctCertificate = f);
              },
            ),
            _DocumentUpload(
              label: 'Shahada ya Udaktari *',
              file: _medicalDegree,
              onPick: () async {
                final f = await _pickDocument('Shahada ya Udaktari');
                if (f != null) setState(() => _medicalDegree = f);
              },
            ),
            _DocumentUpload(
              label: 'Kitambulisho cha Taifa (NIDA) *',
              file: _nationalId,
              onPick: () async {
                final f = await _pickDocument('Kitambulisho');
                if (f != null) setState(() => _nationalId = f);
              },
            ),
            _DocumentUpload(
              label: 'Cheti cha Utaalamu (ikiwa unacho)',
              file: _specialistCertificate,
              onPick: () async {
                final f = await _pickDocument('Cheti cha Utaalamu');
                if (f != null) setState(() => _specialistCertificate = f);
              },
            ),
            const SizedBox(height: 24),

            // Verification notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Uthibitisho utafanywa kupitia Baraza la Madaktari Tanzania (MCT). Mchakato huchukua siku 1-3 za kazi.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Wasilisha Ombi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: label.contains('*') ? (v) => (v == null || v.trim().isEmpty) ? 'Lazima' : null : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentUpload extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onPick;

  const _DocumentUpload({required this.label, this.file, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: file != null ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
                width: file != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  file != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                  color: file != null ? const Color(0xFF4CAF50) : _kSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary)),
                      if (file != null)
                        Text(
                          file!.path.split('/').last,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF4CAF50)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        )
                      else
                        const Text('PDF, JPG au PNG', style: TextStyle(fontSize: 11, color: _kSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _kSecondary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
