import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  final int creatorId;

  const CreateEventScreen({super.key, required this.creatorId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _onlineLinkController = TextEditingController();
  final EventService _eventService = EventService();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _startTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isAllDay = false;
  bool _isOnline = false;
  File? _coverPhoto;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _onlineLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
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
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _eventService.createEvent(
      creatorId: widget.creatorId,
      name: _nameController.text.trim(),
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
      coverPhoto: _coverPhoto,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tukio limeundwa')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindikana kuunda tukio')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unda Tukio'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createEvent,
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Unda'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover photo
            GestureDetector(
              onTap: _pickCoverPhoto,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  image: _coverPhoto != null
                      ? DecorationImage(image: FileImage(_coverPhoto!), fit: BoxFit.cover)
                      : null,
                ),
                child: _coverPhoto == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 48, color: Colors.orange.shade500),
                          const SizedBox(height: 8),
                          Text('Ongeza picha ya jalada', style: TextStyle(color: Colors.orange.shade700)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Jina la tukio *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Jina linahitajika' : null,
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.orange.shade700),
              title: const Text('Tarehe'),
              subtitle: Text(DateFormat('EEEE, MMMM d, yyyy', 'sw').format(_startDate)),
              onTap: _selectDate,
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 8),

            // All day switch
            SwitchListTile(
              title: const Text('Siku nzima'),
              value: _isAllDay,
              onChanged: (v) => setState(() => _isAllDay = v),
            ),

            // Time
            if (!_isAllDay) ...[
              ListTile(
                leading: Icon(Icons.access_time, color: Colors.orange.shade700),
                title: const Text('Saa'),
                subtitle: Text(_startTime != null
                    ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                    : 'Chagua saa'),
                onTap: _selectTime,
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ],
            const SizedBox(height: 16),

            // Online switch
            SwitchListTile(
              title: const Text('Tukio la mtandaoni'),
              subtitle: const Text('Tukio litafanyika kupitia mtandao'),
              value: _isOnline,
              onChanged: (v) => setState(() => _isOnline = v),
            ),
            const SizedBox(height: 8),

            // Location or Online link
            if (_isOnline)
              TextFormField(
                controller: _onlineLinkController,
                decoration: const InputDecoration(
                  labelText: 'Kiungo cha mkutano',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              )
            else ...[
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Mahali',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Anwani',
                  prefixIcon: Icon(Icons.map),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Maelezo',
                hintText: 'Eleza tukio lako...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
