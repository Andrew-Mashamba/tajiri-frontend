import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F9 #79 — "Request a tour" with agent calendar slots + auto-route.
class PropertyTourRequestPage extends StatefulWidget {
  final int userId;
  final int propertyListingId;
  final int? agentUserId;
  final List<int>? routeListingIds;
  const PropertyTourRequestPage({
    super.key,
    required this.userId,
    required this.propertyListingId,
    this.agentUserId,
    this.routeListingIds,
  });

  @override
  State<PropertyTourRequestPage> createState() => _PropertyTourRequestPageState();
}

class _PropertyTourRequestPageState extends State<PropertyTourRequestPage> {
  DateTime _slot = DateTime.now().add(const Duration(days: 1, hours: 10));
  String _mode = 'in_person';
  bool _submitting = false;

  Future<void> _pickSlot() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _slot,
      firstDate: DateTime.now().add(const Duration(hours: 6)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _slot.hour, minute: _slot.minute),
    );
    if (time == null) return;
    setState(() {
      _slot = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final id = await PropertyTourService.request(
      userId: widget.userId,
      propertyListingId: widget.propertyListingId,
      agentUserId: widget.agentUserId,
      requestedAt: _slot,
      mode: _mode,
      routeListingIds: widget.routeListingIds,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ombi limetumwa')),
      );
      Navigator.pop(context, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Omba ziara' : 'Request tour'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSw ? 'Aina ya ziara' : 'Mode',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(isSw ? 'Papo hapo' : 'In person'),
                      selected: _mode == 'in_person',
                      onSelected: (_) => setState(() => _mode = 'in_person'),
                    ),
                    ChoiceChip(
                      label: Text(isSw ? 'Mtandaoni' : 'Virtual'),
                      selected: _mode == 'virtual',
                      onSelected: (_) => setState(() => _mode = 'virtual'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isSw ? 'Tarehe' : 'When',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_rounded),
                  title: Text(
                      '${_slot.day}/${_slot.month}/${_slot.year}  ${_slot.hour.toString().padLeft(2, '0')}:${_slot.minute.toString().padLeft(2, '0')}'),
                  trailing: TextButton(
                    onPressed: _pickSlot,
                    child: Text(isSw ? 'Badilisha' : 'Change'),
                  ),
                ),
              ],
            ),
          ),
          if (widget.routeListingIds != null && widget.routeListingIds!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isSw
                    ? 'Tutapanga njia kuona mali ${widget.routeListingIds!.length} kwa siku moja.'
                    : 'We\'ll route through ${widget.routeListingIds!.length} listings in one trip.',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF1976D2)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting
                  ? (isSw ? 'Inatuma…' : 'Sending…')
                  : (isSw ? 'Tuma ombi' : 'Send request')),
            ),
          ),
        ],
      ),
    );
  }
}
