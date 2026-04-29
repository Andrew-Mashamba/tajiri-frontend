import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/class_session.dart';
import '../services/class_session_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF1B5E20);

/// Spec line 638 — capacity-bounded class booking with waitlist. Customer
/// view: list of upcoming class sessions for a partner with one-tap book.
class ClassSessionsPage extends StatefulWidget {
  final int partnerId;
  final int customerUserId;
  final String? partnerName;
  final bool partnerView; // true = manage (add/cancel); false = customer book.
  const ClassSessionsPage({
    super.key,
    required this.partnerId,
    required this.customerUserId,
    this.partnerName,
    this.partnerView = false,
  });

  @override
  State<ClassSessionsPage> createState() => _ClassSessionsPageState();
}

class _ClassSessionsPageState extends State<ClassSessionsPage> {
  bool _loading = true;
  List<FitnessClassSession> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ClassSessionService.listForPartner(
      partnerId: widget.partnerId,
      from: DateTime.now(),
      to: DateTime.now().add(const Duration(days: 14)),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res;
    });
  }

  Future<void> _book(FitnessClassSession s) async {
    final messenger = ScaffoldMessenger.of(context);
    final status = await ClassSessionService.book(
      sessionId: s.id,
      customerUserId: widget.customerUserId,
    );
    if (!mounted) return;
    if (status == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Imeshindikana' : 'Failed'),
      ));
      return;
    }
    final isWaitlist = status == 'waitlist';
    messenger.showSnackBar(SnackBar(
      content: Text(
        isWaitlist
            ? (_isSwahili
                ? 'Umeingia kwenye orodha ya kusubiri'
                : 'You\'re on the waitlist')
            : (_isSwahili ? 'Umejiunga' : 'Booked'),
      ),
    ));
    _load();
  }

  Future<void> _addSession() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _AddClassDialog(
        partnerId: widget.partnerId,
        isSwahili: _isSwahili,
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.partnerView
              ? (isSw ? 'Madarasa' : 'Classes')
              : (isSw ? 'Madarasa ya ${widget.partnerName ?? "Mshirika"}' : 'Classes — ${widget.partnerName ?? "Partner"}'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center_rounded,
                            size: 56, color: _kSecondary),
                        const SizedBox(height: 12),
                        Text(
                          isSw
                              ? 'Hakuna madarasa wiki hii'
                              : 'No upcoming classes',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _row(_items[i]),
                  ),
                ),
      floatingActionButton: widget.partnerView
          ? FloatingActionButton.extended(
              onPressed: _addSession,
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(isSw ? 'Darasa Jipya' : 'New class'),
            )
          : null,
    );
  }

  Widget _row(FitnessClassSession s) {
    final isSw = _isSwahili;
    final fmt = DateFormat('EEE d MMM • HH:mm');
    final spotsLeft = s.spotsLeft;
    final isFull = s.isFull;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'TZS ${NumberFormat('#,##0').format(s.priceTzs)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _kAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${fmt.format(s.startsAt.toLocal())} • ${s.durationMinutes} ${isSw ? 'daka' : 'min'}',
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isFull ? Icons.event_busy_rounded : Icons.event_seat_rounded,
                size: 14,
                color: isFull ? const Color(0xFFB71C1C) : _kAccent,
              ),
              const SizedBox(width: 4),
              Text(
                isFull
                    ? (isSw
                        ? 'Imejaa · waitlist'
                        : 'Full · waitlist')
                    : (isSw
                        ? 'Nafasi $spotsLeft/${s.capacity}'
                        : '$spotsLeft/${s.capacity} spots'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isFull ? const Color(0xFFB71C1C) : _kAccent,
                ),
              ),
              const Spacer(),
              if (s.isDropin)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSw ? 'Drop-in' : 'Drop-in',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),
            ],
          ),
          if (!widget.partnerView) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _book(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFull ? _kSecondary : _kPrimary,
                  foregroundColor: Colors.white,
                ),
                child: Text(isFull
                    ? (isSw ? 'Jiunge na waitlist' : 'Join waitlist')
                    : (isSw ? 'Hifadhi nafasi' : 'Book')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddClassDialog extends StatefulWidget {
  final int partnerId;
  final bool isSwahili;
  const _AddClassDialog({required this.partnerId, required this.isSwahili});
  @override
  State<_AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<_AddClassDialog> {
  final _title = TextEditingController();
  final _capacity = TextEditingController(text: '12');
  final _waitlist = TextEditingController(text: '4');
  final _price = TextEditingController(text: '15000');
  DateTime _start = DateTime.now().add(const Duration(days: 1, hours: 9));
  int _duration = 60;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _capacity.dispose();
    _waitlist.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null) return;
    setState(() {
      _start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    final cap = int.tryParse(_capacity.text.trim());
    final price = int.tryParse(_price.text.trim());
    if (cap == null || price == null) return;
    setState(() => _saving = true);
    final created = await ClassSessionService.create(
      partnerId: widget.partnerId,
      title: _title.text.trim(),
      startsAt: _start,
      durationMinutes: _duration,
      capacity: cap,
      waitlistCapacity: int.tryParse(_waitlist.text.trim()) ?? 0,
      priceTzs: price,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (created != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isSwahili ? 'Imeshindikana' : 'Failed'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.isSwahili;
    return AlertDialog(
      title: Text(sw ? 'Darasa Jipya' : 'New Class'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: sw ? 'Jina (mfano: HIIT 6am)' : 'Title (e.g. HIIT 6am)',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _pickStart,
              icon: const Icon(Icons.event_rounded, size: 14),
              label: Text(DateFormat('EEE d MMM • HH:mm').format(_start)),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44)),
            ),
            const SizedBox(height: 6),
            Text(sw ? 'Muda (daka)' : 'Duration (min)',
                style: const TextStyle(fontSize: 11, color: _kSecondary)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [30, 45, 60, 75, 90].map((d) {
                final selected = _duration == d;
                return ChoiceChip(
                  label: Text('$d'),
                  selected: selected,
                  onSelected: (_) => setState(() => _duration = d),
                  selectedColor: _kPrimary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : _kPrimary,
                    fontSize: 11,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: sw ? 'Idadi' : 'Capacity',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _waitlist,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: sw ? 'Waitlist' : 'Waitlist',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'TZS',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(sw ? 'Funga' : 'Close')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary, foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(sw ? 'Hifadhi' : 'Save'),
        ),
      ],
    );
  }
}
