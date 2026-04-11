// lib/events/pages/emergency_create_page.dart
// Funeral/Msiba emergency event creation — minimal fields, < 2 minutes.
// Auto-creates committee from funeral template and enables M-Pesa contributions.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event_enums.dart';
import '../models/event_template.dart';
import '../models/event_strings.dart';
import '../services/event_service.dart';
import '../services/committee_service.dart';
import '../services/event_contribution_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EmergencyCreatePage extends StatefulWidget {
  final int userId;
  const EmergencyCreatePage({super.key, required this.userId});

  @override
  State<EmergencyCreatePage> createState() => _EmergencyCreatePageState();
}

class _EmergencyCreatePageState extends State<EmergencyCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _marehemu = TextEditingController();
  final _burialLocation = TextEditingController();
  final _mourningLocation = TextEditingController();
  final _eventService = EventService();
  final _committeeService = CommitteeService();
  final _contributionService = EventContributionService();

  DateTime? _burialDate;
  XFile? _photo;
  bool _isSubmitting = false;
  late EventStrings _strings;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
  }

  @override
  void dispose() {
    _marehemu.dispose();
    _burialLocation.dispose();
    _mourningLocation.dispose();
    super.dispose();
  }

  // ── Date picker ──
  Future<void> _pickBurialDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: _kBg,
            surface: _kBg,
            onSurface: _kPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _burialDate = picked);
  }

  // ── Photo picker ──
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _photo = file);
  }

  // ── Submit: create event → committee → enable michango ──
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_burialDate == null) {
      _showSnack(_strings.isSwahili ? 'Chagua tarehe ya mazishi' : 'Select a burial date');
      return;
    }

    setState(() => _isSubmitting = true);

    final marehemu = _marehemu.text.trim();
    final eventName = _strings.isSwahili
        ? 'Msiba wa Marehemu $marehemu'
        : 'Funeral of the Late $marehemu';
    final burialDateStr = _burialDate!.toIso8601String().split('T').first;

    // Step 1: create event
    final eventResult = await _eventService.createEvent(
      name: eventName,
      description: _strings.isSwahili
          ? 'Tukio la mazishi ya Marehemu $marehemu. '
            'Mahali pa mazishi: ${_burialLocation.text.trim()}. '
            'Mahali pa matanga: ${_mourningLocation.text.trim()}.'
          : 'Funeral service for the Late $marehemu. '
            'Burial at: ${_burialLocation.text.trim()}. '
            'Mourning location: ${_mourningLocation.text.trim()}.',
      category: EventCategory.msiba,
      type: EventType.inPerson,
      startDate: burialDateStr,
      locationName: _burialLocation.text.trim(),
      locationAddress: _mourningLocation.text.trim(),
      isFree: true,
      privacy: EventPrivacy.public,
      coverPhotoPath: _photo?.path,
    );

    if (!mounted) return;

    if (!eventResult.success || eventResult.data == null) {
      setState(() => _isSubmitting = false);
      _showSnack(eventResult.message ?? (_strings.isSwahili ? 'Imeshindwa kuunda tukio' : 'Failed to create event'));
      return;
    }

    final event = eventResult.data!;

    // Step 2: auto-create committee from funeral template (fire & forget, surface errors gently)
    await _committeeService.createFromTemplate(
      eventId: event.id,
      eventName: event.name,
      config: KamatiConfig.funeral,
    );

    // Step 3: enable M-Pesa contributions (urgent, no goal)
    await _contributionService.setupMichango(
      eventId: event.id,
      allowAnonymous: true,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    _showSnack(
      _strings.isSwahili
          ? 'Tukio limechapishwa. Michango ya M-Pesa imeamilishwa.'
          : 'Event published. M-Pesa contributions enabled.',
    );

    // Return the created event to the caller
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.of(context).pop(event);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _kPrimary),
    );
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final isSwahili = _strings.isSwahili;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          isSwahili ? 'Msiba — Chapisha Haraka' : 'Funeral — Quick Publish',
          style: const TextStyle(
            color: _kPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // ── Subtitle ──
              Text(
                isSwahili
                    ? 'Jaza taarifa za lazima. Tangazo litatumwa kwa familia na marafiki.'
                    : 'Fill in the required details. An announcement will be sent to family and friends.',
                style: const TextStyle(color: _kSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // ── Marehemu name ──
              _label(isSwahili ? 'Jina la Marehemu *' : 'Name of the Deceased *'),
              const SizedBox(height: 6),
              _field(
                controller: _marehemu,
                hint: isSwahili ? 'Mfano: Juma Ally Hassan' : 'e.g. Juma Ally Hassan',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (isSwahili ? 'Jina la marehemu linahitajika' : 'Name is required')
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Burial date ──
              _label(isSwahili ? 'Tarehe ya Mazishi *' : 'Burial Date *'),
              const SizedBox(height: 6),
              _dateTile(
                value: _burialDate,
                hint: isSwahili ? 'Chagua tarehe' : 'Select date',
                onTap: _pickBurialDate,
              ),
              const SizedBox(height: 20),

              // ── Burial location ──
              _label(isSwahili ? 'Mahali pa Mazishi *' : 'Burial Location *'),
              const SizedBox(height: 6),
              _field(
                controller: _burialLocation,
                hint: isSwahili ? 'Mfano: Makaburi ya Kinondoni' : 'e.g. Kinondoni Cemetery',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (isSwahili ? 'Mahali pa mazishi linahitajika' : 'Burial location required')
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Mourning location ──
              _label(isSwahili ? 'Mahali pa Matanga *' : 'Mourning Location *'),
              const SizedBox(height: 6),
              _field(
                controller: _mourningLocation,
                hint: isSwahili ? 'Mfano: Nyumba ya familia, Dar es Salaam' : 'e.g. Family home, Dar es Salaam',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (isSwahili ? 'Mahali pa matanga linahitajika' : 'Mourning location required')
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Photo (optional) ──
              _label(isSwahili ? 'Picha ya Marehemu (si lazima)' : 'Photo of Deceased (optional)'),
              const SizedBox(height: 6),
              _photoTile(),
              const SizedBox(height: 32),

              // ── Info row: what happens automatically ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kPrimary.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Kitachotokea moja kwa moja:' : 'What happens automatically:',
                      style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    _autoItem(Icons.groups_rounded, isSwahili ? 'Kamati ya msiba itaundwa' : 'Funeral committee will be created'),
                    _autoItem(Icons.phone_android_rounded, isSwahili ? 'Michango ya M-Pesa itaamilishwa' : 'M-Pesa contributions enabled'),
                    _autoItem(Icons.campaign_rounded, isSwahili ? 'Tangazo litatumwa kwa familia' : 'Announcement sent to family'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── CHAPISHA SASA ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: _kBg,
                    disabledBackgroundColor: _kPrimary.withOpacity(0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _kBg),
                        )
                      : Text(
                          isSwahili ? 'CHAPISHA SASA' : 'PUBLISH NOW',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: _kPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: _kPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _kSecondary.withOpacity(0.7), fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _kPrimary.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _kPrimary.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      );

  Widget _dateTile({required DateTime? value, required String hint, required VoidCallback onTap}) {
    final display = value != null ? _strings.formatDateShort(value) : hint;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: _kSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                display,
                style: TextStyle(
                  color: value != null ? _kPrimary : _kSecondary.withOpacity(0.7),
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _photoTile() {
    if (_photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_photo!.path),
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _photo = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: _kBg, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _kPrimary.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_rounded, color: _kSecondary, size: 22),
            const SizedBox(width: 8),
            Text(
              _strings.isSwahili ? 'Ongeza picha' : 'Add photo',
              style: const TextStyle(color: _kSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _autoItem(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _kSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: _kSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
