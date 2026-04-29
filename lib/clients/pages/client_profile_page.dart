import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../invoices/pages/customer_statement_page.dart';
import '../../invoices/pages/invoice_detail_page.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ClientProfilePage extends StatefulWidget {
  final int businessId;
  final String token;
  final Customer customer;
  final List<String> initialTags;
  const ClientProfilePage({
    super.key,
    required this.businessId,
    required this.token,
    required this.customer,
    this.initialTags = const [],
  });

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage>
    with SingleTickerProviderStateMixin {
  final NumberFormat _nf = NumberFormat('#,###', 'en');
  late Customer _customer;
  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  List<Invoice> _invoices = [];
  List<Debt> _debts = [];
  List<BusinessAppointment> _appointments = [];
  final List<_ClientEvent> _events = [];
  final List<_ClientNote> _notes = [];
  final List<_ClientReminder> _reminders = [];
  late final Set<String> _tags;
  int? _userId;
  int _activityLimit = 30;

  String _friendlyApiMessage(String? message, {String fallback = 'Request failed'}) {
    final msg = (message ?? '').trim();
    if (msg.contains('FORBIDDEN_OWNER_MISMATCH')) {
      return 'This action is blocked: account ownership mismatch.';
    }
    if (msg.contains('UNAUTHENTICATED')) {
      return 'Session expired. Please sign in again.';
    }
    if (msg.contains('VALIDATION_ERROR')) {
      return 'Please check the entered values and try again.';
    }
    return msg.isEmpty ? fallback : msg;
  }

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _tags = {...widget.initialTags};
    _tabs = TabController(length: 5, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      _userId = storage.getUser()?.userId;
      final invoicesRes = await BusinessService.getInvoices(widget.token, widget.businessId);
      final debtsRes = await BusinessService.getDebts(widget.token, widget.businessId);
      final apptRes = await BusinessService.getAppointments(widget.token, widget.businessId);
      _invoices = invoicesRes.success
          ? invoicesRes.data.where((e) => _matchCustomer(e.customerId, e.customerName)).toList()
          : [];
      _debts = debtsRes.success
          ? debtsRes.data.where((e) => _matchCustomer(e.customerId, e.customerName)).toList()
          : [];
      _appointments = apptRes.success
          ? apptRes.data.where((e) => _matchCustomer(e.customerId, e.customerName)).toList()
          : [];
      await _loadNotesAndReminders(storage);
      _buildEvents();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load profile';
        });
      }
    }
  }

  Future<void> _loadNotesAndReminders(LocalStorageService storage) async {
    final cid = _customer.id;
    if (cid == null) return;
    final notesRes =
        await BusinessService.getClientNotes(widget.token, cid, userId: _userId);
    final remindersRes = await BusinessService.getClientReminders(
      widget.token,
      cid,
      userId: _userId,
    );
    if (notesRes.success || remindersRes.success) {
      _notes
        ..clear()
        ..addAll(_mapBackendNotes(notesRes.data));
      _reminders
        ..clear()
        ..addAll(_mapBackendReminders(remindersRes.data));
      return;
    }
    final notesRaw = storage.getString('clients_notes_${widget.businessId}_$cid');
    final remRaw = storage.getString('clients_reminders_${widget.businessId}_$cid');
    _notes
      ..clear()
      ..addAll(_decodeNotes(notesRaw));
    _reminders
      ..clear()
      ..addAll(_decodeReminders(remRaw));
  }

  Future<void> _persistLocalNotesAndReminders() async {
    final cid = _customer.id;
    if (cid == null) return;
    final storage = await LocalStorageService.getInstance();
    await storage.setString(
      'clients_notes_${widget.businessId}_$cid',
      _encodeNotes(_notes),
    );
    await storage.setString(
      'clients_reminders_${widget.businessId}_$cid',
      _encodeReminders(_reminders),
    );
  }

  List<_ClientNote> _mapBackendNotes(List<Map<String, dynamic>> rows) {
    return rows.map((r) {
      final created = DateTime.tryParse('${r['created_at'] ?? r['createdAt'] ?? ''}') ??
          DateTime.now();
      return _ClientNote(
        id: _parseInt(r['id']),
        type: '${r['type'] ?? 'General'}',
        text: '${r['note'] ?? r['text'] ?? ''}'.trim(),
        createdAt: created,
      );
    }).where((e) => e.text.isNotEmpty).toList();
  }

  List<_ClientReminder> _mapBackendReminders(List<Map<String, dynamic>> rows) {
    return rows.map((r) {
      final when = DateTime.tryParse(
            '${r['remind_at'] ?? r['when_at'] ?? r['when'] ?? ''}',
          ) ??
          DateTime.now();
      return _ClientReminder(
        id: _parseInt(r['id']),
        text: '${r['title'] ?? r['message'] ?? r['note'] ?? r['text'] ?? ''}'.trim(),
        when: when,
      );
    }).where((e) => e.text.isNotEmpty).toList();
  }

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  bool _matchCustomer(int? id, String? name) {
    if (_customer.id != null && id != null) return _customer.id == id;
    return (name ?? '').trim().toLowerCase() == _customer.name.trim().toLowerCase();
  }

  void _buildEvents() {
    _events
      ..clear()
      ..addAll(_invoices.map((e) => _ClientEvent(
            type: _ClientEventType.invoice,
            title: 'Invoice #${e.invoiceNumber.trim().isNotEmpty ? e.invoiceNumber : (e.id?.toString() ?? '-')}',
            subtitle: 'Issued',
            amount: e.totalAmount,
            date: e.createdAt,
            refId: e.id,
          )))
      ..addAll(_debts.map((e) => _ClientEvent(
            type: _ClientEventType.debt,
            title: 'Debt recorded',
            subtitle: e.description ?? 'Outstanding',
            amount: e.remainingAmount,
            date: e.createdAt,
          )))
      ..addAll(_appointments.map((e) => _ClientEvent(
            type: _ClientEventType.appointment,
            title: e.serviceName ?? 'Appointment',
            subtitle: appointmentStatusLabel(e.status),
            amount: 0,
            date: e.date ?? e.createdAt,
          )))
      ..addAll(_notes.map((e) => _ClientEvent(
            type: _ClientEventType.note,
            title: e.typeLabel,
            subtitle: e.text,
            amount: 0,
            date: e.createdAt,
          )))
      ..addAll(_reminders.map((e) => _ClientEvent(
            type: _ClientEventType.reminder,
            title: 'Reminder',
            subtitle: e.text,
            amount: 0,
            date: e.when,
          )));
    _events.sort((a, b) => (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)));
  }

  Future<void> _call() async {
    final p = _customer.phone;
    if (p == null || p.isEmpty) return;
    await launchUrl(Uri.parse('tel:$p'));
    _logContact('Called via app');
  }

  Future<void> _whatsApp() async {
    final p = _customer.phone;
    if (p == null || p.isEmpty) return;
    await launchUrl(Uri.parse('https://wa.me/${p.replaceAll('+', '')}'));
    _logContact('WhatsApp opened');
  }

  Future<void> _email() async {
    final e = _customer.email;
    if (e == null || e.isEmpty) return;
    await launchUrl(Uri.parse('mailto:$e?subject=TAJIRI%20Business'));
  }

  void _logContact(String action) {
    _events.insert(
      0,
      _ClientEvent(
        type: _ClientEventType.contact,
        title: action,
        subtitle: _customer.name,
        amount: 0,
        date: DateTime.now(),
      ),
    );
    setState(() {});
  }

  void _addReminder() {
    final noteCtrl = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(days: 1));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteCtrl,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Reminder note'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(DateFormat('dd MMM yyyy • HH:mm').format(when))),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                        initialDate: when,
                      );
                      if (d == null) return;
                      final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(when));
                      if (t == null) return;
                      setLocal(() => when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    },
                    child: const Text('Pick date/time'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (noteCtrl.text.trim().isEmpty) return;
                    final cid = _customer.id;
                    if (cid == null) return;
                    final payload = <String, dynamic>{
                      if (_userId != null) 'user_id': _userId,
                      'title': noteCtrl.text.trim(),
                      'message': noteCtrl.text.trim(),
                      'remind_at': when.toIso8601String(),
                      'status': 'pending',
                    };
                    final res = await BusinessService.addClientReminder(
                      widget.token,
                      cid,
                      payload,
                    );
                    if (!res.success) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _friendlyApiMessage(
                              res.message,
                              fallback: 'Failed to create reminder',
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _reminders.add(
                        _ClientReminder(
                          id: _parseInt(res.data?['id']),
                          text: noteCtrl.text.trim(),
                          when: when,
                        ),
                      );
                      _buildEvents();
                    });
                    _persistLocalNotesAndReminders();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Set Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNote() {
    final noteCtrl = TextEditingController();
    String type = 'General';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: ['Call', 'Order', 'General', 'Alert']
                    .map((e) => ChoiceChip(
                          label: Text(e),
                          selected: type == e,
                          onSelected: (_) => setLocal(() => type = e),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                decoration: const InputDecoration(labelText: 'What happened?'),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (noteCtrl.text.trim().isEmpty) return;
                    final cid = _customer.id;
                    if (cid == null) return;
                    final payload = <String, dynamic>{
                      if (_userId != null) 'user_id': _userId,
                      'type': type,
                      'note': noteCtrl.text.trim(),
                    };
                    final res =
                        await BusinessService.addClientNote(widget.token, cid, payload);
                    if (!res.success) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _friendlyApiMessage(
                              res.message,
                              fallback: 'Failed to save note',
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _notes.insert(
                        0,
                        _ClientNote(
                          id: _parseInt(res.data?['id']),
                          type: type,
                          text: noteCtrl.text.trim(),
                          createdAt: DateTime.now(),
                        ),
                      );
                      _buildEvents();
                    });
                    _persistLocalNotesAndReminders();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Note'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _manageTags() {
    final presets = {'VIP', 'Wholesale', 'Retail', 'Inactive', 'New', 'Credit Risk'};
    final all = {...presets, ..._tags};
    final customCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Manage Tags', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: all
                    .map((e) => FilterChip(
                          label: Text(e),
                          selected: _tags.contains(e),
                          onSelected: (v) => setLocal(() => v ? _tags.add(e) : _tags.remove(e)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: customCtrl, decoration: const InputDecoration(hintText: 'Add tag'))),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final t = customCtrl.text.trim();
                      if (t.isEmpty) return;
                      setLocal(() {
                        all.add(t);
                        _tags.add(t);
                        customCtrl.clear();
                      });
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _saveTagsToCustomer());
  }

  Future<void> _saveTagsToCustomer() async {
    final cid = _customer.id;
    if (cid == null) {
      setState(() {});
      return;
    }
    final body = {
      'business_id': widget.businessId,
      if (_userId != null) 'user_id': _userId,
      'name': _customer.name,
      'phone': _customer.phone ?? '',
      'email': _customer.email ?? '',
      'address': _customer.address ?? '',
      'tags': _tags.toList(),
      if ((_extractMeta(_customer.notes, 'dob') ?? '').isNotEmpty)
        'date_of_birth': _extractMeta(_customer.notes, 'dob'),
      if ((_extractMeta(_customer.notes, 'client_since') ?? '').isNotEmpty)
        'anniversary_date': _extractMeta(_customer.notes, 'client_since'),
      'notes': _mergeMetaNotes(
        baseNotes: _customer.notes ?? '',
        tags: _tags.toList(),
      ),
    };
    final res = await BusinessService.updateCustomer(widget.token, cid, body);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() => _customer = res.data!);
    } else {
      setState(() {});
    }
  }

  String _mergeMetaNotes({required String baseNotes, List<String>? tags}) {
    final cleaned = baseNotes
        .split('\n')
        .where((l) => !l.startsWith('[tags:') && !l.startsWith('[dob:') && !l.startsWith('[client_since:'))
        .join('\n')
        .trim();
    final chunks = <String>[];
    if (cleaned.isNotEmpty) chunks.add(cleaned);
    if (tags != null && tags.isNotEmpty) chunks.add('[tags:${tags.join('|')}]');
    final dob = _extractMeta(_customer.notes, 'dob');
    final since = _extractMeta(_customer.notes, 'client_since');
    if (dob != null && dob.isNotEmpty) chunks.add('[dob:$dob]');
    if (since != null && since.isNotEmpty) chunks.add('[client_since:$since]');
    return chunks.join('\n');
  }

  String? _extractMeta(String? notes, String key) {
    if (notes == null) return null;
    final m = RegExp('\\[$key:([^\\]]+)\\]').firstMatch(notes);
    return m?.group(1)?.trim();
  }

  Future<void> _editCustomer() async {
    final cid = _customer.id;
    if (cid == null) return;
    final nameCtrl = TextEditingController(text: _customer.name);
    final phoneCtrl = TextEditingController(text: _customer.phone ?? '');
    final emailCtrl = TextEditingController(text: _customer.email ?? '');
    final addressCtrl = TextEditingController(text: _customer.address ?? '');
    final notesCtrl = TextEditingController(text: _customer.notes ?? '');
    bool saving = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setLocal(() => saving = true);
                          final body = {
                            'business_id': widget.businessId,
                            if (_userId != null) 'user_id': _userId,
                            'name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'address': addressCtrl.text.trim(),
                            'tags': _tags.toList(),
                            if ((_extractMeta(notesCtrl.text, 'dob') ?? '').isNotEmpty)
                              'date_of_birth': _extractMeta(notesCtrl.text, 'dob'),
                            if ((_extractMeta(notesCtrl.text, 'client_since') ?? '').isNotEmpty)
                              'anniversary_date': _extractMeta(notesCtrl.text, 'client_since'),
                            'notes': notesCtrl.text.trim(),
                          };
                          final res = await BusinessService.updateCustomer(widget.token, cid, body);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (res.success && res.data != null) {
                            setState(() => _customer = res.data!);
                          }
                        },
                  child: const Text('Update'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCustomer() async {
    final cid = _customer.id;
    if (cid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${_customer.name}? All records will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await BusinessService.deleteCustomer(widget.token, cid);
    if (!mounted) return;
    if (res.success) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastInvoice = _invoices.isEmpty ? null : _invoices.first.createdAt;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        title: const Text('Client Profile'),
        actions: [
          IconButton(onPressed: _editCustomer, icon: const Icon(Icons.edit_rounded)),
          IconButton(onPressed: _manageTags, icon: const Icon(Icons.sell_rounded)),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'reminder') _addReminder();
              if (v == 'delete') _deleteCustomer();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reminder', child: Text('Add Reminder')),
              PopupMenuItem(value: 'delete', child: Text('Delete Client')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _error != null
                ? Center(child: Text(_error!))
                : Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: _kPrimary.withValues(alpha: 0.1),
                              child: Text(_customer.name.isEmpty ? '?' : _customer.name[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _kPrimary)),
                            ),
                            const SizedBox(height: 8),
                            Text(_customer.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            if ((_customer.phone ?? '').isNotEmpty) Text(_customer.phone!, style: const TextStyle(color: _kSecondary)),
                            if ((_customer.email ?? '').isNotEmpty) Text(_customer.email!, style: const TextStyle(color: _kSecondary)),
                            if (_tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(spacing: 6, children: _tags.map((e) => Chip(label: Text(e), visualDensity: VisualDensity.compact)).toList()),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _metricCard('Total Purchases', 'TZS ${_nf.format(_customer.totalPurchases)}', Colors.black87),
                                _metricCard('Outstanding Debt', 'TZS ${_nf.format(_customer.totalDebt)}', _customer.totalDebt > 0 ? Colors.red.shade700 : Colors.green.shade700),
                                _metricCard('Last Purchase', lastInvoice == null ? '-' : _relative(lastInvoice), Colors.black87),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TabBar(
                        controller: _tabs,
                        labelColor: _kPrimary,
                        unselectedLabelColor: _kSecondary,
                        isScrollable: true,
                        tabs: const [
                          Tab(text: 'Activity'),
                          Tab(text: 'Invoices'),
                          Tab(text: 'Debts'),
                          Tab(text: 'Appointments'),
                          Tab(text: 'Notes'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _activityTab(),
                            _invoicesTab(),
                            _debtsTab(),
                            _appointmentsTab(),
                            _notesTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: _kCardBg,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Row(
            children: [
              _actionBtn('Call', Icons.call_rounded, _call),
              _actionBtn('WhatsApp', Icons.chat_rounded, _whatsApp),
              _actionBtn('Email', Icons.email_rounded, _email),
              _actionBtn('Statement', Icons.description_rounded, _openStatementRangePicker),
            ],
          ),
        ),
      ),
      floatingActionButton: _tabs.index == 4
          ? FloatingActionButton(
              backgroundColor: _kPrimary,
              onPressed: _addNote,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _metricCard(String title, String value, Color valueColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _kBackground, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: _kSecondary)),
            const SizedBox(height: 4),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(label, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  Widget _activityTab() {
    if (_events.isEmpty) return const Center(child: Text('No activity yet'));
    final visible = _events.take(_activityLimit).toList();
    final grouped = <String, List<_ClientEvent>>{};
    for (final e in visible) {
      final k = _bucket(e.date);
      grouped.putIfAbsent(k, () => []).add(e);
    }
    final rows = <Object>[];
    grouped.forEach((k, list) {
      rows.add(k);
      rows.addAll(list);
    });
    if (_events.length > _activityLimit) rows.add('_LOAD_MORE_');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) {
        final row = rows[i];
        if (row == '_LOAD_MORE_') {
          return Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _activityLimit += 30),
              child: const Text('Load older activity'),
            ),
          );
        }
        if (row is String) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(row, style: const TextStyle(fontWeight: FontWeight.w700, color: _kSecondary)),
          );
        }
        final e = row as _ClientEvent;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: e.color.withValues(alpha: 0.15),
            child: Icon(e.icon, size: 16, color: e.color),
          ),
          title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(e.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(e.date == null ? '-' : DateFormat('dd MMM').format(e.date!), style: const TextStyle(fontSize: 11, color: _kSecondary)),
              if (e.amount > 0)
                Text('TZS ${_nf.format(e.amount)}', style: TextStyle(fontSize: 11, color: e.type == _ClientEventType.debt ? Colors.red.shade700 : Colors.green.shade700)),
            ],
          ),
          onTap: () {
            if (e.type == _ClientEventType.invoice && e.refId != null) {
              final invoice = _invoices.cast<Invoice?>().firstWhere(
                    (inv) => inv?.id == e.refId,
                    orElse: () => null,
                  );
              if (invoice != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailPage(
                      invoice: invoice,
                      businessId: widget.businessId,
                    ),
                  ),
                );
              }
            }
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: rows.length,
    );
  }

  Widget _invoicesTab() {
    if (_invoices.isEmpty) return const Center(child: Text('No invoices'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length,
      itemBuilder: (_, i) {
        final inv = _invoices[i];
        return Card(
          child: ListTile(
            title: Text('#${inv.invoiceNumber.trim().isNotEmpty ? inv.invoiceNumber : (inv.id?.toString() ?? '-')}'),
            subtitle: Text(invoiceStatusLabel(inv.status)),
            trailing: Text('TZS ${_nf.format(inv.totalAmount)}'),
          ),
        );
      },
    );
  }

  Widget _debtsTab() {
    if (_debts.isEmpty) return const Center(child: Text('No debts'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _debts.length,
      itemBuilder: (_, i) {
        final d = _debts[i];
        return Card(
          child: ListTile(
            title: Text(d.description ?? 'Debt'),
            subtitle: Text(debtStatusLabel(d.status)),
            trailing: Text('TZS ${_nf.format(d.remainingAmount)}', style: TextStyle(color: Colors.red.shade700)),
          ),
        );
      },
    );
  }

  Widget _appointmentsTab() {
    if (_appointments.isEmpty) return const Center(child: Text('No appointments'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (_, i) {
        final a = _appointments[i];
        return Card(
          child: ListTile(
            title: Text(a.serviceName ?? 'Appointment'),
            subtitle: Text('${appointmentStatusLabel(a.status)} • ${a.startTime ?? ''}'),
            trailing: Text(a.date == null ? '-' : DateFormat('dd MMM').format(a.date!)),
          ),
        );
      },
    );
  }

  Widget _notesTab() {
    if (_notes.isEmpty) return const Center(child: Text('No notes yet'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (_, i) {
        final n = _notes[i];
        return Card(
          child: ListTile(
            title: Text(n.type),
            subtitle: Text(n.text),
            trailing: Text(DateFormat('dd MMM').format(n.createdAt)),
            onLongPress: () => _editOrDeleteNote(n),
          ),
        );
      },
    );
  }

  Future<void> _editOrDeleteNote(_ClientNote note) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Edit Note'), onTap: () => Navigator.pop(ctx, 'edit')),
            ListTile(title: const Text('Delete Note'), onTap: () => Navigator.pop(ctx, 'delete')),
          ],
        ),
      ),
    );
    if (action == 'delete') {
      if (note.id != null && _userId != null) {
        final res =
            await BusinessService.deleteClientNote(widget.token, note.id!, _userId!);
        if (!res.success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _friendlyApiMessage(res.message, fallback: 'Failed to delete note'),
              ),
            ),
          );
          return;
        }
      }
      setState(() => _notes.remove(note));
      _buildEvents();
      _persistLocalNotesAndReminders();
      return;
    }
    if (action == 'edit') {
      final ctrl = TextEditingController(text: note.text);
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrl, maxLines: 4),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final updatedText = ctrl.text.trim();
                    if (updatedText.isEmpty) return;
                    if (note.id != null) {
                      final res = await BusinessService.updateClientNote(
                        widget.token,
                        note.id!,
                        {
                          if (_userId != null) 'user_id': _userId,
                          'type': note.type,
                          'note': updatedText,
                        },
                      );
                      if (!res.success) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _friendlyApiMessage(
                                res.message,
                                fallback: 'Failed to update note',
                              ),
                            ),
                          ),
                        );
                        return;
                      }
                    }
                    setState(() => note.text = updatedText);
                    _buildEvents();
                    _persistLocalNotesAndReminders();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Update'),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _openStatementRangePicker() async {
    DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime to = DateTime.now();
    final selection = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select statement period', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('This Month'), selected: false, onSelected: (_) {
                      setLocal(() {
                        from = DateTime(DateTime.now().year, DateTime.now().month, 1);
                        to = DateTime.now();
                      });
                    }),
                    ChoiceChip(label: const Text('Last Month'), selected: false, onSelected: (_) {
                      final now = DateTime.now();
                      final firstThis = DateTime(now.year, now.month, 1);
                      setLocal(() {
                        from = DateTime(firstThis.year, firstThis.month - 1, 1);
                        to = firstThis.subtract(const Duration(seconds: 1));
                      });
                    }),
                    ChoiceChip(label: const Text('Last 3 Months'), selected: false, onSelected: (_) {
                      final now = DateTime.now();
                      setLocal(() {
                        from = DateTime(now.year, now.month - 2, 1);
                        to = now;
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text('From: ${DateFormat('dd MMM yyyy').format(from)}')),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: from,
                        );
                        if (d != null) setLocal(() => from = d);
                      },
                      child: const Text('Pick'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text('To: ${DateFormat('dd MMM yyyy').format(to)}')),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: to,
                        );
                        if (d != null) setLocal(() => to = d);
                      },
                      child: const Text('Pick'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selection != true || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerStatementPage(
          businessId: widget.businessId,
          customerId: _customer.id,
          customerName: _customer.name,
          initialFrom: from,
          initialTo: to,
        ),
      ),
    );
  }

  String _bucket(DateTime? d) {
    if (d == null) return 'Older';
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff <= 7) return 'This Week';
    return DateFormat('MMMM yyyy').format(d);
  }

  List<_ClientNote> _decodeNotes(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final out = <_ClientNote>[];
    for (final line in raw.split('\n')) {
      final parts = line.split('||');
      if (parts.length < 3) continue;
      final dt = DateTime.tryParse(parts[2]) ?? DateTime.now();
      out.add(_ClientNote(type: parts[0], text: parts[1], createdAt: dt));
    }
    return out;
  }

  String _encodeNotes(List<_ClientNote> notes) {
    return notes
        .map((n) => '${n.type}||${n.text.replaceAll('\n', ' ')}||${n.createdAt.toIso8601String()}')
        .join('\n');
  }

  List<_ClientReminder> _decodeReminders(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final out = <_ClientReminder>[];
    for (final line in raw.split('\n')) {
      final parts = line.split('||');
      if (parts.length < 2) continue;
      final dt = DateTime.tryParse(parts[1]) ?? DateTime.now();
      out.add(_ClientReminder(text: parts[0], when: dt));
    }
    return out;
  }

  String _encodeReminders(List<_ClientReminder> reminders) {
    return reminders
        .map((r) => '${r.text.replaceAll('\n', ' ')}||${r.when.toIso8601String()}')
        .join('\n');
  }

  String _relative(DateTime? d) {
    if (d == null) return '-';
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }
}

enum _ClientEventType { invoice, debt, appointment, note, reminder, contact }

class _ClientEvent {
  final _ClientEventType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime? date;
  final int? refId;
  _ClientEvent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    this.refId,
  });

  IconData get icon {
    switch (type) {
      case _ClientEventType.invoice:
        return Icons.receipt_long_rounded;
      case _ClientEventType.debt:
        return Icons.warning_amber_rounded;
      case _ClientEventType.appointment:
        return Icons.event_rounded;
      case _ClientEventType.note:
        return Icons.note_alt_rounded;
      case _ClientEventType.reminder:
        return Icons.notifications_active_rounded;
      case _ClientEventType.contact:
        return Icons.call_rounded;
    }
  }

  Color get color {
    switch (type) {
      case _ClientEventType.invoice:
        return Colors.green.shade700;
      case _ClientEventType.debt:
        return Colors.red.shade700;
      case _ClientEventType.appointment:
        return Colors.blueGrey.shade700;
      case _ClientEventType.note:
        return Colors.deepPurple.shade700;
      case _ClientEventType.reminder:
        return Colors.orange.shade700;
      case _ClientEventType.contact:
        return Colors.teal.shade700;
    }
  }
}

class _ClientNote {
  final int? id;
  final String type;
  String text;
  final DateTime createdAt;
  _ClientNote({this.id, required this.type, required this.text, required this.createdAt});
  String get typeLabel => type;
}

class _ClientReminder {
  final int? id;
  final String text;
  final DateTime when;
  _ClientReminder({this.id, required this.text, required this.when});
}

