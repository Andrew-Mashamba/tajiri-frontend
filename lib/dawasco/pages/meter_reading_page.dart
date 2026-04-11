// lib/dawasco/pages/meter_reading_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MeterReadingPage extends StatefulWidget {
  final WaterAccount? account;
  const MeterReadingPage({super.key, this.account});
  @override
  State<MeterReadingPage> createState() => _MeterReadingPageState();
}

class _MeterReadingPageState extends State<MeterReadingPage> {
  final _readingCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  bool _submitting = false;
  File? _photo;

  @override
  void initState() {
    super.initState();
    if (widget.account?.accountNumber != null) {
      _accountCtrl.text = widget.account!.accountNumber;
    }
  }

  @override
  void dispose() {
    _readingCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 80);
      if (xFile != null && mounted) {
        setState(() => _photo = File(xFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw ? 'Imeshindwa kuchukua picha' : 'Failed to take photo')));
    }
  }

  Future<void> _submit() async {
    final sw = _sw;
    final account = _accountCtrl.text.trim();
    final reading = double.tryParse(_readingCtrl.text.trim());

    if (account.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw ? 'Weka namba ya akaunti' : 'Enter account number')));
      return;
    }
    if (reading == null || reading <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw ? 'Weka usomaji wa mita sahihi' : 'Enter valid meter reading')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await DawascoService.submitMeterReading({
        'account_number': account,
        'reading': reading,
      }, photoPath: _photo?.path);
      if (!mounted) return;
      setState(() => _submitting = false);
      final messenger = ScaffoldMessenger.of(context);
      if (result.success) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw ? 'Usomaji umewasilishwa!' : 'Reading submitted!')));
        Navigator.pop(context, true);
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(result.message ?? (sw ? 'Imeshindwa' : 'Failed'))));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Soma Mita ya Maji' : 'Submit Meter Reading',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 20, color: _kPrimary),
            const SizedBox(width: 10),
            Expanded(child: Text(
              sw ? 'Soma mita yako na uwasilishe usomaji hapa ili kupata bili sahihi.'
                  : 'Read your meter and submit the reading here for accurate billing.',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 3, overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
        const SizedBox(height: 20),

        // Account number
        Text(sw ? 'Namba ya Akaunti' : 'Account Number',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _accountCtrl,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: sw ? 'Namba ya akaunti yako' : 'Your account number',
            hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
        ),
        const SizedBox(height: 16),

        // Meter reading
        Text(sw ? 'Usomaji wa Mita (m\u00B3)' : 'Meter Reading (m\u00B3)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _readingCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: sw ? 'Mfano: 12345.6' : 'e.g. 12345.6',
            hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
        ),
        const SizedBox(height: 16),

        // Photo
        Text(sw ? 'Picha ya Mita' : 'Meter Photo',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            height: _photo != null ? 200 : 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
            ),
            child: _photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(children: [
                      Image.file(_photo!, width: double.infinity, height: 200, fit: BoxFit.cover),
                      Positioned(top: 8, right: 8, child: GestureDetector(
                        onTap: () => setState(() => _photo = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        ),
                      )),
                    ]),
                  )
                : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.camera_alt_rounded, size: 28, color: _kPrimary.withValues(alpha: 0.4)),
                    const SizedBox(height: 4),
                    Text(sw ? 'Piga picha ya mita' : 'Take meter photo',
                        style: TextStyle(fontSize: 12, color: _kPrimary.withValues(alpha: 0.5))),
                  ])),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          height: 48, width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(sw ? 'Wasilisha Usomaji' : 'Submit Reading',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
