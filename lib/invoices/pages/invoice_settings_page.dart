// lib/invoices/pages/invoice_settings_page.dart
// Invoice settings/configuration — number prefix, payment terms, VAT,
// payment instructions, notes, auto-reminders.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../business/services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class InvoiceSettingsPage extends StatefulWidget {
  final int businessId;
  const InvoiceSettingsPage({super.key, required this.businessId});

  @override
  State<InvoiceSettingsPage> createState() => _InvoiceSettingsPageState();
}

class _InvoiceSettingsPageState extends State<InvoiceSettingsPage> {
  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? _token;

  late TextEditingController _prefixCtrl;
  late TextEditingController _paymentInstructionsCtrl;
  late TextEditingController _notesCtrl;

  String _paymentTerms = 'net_30';
  bool _includeVat = true;
  bool _autoReminder = false;
  List<int> _reminderDays = [];
  final Set<String> _reminderChannels = {};
  int _nextSequence = 1;
  String? _logoUrl;
  String? _pickedLogoPath; // Path of newly picked logo, pending upload on save
  final _picker = ImagePicker();

  static const List<int> _availableReminderDays = [1, 3, 7, 14];

  @override
  void initState() {
    super.initState();
    _prefixCtrl = TextEditingController(text: 'INV');
    _paymentInstructionsCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _paymentInstructionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final storage = await LocalStorageService.getInstance();
      _token = storage.getAuthToken();
      if (_token == null) {
        if (!mounted) return;
        setState(() {
          _error = _sw ? 'Tafadhali ingia kwanza' : 'Please log in first';
          _loading = false;
        });
        return;
      }
      final result =
          await BusinessService.getInvoiceSettings(_token!, widget.businessId);
      if (!mounted) return;
      if (result.success && result.data != null) {
        final s = result.data!;
        _prefixCtrl.text = s.numberPrefix;
        _paymentTerms = s.defaultPaymentTerms;
        _includeVat = s.defaultIncludeVat;
        _paymentInstructionsCtrl.text = s.defaultPaymentInstructions ?? '';
        _notesCtrl.text = s.defaultNotes ?? '';
        _autoReminder = s.autoReminderEnabled;
        _reminderDays = List<int>.from(s.reminderDaysAfterDue);
        _nextSequence = s.nextSequence;
        _logoUrl = s.logoUrl;
      }
      // If 404/failure, keep defaults from controllers
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_token == null) return;
      final body = {
        'number_prefix': _prefixCtrl.text.trim(),
        'default_payment_terms': _paymentTerms,
        'default_include_vat': _includeVat,
        'default_payment_instructions':
            _paymentInstructionsCtrl.text.trim().isEmpty
                ? null
                : _paymentInstructionsCtrl.text.trim(),
        'default_notes': _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        'auto_reminder_enabled': _autoReminder,
        'reminder_days_after_due': _reminderDays,
        'reminder_channels': _reminderChannels.toList(),
        'logo_url': _logoUrl,
        // If a new logo was picked locally, include the path so the backend
        // can handle the upload. Full multipart upload can be added later.
        if (_pickedLogoPath != null) 'logo_path': _pickedLogoPath,
      };
      final result = await BusinessService.updateInvoiceSettings(
          _token!, widget.businessId, body);
      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _sw ? 'Mipangilio imehifadhiwa' : 'Settings saved'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? (_sw ? 'Hitilafu' : 'Error')),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _sw ? 'Mipangilio ya Ankara' : 'Invoice Settings',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        style: const TextStyle(color: _kSecondary)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildNumberingSection(),
                    const SizedBox(height: 16),
                    _buildPaymentTermsSection(),
                    const SizedBox(height: 16),
                    _buildVatSection(),
                    const SizedBox(height: 16),
                    _buildPaymentInstructionsSection(),
                    const SizedBox(height: 16),
                    _buildNotesSection(),
                    const SizedBox(height: 16),
                    _buildLogoSection(),
                    const SizedBox(height: 16),
                    _buildAutoRemindersSection(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: _kBackground,
      labelStyle: const TextStyle(color: _kSecondary, fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kPrimary, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // --- Section 1: Numbering ---
  Widget _buildNumberingSection() {
    final prefix = _prefixCtrl.text.trim().isEmpty ? 'INV' : _prefixCtrl.text.trim();
    final year = DateTime.now().year;
    final preview = '$prefix-$year-${_nextSequence.toString().padLeft(4, '0')}';

    return _sectionCard(children: [
      Text(
        _sw ? 'Utaratibu wa Nambari' : 'Numbering',
        style: const TextStyle(
            color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _prefixCtrl,
        decoration:
            _inputDecoration(_sw ? 'Kiambishi awali' : 'Prefix'),
        style: const TextStyle(color: _kPrimary, fontSize: 14),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 8),
      Text(
        '${_sw ? 'Ankara ijayo' : 'Next invoice'}: $preview',
        style: const TextStyle(color: _kSecondary, fontSize: 13),
      ),
      const SizedBox(height: 4),
      Text(
        _sw
            ? 'Nambari haziwezi kurudi nyuma'
            : 'Numbers cannot be reset',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
    ]);
  }

  // --- Section 2: Default Payment Terms ---
  Widget _buildPaymentTermsSection() {
    return _sectionCard(children: [
      Text(
        _sw ? 'Masharti ya Malipo' : 'Default Payment Terms',
        style: const TextStyle(
            color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: ValueKey('payment_terms_$_paymentTerms'),
        initialValue: _paymentTerms,
        decoration: _inputDecoration(''),
        dropdownColor: _kCardBg,
        style: const TextStyle(color: _kPrimary, fontSize: 14),
        items: const [
          DropdownMenuItem(value: 'net_7', child: Text('Net 7')),
          DropdownMenuItem(value: 'net_14', child: Text('Net 14')),
          DropdownMenuItem(value: 'net_30', child: Text('Net 30')),
          DropdownMenuItem(value: 'net_60', child: Text('Net 60')),
        ],
        onChanged: (v) {
          if (v != null) setState(() => _paymentTerms = v);
        },
      ),
      const SizedBox(height: 8),
      Text(
        _sw
            ? 'Hii itatumika kwa ankara zote mpya'
            : 'This will be used for all new invoices',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
    ]);
  }

  // --- Section 3: Default VAT ---
  Widget _buildVatSection() {
    return _sectionCard(children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: _kPrimary,
        title: Text(
          _sw
              ? 'Jumuisha VAT kwa ankara zote'
              : 'Include VAT on all invoices',
          style: const TextStyle(
              color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        value: _includeVat,
        onChanged: (v) => setState(() => _includeVat = v),
      ),
    ]);
  }

  // --- Section 4: Default Payment Instructions ---
  Widget _buildPaymentInstructionsSection() {
    return _sectionCard(children: [
      Text(
        _sw ? 'Maelekezo ya Malipo' : 'Payment Instructions',
        style: const TextStyle(
            color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _paymentInstructionsCtrl,
        maxLines: 3,
        decoration: _inputDecoration(
          _sw ? 'Maelekezo ya malipo' : 'Payment instructions',
          hint: _sw
              ? 'Ongeza nambari yako ya M-Pesa na akaunti ya benki'
              : 'Add your M-Pesa number and bank account',
        ),
        style: const TextStyle(color: _kPrimary, fontSize: 14),
      ),
    ]);
  }

  // --- Section 5: Default Notes/Terms ---
  Widget _buildNotesSection() {
    return _sectionCard(children: [
      Text(
        _sw ? 'Masharti na Maelezo' : 'Notes & Terms',
        style: const TextStyle(
            color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _notesCtrl,
        maxLines: 3,
        decoration: _inputDecoration(
          _sw ? 'Maelezo' : 'Notes',
          hint: _sw
              ? 'Masharti ya biashara, sera ya urejeshaji, n.k.'
              : 'Business terms, return policy, etc.',
        ),
        style: const TextStyle(color: _kPrimary, fontSize: 14),
      ),
    ]);
  }

  // --- Section 6: Logo ---
  Widget _buildLogoSection() {
    return _sectionCard(children: [
      Text(
        _sw ? 'Nembo / Logo' : 'Logo',
        style: const TextStyle(
            color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      if (_logoUrl != null && _logoUrl!.isNotEmpty) ...[
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _kBackground,
                backgroundImage: _pickedLogoPath != null
                    ? FileImage(File(_pickedLogoPath!))
                    : NetworkImage(_logoUrl!) as ImageProvider,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _logoUrl = null;
                  _pickedLogoPath = null;
                }),
                child: Text(
                  _sw ? 'Ondoa' : 'Remove',
                  style: const TextStyle(
                      color: Colors.red, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ] else
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              color: _kBackground,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_rounded,
                    size: 28, color: Colors.grey.shade400),
                const SizedBox(height: 6),
                Text(
                  _sw ? 'Pakua nembo' : 'Upload logo',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
    ]);
  }

  Future<void> _pickLogo() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;
      setState(() {
        _pickedLogoPath = image.path;
        _logoUrl = image.path; // Show local preview
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _sw
                  ? 'Nembo imechaguliwa. Itapakiwa unapohifadhi mipangilio'
                  : 'Logo selected. Will be uploaded when you save settings'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _sw ? 'Imeshindikana kuchagua picha' : 'Failed to pick image'),
        ),
      );
    }
  }

  // --- Section 7: Auto-Reminders ---
  Widget _buildAutoRemindersSection() {
    return _sectionCard(children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: _kPrimary,
        title: Text(
          _sw
              ? 'Vikumbusho vya moja kwa moja'
              : 'Auto-reminders',
          style: const TextStyle(
              color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        value: _autoReminder,
        onChanged: (v) => setState(() => _autoReminder = v),
      ),
      if (_autoReminder) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableReminderDays.map((day) {
            final selected = _reminderDays.contains(day);
            return FilterChip(
              label: Text(
                _sw ? '$day ${day == 1 ? 'siku' : 'siku'}' : '$day ${day == 1 ? 'day' : 'days'}',
                style: TextStyle(
                  color: selected ? Colors.white : _kPrimary,
                  fontSize: 13,
                ),
              ),
              selected: selected,
              selectedColor: _kPrimary,
              backgroundColor: _kBackground,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _reminderDays.add(day);
                    _reminderDays.sort();
                  } else {
                    _reminderDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text(
          _sw ? 'Tuma kupitia' : 'Send via',
          style: const TextStyle(
              color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              avatar: Icon(Icons.chat_rounded, size: 16,
                  color: _reminderChannels.contains('whatsapp') ? Colors.white : _kSecondary),
              label: Text('WhatsApp',
                  style: TextStyle(
                    color: _reminderChannels.contains('whatsapp') ? Colors.white : _kPrimary,
                    fontSize: 13)),
              selected: _reminderChannels.contains('whatsapp'),
              selectedColor: _kPrimary,
              backgroundColor: _kBackground,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _reminderChannels.add('whatsapp');
                  } else {
                    _reminderChannels.remove('whatsapp');
                  }
                });
              },
            ),
            FilterChip(
              avatar: Icon(Icons.email_rounded, size: 16,
                  color: _reminderChannels.contains('email') ? Colors.white : _kSecondary),
              label: Text(_sw ? 'Barua pepe' : 'Email',
                  style: TextStyle(
                    color: _reminderChannels.contains('email') ? Colors.white : _kPrimary,
                    fontSize: 13)),
              selected: _reminderChannels.contains('email'),
              selectedColor: _kPrimary,
              backgroundColor: _kBackground,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _reminderChannels.add('email');
                  } else {
                    _reminderChannels.remove('email');
                  }
                });
              },
            ),
            FilterChip(
              avatar: Icon(Icons.phone_android_rounded, size: 16,
                  color: _reminderChannels.contains('tajiri') ? Colors.white : _kSecondary),
              label: Text('TAJIRI',
                  style: TextStyle(
                    color: _reminderChannels.contains('tajiri') ? Colors.white : _kPrimary,
                    fontSize: 13)),
              selected: _reminderChannels.contains('tajiri'),
              selectedColor: _kPrimary,
              backgroundColor: _kBackground,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _reminderChannels.add('tajiri');
                  } else {
                    _reminderChannels.remove('tajiri');
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _sw
              ? 'Vikumbusho vitatumwa moja kwa moja kwa ankara zilizochelewa'
              : 'Reminders will be sent automatically for overdue invoices',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ],
    ]);
  }

  // --- Section 7: Save Button ---
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _sw ? 'Hifadhi' : 'Save',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
