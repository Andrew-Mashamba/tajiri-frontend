import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/event_service.dart';

/// Create Event screen (Story 46).
/// Navigation: Home → Events discover OR Profile → Events → Create.
/// When [groupId] is set (e.g. from group chat), the event is linked to that group (in-group events).
/// Design: DOCS/DESIGN.md — monochrome, 48dp touch targets, overflow prevention.
class CreateEventScreen extends StatefulWidget {
  final int creatorId;
  /// When creating from a group chat, pass the group/conversation id so the event is linked.
  final int? groupId;

  const CreateEventScreen({super.key, required this.creatorId, this.groupId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _onlineLinkController = TextEditingController();
  final EventService _eventService = EventService();

  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const Color _buttonBg = Color(0xFFFFFFFF);

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _startTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isAllDay = false;
  bool _isOnline = false;
  File? _coverPhoto;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _onlineLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() => _coverPhoto = File(image.path));
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null && mounted) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null && mounted) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _eventService.createEvent(
      creatorId: widget.creatorId,
      name: _titleController.text.trim(),
      startDate: _startDate,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      startTime: !_isAllDay && _startTime != null
          ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
          : null,
      isAllDay: _isAllDay,
      locationName: !_isOnline && _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      locationAddress: !_isOnline && _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      isOnline: _isOnline,
      onlineLink: _isOnline && _onlineLinkController.text.trim().isNotEmpty
          ? _onlineLinkController.text.trim()
          : null,
      groupId: widget.groupId,
      coverPhoto: _coverPhoto,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tukio limeundwa')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Imeshindikana kuunda tukio'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _buttonBg,
        foregroundColor: _primaryText,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        title: const Text(
          'Unda Tukio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
        actions: [
          SemanticButton(
            minSize: const Size(48, 48),
            onPressed: _isLoading ? null : _createEvent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Unda',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCoverPhotoSection(),
                const SizedBox(height: 24),
                _buildTitleField(),
                const SizedBox(height: 16),
                _buildDateSection(),
                const SizedBox(height: 12),
                _buildAllDaySwitch(),
                if (!_isAllDay) _buildTimeSection(),
                const SizedBox(height: 16),
                _buildOnlineSwitch(),
                const SizedBox(height: 12),
                _buildLocationSection(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPhotoSection() {
    return Semantics(
      button: true,
      label: 'Ongeza picha ya jalada',
      child: GestureDetector(
        onTap: _isLoading ? null : _pickCoverPhoto,
        child: Container(
          height: 150,
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            image: _coverPhoto != null
                ? DecorationImage(
                    image: FileImage(_coverPhoto!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _coverPhoto == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: _secondaryText,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ongeza picha ya jalada',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: const TextStyle(color: _primaryText, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Jina la tukio *',
        hintText: 'Weka jina la tukio',
        labelStyle: const TextStyle(color: _secondaryText),
        hintStyle: const TextStyle(color: _accent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _buttonBg,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Jina linahitajika';
        }
        return null;
      },
    );
  }

  Widget _buildDateSection() {
    return Material(
      color: _buttonBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: _isLoading ? null : _selectDate,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: _primaryText, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tarehe',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, d MMM yyyy', 'sw').format(_startDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _secondaryText, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllDaySwitch() {
    return Material(
      color: _buttonBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: SwitchListTile(
        title: const Text(
          'Siku nzima',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _primaryText,
          ),
        ),
        value: _isAllDay,
        onChanged: _isLoading
            ? null
            : (value) => setState(() => _isAllDay = value),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: _buttonBg,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: _isLoading ? null : _selectTime,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.access_time, color: _primaryText, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Saa',
                        style: TextStyle(
                          fontSize: 12,
                          color: _secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _startTime != null
                            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                            : 'Chagua saa',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: _secondaryText, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineSwitch() {
    return Material(
      color: _buttonBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: SwitchListTile(
        title: const Text(
          'Tukio la mtandaoni',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _primaryText,
          ),
        ),
        subtitle: const Text(
          'Tukio litafanyika kupitia mtandao',
          style: TextStyle(fontSize: 11, color: _secondaryText),
        ),
        value: _isOnline,
        onChanged: _isLoading
            ? null
            : (value) => setState(() => _isOnline = value),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildLocationSection() {
    if (_isOnline) {
      return TextFormField(
        controller: _onlineLinkController,
        style: const TextStyle(color: _primaryText, fontSize: 14),
        decoration: InputDecoration(
          labelText: 'Kiungo cha mkutano',
          hintText: 'https://...',
          labelStyle: const TextStyle(color: _secondaryText),
          hintStyle: const TextStyle(color: _accent),
          prefixIcon: const Icon(Icons.link, color: _secondaryText),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _buttonBg,
        ),
        keyboardType: TextInputType.url,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _locationController,
          style: const TextStyle(color: _primaryText, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Mahali',
            hintText: 'Weka mahali',
            labelStyle: const TextStyle(color: _secondaryText),
            hintStyle: const TextStyle(color: _accent),
            prefixIcon: const Icon(Icons.location_on, color: _secondaryText),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: _buttonBg,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          style: const TextStyle(color: _primaryText, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Anwani',
            hintText: 'Anwani kamili',
            labelStyle: const TextStyle(color: _secondaryText),
            hintStyle: const TextStyle(color: _accent),
            prefixIcon: const Icon(Icons.map, color: _secondaryText),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: _buttonBg,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      maxLength: 1000,
      style: const TextStyle(color: _primaryText, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Maelezo',
        hintText: 'Eleza tukio lako...',
        labelStyle: const TextStyle(color: _secondaryText),
        hintStyle: const TextStyle(color: _accent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _buttonBg,
      ),
    );
  }
}

/// Wrapper to enforce 48dp minimum touch target (DESIGN.md).
class SemanticButton extends StatelessWidget {
  const SemanticButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.minSize = const Size(48, 48),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Size minSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minSize.width,
            minHeight: minSize.height,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
