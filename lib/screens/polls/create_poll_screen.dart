import 'package:flutter/material.dart';
import '../../services/poll_service.dart';

class CreatePollScreen extends StatefulWidget {
  final int creatorId;
  final int? groupId;
  final int? pageId;

  const CreatePollScreen({
    super.key,
    required this.creatorId,
    this.groupId,
    this.pageId,
  });

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PollService _pollService = PollService();

  List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _allowMultipleVotes = false;
  bool _isAnonymous = false;
  bool _hasEndDate = false;
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate options
    final validOptions = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (validOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unahitaji angalau chaguo 2')),
      );
      return;
    }

    // Check for duplicate options
    final uniqueOptions = validOptions.toSet();
    if (uniqueOptions.length != validOptions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chaguo havipaswi kurudiwa')),
      );
      return;
    }

    setState(() => _isLoading = true);

    DateTime? endsAt;
    if (_hasEndDate) {
      endsAt = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );
    }

    final result = await _pollService.createPoll(
      creatorId: widget.creatorId,
      question: _questionController.text.trim(),
      options: validOptions,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      allowMultipleVotes: _allowMultipleVotes,
      isAnonymous: _isAnonymous,
      endsAt: endsAt,
      groupId: widget.groupId,
      pageId: widget.pageId,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kura imeundwa')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindikana kuunda kura')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unda Kura'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPoll,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
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
            // Question
            TextFormField(
              controller: _questionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Swali *',
                hintText: 'Andika swali lako hapa...',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Swali linahitajika' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Maelezo ya ziada',
                hintText: 'Eleza zaidi kuhusu kura hii...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Options header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chaguo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_optionControllers.length}/10',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Options list
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Chaguo ${index + 1}',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removeOption(index),
                        icon: Icon(Icons.remove_circle, color: Colors.red.shade400),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // Add option button
            if (_optionControllers.length < 10)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Ongeza chaguo'),
              ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Settings
            const Text(
              'Mipangilio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Ruhusu chaguo nyingi'),
              subtitle: const Text('Watu wanaweza kuchagua zaidi ya moja'),
              value: _allowMultipleVotes,
              onChanged: (v) => setState(() => _allowMultipleVotes = v),
            ),

            SwitchListTile(
              title: const Text('Kura za siri'),
              subtitle: const Text('Wengine hawataona nani amechagua nini'),
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
            ),

            SwitchListTile(
              title: const Text('Weka muda wa mwisho'),
              subtitle: const Text('Kura itafungwa baada ya muda'),
              value: _hasEndDate,
              onChanged: (v) => setState(() => _hasEndDate = v),
            ),

            // End date/time
            if (_hasEndDate) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.calendar_today, color: Colors.purple.shade600),
                      title: const Text('Tarehe'),
                      subtitle: Text(
                        '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                      ),
                      onTap: _selectEndDate,
                      tileColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.access_time, color: Colors.purple.shade600),
                      title: const Text('Saa'),
                      subtitle: Text(
                        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                      ),
                      onTap: _selectEndTime,
                      tileColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Preview card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.preview, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Mtazamo wa awali',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _questionController.text.isEmpty
                        ? 'Swali lako litaonekana hapa...'
                        : _questionController.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._optionControllers.where((c) => c.text.isNotEmpty).map((c) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _allowMultipleVotes
                                ? Icons.check_box_outline_blank
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Text(c.text),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
