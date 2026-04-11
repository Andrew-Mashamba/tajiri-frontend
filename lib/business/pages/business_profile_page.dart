// lib/business/pages/business_profile_page.dart
// Business profile, registration details, and document vault.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';
import 'registration_guide_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BusinessProfilePage extends StatefulWidget {
  final int userId;
  final Business? business;
  const BusinessProfilePage(
      {super.key, required this.userId, required this.business});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? _token;
  bool _saving = false;
  bool _loadingDocs = false;

  // Form controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _tinCtrl;
  late TextEditingController _vrnCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _licenseNumberCtrl;
  late TextEditingController _regNumberCtrl;
  BusinessType _type = BusinessType.sole_proprietor;
  DateTime? _licenseExpiry;
  DateTime? _incorporationDate;
  List<BusinessDocument> _documents = [];

  bool get _isNew => widget.business == null;

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _tinCtrl = TextEditingController(text: b?.tinNumber ?? '');
    _vrnCtrl = TextEditingController(text: b?.vrn ?? '');
    _addressCtrl = TextEditingController(text: b?.address ?? '');
    _phoneCtrl = TextEditingController(text: b?.phone ?? '');
    _emailCtrl = TextEditingController(text: b?.email ?? '');
    _licenseNumberCtrl = TextEditingController(text: b?.licenseNumber ?? '');
    _regNumberCtrl = TextEditingController(text: b?.registrationNumber ?? '');
    _type = b?.type ?? BusinessType.sole_proprietor;
    _licenseExpiry = b?.licenseExpiry;
    _incorporationDate = b?.incorporationDate;
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    if (!_isNew && widget.business?.id != null) {
      _loadDocuments();
    }
  }

  Future<void> _loadDocuments() async {
    if (_token == null || widget.business?.id == null) return;
    setState(() => _loadingDocs = true);
    final res =
        await BusinessService.getDocuments(_token!, widget.business!.id!);
    if (mounted) {
      setState(() {
        _loadingDocs = false;
        if (res.success) _documents = res.data;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _token == null) return;
    setState(() => _saving = true);

    final body = {
      'user_id': widget.userId,
      'name': _nameCtrl.text.trim(),
      'type': _type.name,
      'tin_number': _tinCtrl.text.trim(),
      'vrn': _vrnCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'license_number': _licenseNumberCtrl.text.trim(),
      'registration_number': _regNumberCtrl.text.trim(),
      'license_expiry': _licenseExpiry?.toIso8601String(),
      'incorporation_date': _incorporationDate?.toIso8601String(),
    };

    final res = _isNew
        ? await BusinessService.createBusiness(_token!, body)
        : await BusinessService.updateBusiness(
            _token!, widget.business!.id!, body);

    if (mounted) {
      setState(() => _saving = false);
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isNew
                ? 'Business registered successfully!'
                : 'Details updated!')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message ?? 'Operation failed')));
      }
    }
  }

  Future<void> _pickDate(bool isLicense) async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (dt != null && mounted) {
      setState(() {
        if (isLicense) {
          _licenseExpiry = dt;
        } else {
          _incorporationDate = dt;
        }
      });
    }
  }

  Future<void> _uploadDocument(DocumentType type) async {
    if (_token == null || widget.business?.id == null) return;
    final picker = ImagePicker();
    // Using image picker for simplicity; in production, use file_picker for PDFs
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _loadingDocs = true);
    final res = await BusinessService.uploadDocument(
        _token!, widget.business!.id!, type.name, File(picked.path));
    if (mounted) {
      setState(() => _loadingDocs = false);
      if (res.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Document uploaded!')));
        _loadDocuments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message ?? 'Upload failed')));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tinCtrl.dispose();
    _vrnCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _licenseNumberCtrl.dispose();
    _regNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isNew ? 'Register Business' : 'Business Profile',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.menu_book_rounded, color: _kSecondary),
              tooltip: 'Registration Steps',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegistrationGuidePage())),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Business Details ----
            _sectionTitle('Business Details'),
            const SizedBox(height: 10),
            _field(_nameCtrl, 'Business Name', required: true),
            const SizedBox(height: 12),

            // Type dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BusinessType>(
                  value: _type,
                  isExpanded: true,
                  items: BusinessType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(businessTypeLabel(t))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _field(_addressCtrl, 'Address'),
            const SizedBox(height: 12),
            _field(_phoneCtrl, 'Phone',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _field(_emailCtrl, 'Email',
                keyboardType: TextInputType.emailAddress),

            const SizedBox(height: 24),

            // ---- Registration ----
            _sectionTitle('Registration & License'),
            const SizedBox(height: 10),
            _field(_regNumberCtrl, 'Registration Number (BRELA)'),
            const SizedBox(height: 12),
            _field(_tinCtrl, 'TIN Number (TRA)',
                hint: 'e.g. XXX-XXX-XXX'),
            const SizedBox(height: 12),
            _field(_vrnCtrl, 'VRN (VAT Number)',
                hint: 'If applicable'),
            const SizedBox(height: 12),
            _field(_licenseNumberCtrl, 'License Number'),
            const SizedBox(height: 12),
            _dateField(
              'License Expiry Date',
              _licenseExpiry,
              () => _pickDate(true),
              df,
            ),
            const SizedBox(height: 12),
            _dateField(
              'Incorporation Date',
              _incorporationDate,
              () => _pickDate(false),
              df,
            ),

            const SizedBox(height: 24),

            // ---- Document Vault ----
            if (!_isNew) ...[
              _sectionTitle('Business Documents'),
              const SizedBox(height: 10),
              if (_loadingDocs)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: _kPrimary),
                ))
              else ...[
                ..._documents.map((doc) => _documentTile(doc)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DocumentType.values.map((dt) {
                    final exists =
                        _documents.any((d) => d.type == dt);
                    return ActionChip(
                      avatar: Icon(
                        exists
                            ? Icons.check_circle_rounded
                            : Icons.upload_file_rounded,
                        size: 16,
                        color: exists ? Colors.green : _kSecondary,
                      ),
                      label: Text(documentTypeLabel(dt),
                          style: const TextStyle(fontSize: 11)),
                      onPressed: exists ? null : () => _uploadDocument(dt),
                      backgroundColor: _kCardBg,
                      side: BorderSide(color: Colors.grey.shade200),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
            ],

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_isNew ? 'Register Business' : 'Save Changes',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary));
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false,
      TextInputType keyboardType = TextInputType.text,
      String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: _kCardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _dateField(
      String label, DateTime? value, VoidCallback onTap, DateFormat df) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _kCardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          suffixIcon:
              const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        child: Text(
          value != null ? df.format(value) : 'Select date',
          style: TextStyle(
            color: value != null ? _kPrimary : _kSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _documentTile(BusinessDocument doc) {
    final df = DateFormat('dd/MM/yyyy');
    final isExpiring = doc.expiryDate != null &&
        doc.expiryDate!.difference(DateTime.now()).inDays <= 30;
    final isExpired =
        doc.expiryDate != null && doc.expiryDate!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpired
              ? Colors.red.shade200
              : isExpiring
                  ? Colors.orange.shade200
                  : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_rounded,
            color: isExpired
                ? Colors.red.shade700
                : isExpiring
                    ? Colors.orange.shade700
                    : _kPrimary,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(documentTypeLabel(doc.type),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _kPrimary)),
                if (doc.expiryDate != null)
                  Text(
                    isExpired
                        ? 'Expired: ${df.format(doc.expiryDate!)}'
                        : 'Expires: ${df.format(doc.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isExpired
                          ? Colors.red.shade700
                          : isExpiring
                              ? Colors.orange.shade700
                              : _kSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              size: 18, color: Colors.green.shade600),
        ],
      ),
    );
  }
}
