// lib/my_pregnancy/pages/pregnancy_journal_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/my_pregnancy_models.dart';
import '../services/my_pregnancy_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class PregnancyJournalPage extends StatefulWidget {
  final Pregnancy pregnancy;
  final int userId;

  const PregnancyJournalPage({
    super.key,
    required this.pregnancy,
    required this.userId,
  });

  @override
  State<PregnancyJournalPage> createState() => _PregnancyJournalPageState();
}

class _PregnancyJournalPageState extends State<PregnancyJournalPage> {
  final MyPregnancyService _service = MyPregnancyService();

  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  bool _isSaving = false;

  String? get _token =>
      LocalStorageService.instanceSync?.getAuthToken();

  bool get _sw =>
      LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getJournalEntries(
        widget.pregnancy.id,
        token: _token,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) {
            _entries = result.items;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showWriteEntrySheet() {
    final sw = _sw;
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    File? selectedPhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Andika Leo' : "Write Today's Entry",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 300)),
                        lastDate: DateTime.now(),
                        helpText: sw ? 'Chagua tarehe' : 'Select date',
                        cancelText: sw ? 'Ghairi' : 'Cancel',
                        confirmText: sw ? 'Chagua' : 'Select',
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: _kSecondary),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sw ? 'Tarehe' : 'Date',
                                style: const TextStyle(
                                    fontSize: 11, color: _kSecondary),
                              ),
                              Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  TextField(
                    controller: notesController,
                    maxLines: 5,
                    minLines: 3,
                    decoration: InputDecoration(
                      labelText: sw ? 'Maandishi' : 'Notes',
                      hintText: sw
                          ? 'Andika hisia zako, mawazo, au kumbukumbu...'
                          : 'Write your feelings, thoughts, or memories...',
                      labelStyle:
                          const TextStyle(fontSize: 13, color: _kSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Photo picker
                  if (selectedPhoto != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            selectedPhoto!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedPhoto = null),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: () => _showPhotoSourceSheet(ctx, (file) {
                        setSheetState(() => selectedPhoto = file);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt_rounded,
                                size: 18, color: _kSecondary),
                            const SizedBox(width: 8),
                            Text(
                              sw ? 'Ongeza Picha' : 'Add Photo',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              final notes = notesController.text.trim();
                              if (notes.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(sw
                                        ? 'Tafadhali andika kitu'
                                        : 'Please write something'),
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(ctx);
                              await _saveEntry(
                                  notes, selectedDate, selectedPhoto);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPhotoSourceSheet(BuildContext ctx, void Function(File) onPicked) {
    final sw = _sw;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.photo_library_rounded, color: _kPrimary),
                title: Text(sw ? 'Chagua kutoka Picha' : 'Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final xFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, maxWidth: 1200);
                  if (xFile != null) onPicked(File(xFile.path));
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt_rounded, color: _kPrimary),
                title: Text(sw ? 'Piga Picha' : 'Take Photo'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final xFile = await ImagePicker()
                      .pickImage(source: ImageSource.camera, maxWidth: 1200);
                  if (xFile != null) onPicked(File(xFile.path));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveEntry(String notes, DateTime date, File? photo) async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    try {
      final result = await _service.saveJournalEntry(
        pregnancyId: widget.pregnancy.id,
        userId: widget.userId,
        notes: notes,
        date: date,
        photo: photo,
        token: _token,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        if (result.success) {
          messenger.showSnackBar(
            SnackBar(
                content: Text(
                    sw ? 'Imehifadhiwa' : 'Saved')),
          );
          _loadEntries();
        } else {
          messenger.showSnackBar(
            SnackBar(
                content: Text(result.message ??
                    (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Kosa: $e' : 'Error: $e')),
        );
      }
    }
  }

  void _showEntryDetail(Map<String, dynamic> entry) {
    final sw = _sw;
    final notes = entry['notes'] as String? ?? '';
    final dateStr = entry['date']?.toString() ?? '';
    final date = DateTime.tryParse(dateStr);
    final photoUrl = entry['photo_url'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.book_rounded, size: 20, color: _kPrimary),
                  const SizedBox(width: 8),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : (sw ? 'Kumbukumbu' : 'Entry'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Full photo
              if (photoUrl != null && photoUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    photoUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                notes,
                style: const TextStyle(
                    fontSize: 14, color: _kSecondary, height: 1.6),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Daftari la Ujauzito' : 'Pregnancy Journal',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showWriteEntrySheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadEntries,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  children: [
                    // Write today card
                    GestureDetector(
                      onTap: _showWriteEntrySheet,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded,
                                size: 28, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sw
                                        ? 'Andika Kumbukumbu ya Leo'
                                        : "Write Today's Entry",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sw
                                        ? 'Hifadhi hisia na kumbukumbu za ujauzito wako'
                                        : 'Save your pregnancy feelings and memories',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Entries
                    if (_entries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.book_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              sw
                                  ? 'Bado hakuna kumbukumbu'
                                  : 'No entries yet',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sw
                                  ? 'Anza kuandika hisia zako za ujauzito'
                                  : 'Start writing about your pregnancy journey',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade400),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    else
                      ..._entries.map((entry) => _JournalEntryCard(
                            entry: entry,
                            isSwahili: sw,
                            onTap: () => _showEntryDetail(entry),
                          )),
                    const SizedBox(height: 80), // FAB clearance
                  ],
                ),
              ),
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isSwahili;
  final VoidCallback onTap;

  const _JournalEntryCard({
    required this.entry,
    required this.isSwahili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final notes = entry['notes'] as String? ?? '';
    final dateStr = entry['date']?.toString() ?? '';
    final date = DateTime.tryParse(dateStr);
    final photoUrl = entry['photo_url'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show photo thumbnail or book icon
            if (photoUrl != null && photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kPrimary.withValues(alpha: 0.08),
                    ),
                    child: const Icon(Icons.book_rounded,
                        size: 20, color: _kPrimary),
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPrimary.withValues(alpha: 0.08),
                ),
                child: const Icon(Icons.book_rounded,
                    size: 20, color: _kPrimary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (date != null)
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    notes,
                    style: const TextStyle(
                        fontSize: 13, color: _kSecondary, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}
