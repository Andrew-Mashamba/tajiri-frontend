import 'package:flutter/material.dart';
import '../../services/poll_service.dart';

/// Create Poll screen – reachable via Home → Feed → Create Post → Poll.
/// Design: DOCS/DESIGN.md (SafeArea, 48dp touch targets, monochrome).
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

  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _iconBg = Color(0xFF1A1A1A);
  static const Color _accent = Color(0xFF999999);

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
    if (date != null && mounted) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (time != null && mounted) {
      setState(() => _endTime = time);
    }
  }

  Future<void> _createPoll() async {
    if (_formKey.currentState?.validate() != true) return;

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

    if (!mounted) return;
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
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Unda Kura'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _primaryText,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _isLoading ? null : _createPoll,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unda'),
                  ),
                ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _questionController,
                  maxLines: 2,
                  style: const TextStyle(color: _primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Swali *',
                    hintText: 'Andika swali lako hapa...',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: _secondaryText),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Swali linahitajika' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: const TextStyle(color: _primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Maelezo ya ziada',
                    hintText: 'Eleza zaidi kuhusu kura hii...',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: _secondaryText),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chaguo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryText,
                      ),
                    ),
                    Text(
                      '${_optionControllers.length}/10',
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(_optionControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _iconBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[index],
                            style: const TextStyle(
                              color: _primaryText,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Chaguo ${index + 1}',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        if (_optionControllers.length > 2) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeOption(index),
                            icon: const Icon(Icons.remove_circle_outline),
                            color: _secondaryText,
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (_optionControllers.length < 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Ongeza chaguo'),
                      style: TextButton.styleFrom(
                        foregroundColor: _primaryText,
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Mipangilio',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text(
                    'Ruhusu chaguo nyingi',
                    style: TextStyle(color: _primaryText, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Watu wanaweza kuchagua zaidi ya moja',
                    style: TextStyle(color: _secondaryText, fontSize: 11),
                  ),
                  value: _allowMultipleVotes,
                  onChanged: (v) => setState(() => _allowMultipleVotes = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text(
                    'Kura za siri',
                    style: TextStyle(color: _primaryText, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Wengine hawataona nani amechagua nini',
                    style: TextStyle(color: _secondaryText, fontSize: 11),
                  ),
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text(
                    'Weka muda wa mwisho',
                    style: TextStyle(color: _primaryText, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Kura itafungwa baada ya muda',
                    style: TextStyle(color: _secondaryText, fontSize: 11),
                  ),
                  value: _hasEndDate,
                  onChanged: (v) => setState(() => _hasEndDate = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_hasEndDate) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.1),
                          child: InkWell(
                            onTap: _selectEndDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 20, color: _accent),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Tarehe',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _secondaryText,
                                        ),
                                      ),
                                      Text(
                                        '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: _primaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.1),
                          child: InkWell(
                            onTap: _selectEndTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 20, color: _accent),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Saa',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _secondaryText,
                                        ),
                                      ),
                                      Text(
                                        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: _primaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.preview, size: 20, color: _accent),
                          const SizedBox(width: 8),
                          const Text(
                            'Mtazamo wa awali',
                            style: TextStyle(
                              color: _secondaryText,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      ..._optionControllers
                          .where((c) => c.text.isNotEmpty)
                          .map((c) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: _accent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _allowMultipleVotes
                                    ? Icons.check_box_outline_blank
                                    : Icons.radio_button_unchecked,
                                size: 20,
                                color: _secondaryText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.text,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _primaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
