import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../services/local_storage_service.dart';
import 'client_profile_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ClientsPage extends StatefulWidget {
  final int businessId;
  const ClientsPage({super.key, required this.businessId});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  String? _token;
  int? _userId;
  bool _loading = true;
  String? _error;
  String? _syncNotice;
  final _searchCtrl = TextEditingController();
  final NumberFormat _nf = NumberFormat('#,###', 'en');
  List<Customer> _customers = [];
  List<Customer> _filtered = [];
  String _filter = 'all';
  final Set<String> _activeTagFilters = {};
  final Map<int, Set<String>> _clientTags = {};
  final Set<String> _customTags = {};
  final List<_TodayReminderItem> _todayReminders = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _userId = storage.getUser()?.userId;
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _syncNotice = null;
    });
    try {
      await _syncClientsFromShopOrders();
      final res = await BusinessService.getCustomers(_token!, widget.businessId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (res.success) {
          _customers = res.data;
          for (final c in _customers) {
            final tags = _extractTags(c.notes);
            if (c.id != null) _clientTags[c.id!] = tags.toSet();
            _customTags.addAll(tags.where((e) => !_presetTags.contains(e)));
          }
          _applyFilter();
          _loadTodayReminders();
        } else {
          _error = res.message ?? 'Failed to load customers';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Connection error. Pull to retry.';
      });
    }
  }

  Future<void> _syncClientsFromShopOrders() async {
    if (_token == null || _userId == null) return;
    try {
      final res = await BusinessService.syncClientsFromShop(
        _token!,
        widget.businessId,
        userId: _userId!,
      );
      if (!res.success) {
        final msg = res.message ?? 'Shop sync failed';
        if (msg.contains('SYNC_DISABLED')) {
          _syncNotice = 'Shop sync is disabled on backend.';
        } else if (msg.contains('FORBIDDEN_OWNER_MISMATCH')) {
          _syncNotice = 'Shop sync blocked: user ownership mismatch.';
        } else {
          _syncNotice = msg;
        }
      }
    } catch (_) {
      // Best-effort sync. Clients screen still loads from current CRM source.
    }
  }

  void _loadTodayReminders() {
    _todayReminders.clear();
    final storage = LocalStorageService.instanceSync;
    if (storage == null) return;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    for (final c in _customers) {
      if (c.id == null) continue;
      final raw = storage.getString('clients_reminders_${widget.businessId}_${c.id!}');
      if (raw == null || raw.isEmpty) continue;
      for (final line in raw.split('\n')) {
        final parts = line.split('||');
        if (parts.length < 2) continue;
        final when = DateTime.tryParse(parts[1]);
        if (when == null) continue;
        if (when.isAfter(start) && when.isBefore(end)) {
          _todayReminders.add(_TodayReminderItem(
            customerId: c.id!,
            customerName: c.name,
            text: parts[0],
            when: when,
          ));
        }
      }
    }
    _todayReminders.sort((a, b) => a.when.compareTo(b.when));
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    _filtered = _customers.where((c) {
      final tagSet = c.id == null ? <String>{} : (_clientTags[c.id!] ?? <String>{});
      final matchQuery = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          (c.phone ?? '').toLowerCase().contains(q) ||
          (c.email ?? '').toLowerCase().contains(q);
      if (!matchQuery) return false;
      if (_filter == 'debt' && c.totalDebt <= 0) return false;
      if (_filter == 'inactive' && !_isInactive(c)) return false;
      if (_activeTagFilters.isNotEmpty && tagSet.intersection(_activeTagFilters).isEmpty) return false;
      return true;
    }).toList();
  }

  bool _isInactive(Customer c) {
    final days = _daysSince(c.createdAt);
    return days != null && days > 30;
  }

  int? _daysSince(DateTime? d) => d == null ? null : DateTime.now().difference(d).inDays;

  String _activityText(Customer c) {
    final d = _daysSince(c.createdAt);
    if (d == null) return 'Last purchase -';
    if (d <= 30) return 'Last purchase $d day${d == 1 ? '' : 's'} ago';
    return 'Inactive $d days';
  }

  Future<void> _showAddEditSheet({Customer? customer}) async {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    final notesCtrl = TextEditingController(text: customer?.notes ?? '');
    final tagsCtrl = TextEditingController(text: _extractTags(customer?.notes).join(', '));
    final dobCtrl = TextEditingController(text: _extractMeta(customer?.notes, 'dob') ?? '');
    final sinceCtrl = TextEditingController(text: _extractMeta(customer?.notes, 'client_since') ?? '');
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer == null ? 'New Customer' : 'Edit Customer',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _field(nameCtrl, 'Full Name'),
                _field(phoneCtrl, 'Phone', type: TextInputType.phone),
                _field(emailCtrl, 'Email', type: TextInputType.emailAddress),
                _field(addressCtrl, 'Address'),
                _field(tagsCtrl, 'Tags (comma separated)'),
                _field(dobCtrl, 'Date of Birth (YYYY-MM-DD)'),
                _field(sinceCtrl, 'Client Since (YYYY-MM-DD)'),
                _field(notesCtrl, 'Notes', lines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty) return;
                            setLocal(() => saving = true);
                            final tags = tagsCtrl.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            final composedNotes = _composeNotes(
                              rawNotes: notesCtrl.text.trim(),
                              tags: tags,
                              dob: dobCtrl.text.trim(),
                              clientSince: sinceCtrl.text.trim(),
                            );
                            final body = <String, dynamic>{
                              'business_id': widget.businessId,
                              if (_userId != null) 'user_id': _userId,
                              'name': nameCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'address': addressCtrl.text.trim(),
                              'tags': tags,
                              if (dobCtrl.text.trim().isNotEmpty)
                                'date_of_birth': dobCtrl.text.trim(),
                              if (sinceCtrl.text.trim().isNotEmpty)
                                'anniversary_date': sinceCtrl.text.trim(),
                              'notes': composedNotes,
                            };
                            final res = customer == null
                                ? await BusinessService.addCustomer(_token!, body)
                                : await BusinessService.updateCustomer(_token!, customer.id!, body);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res.success ? 'Saved' : (res.message ?? 'Failed'))),
                            );
                            _load();
                          },
                    child: Text(saving ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _composeNotes({
    required String rawNotes,
    required List<String> tags,
    required String dob,
    required String clientSince,
  }) {
    final parts = <String>[];
    if (rawNotes.isNotEmpty) parts.add(rawNotes);
    if (tags.isNotEmpty) parts.add('[tags:${tags.join('|')}]');
    if (dob.isNotEmpty) parts.add('[dob:$dob]');
    if (clientSince.isNotEmpty) parts.add('[client_since:$clientSince]');
    return parts.join('\n');
  }

  List<String> _extractTags(String? notes) {
    if (notes == null) return const [];
    final m = RegExp(r'\[tags:([^\]]+)\]').firstMatch(notes);
    if (m == null) return const [];
    return (m.group(1) ?? '')
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String? _extractMeta(String? notes, String key) {
    if (notes == null) return null;
    final m = RegExp('\\[$key:([^\\]]+)\\]').firstMatch(notes);
    return m?.group(1)?.trim();
  }

  Future<void> _deleteCustomer(Customer c) async {
    if (_token == null || c.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${c.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await BusinessService.deleteCustomer(_token!, c.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.success ? 'Deleted' : 'Failed')));
    if (res.success) _load();
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _wa(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    await launchUrl(Uri.parse('https://wa.me/${phone.replaceAll('+', '')}'));
  }

  Future<void> _importContacts() async {
    if (_token == null) return;
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contacts permission required. Open settings to allow.'),
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
      return;
    }
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    if (!mounted) return;
    final existingPhones = _customers.map((e) => (e.phone ?? '').replaceAll(' ', '')).toSet();
    final selected = <Contact>{};
    final searchCtrl = TextEditingController();
    List<Contact> filtered = List.from(contacts);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Import Contacts', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: searchCtrl,
                  onChanged: (v) {
                    final q = v.trim().toLowerCase();
                    setLocal(() {
                      filtered = q.isEmpty
                          ? List.from(contacts)
                          : contacts.where((c) {
                              final p = c.phones.isEmpty ? '' : c.phones.first.number;
                              return c.displayName.toLowerCase().contains(q) || p.toLowerCase().contains(q);
                            }).toList();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search contact...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      final p = c.phones.isEmpty ? '' : c.phones.first.number.replaceAll(' ', '');
                      final exists = p.isNotEmpty && existingPhones.contains(p);
                      return CheckboxListTile(
                        value: selected.contains(c),
                        onChanged: exists
                            ? null
                            : (v) => setLocal(() => v == true ? selected.add(c) : selected.remove(c)),
                        title: Text(c.displayName),
                        subtitle: Text(p.isEmpty ? 'No phone' : p),
                        secondary: exists ? const Chip(label: Text('Already added')) : null,
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            int ok = 0;
                            int idx = 0;
                            for (final c in selected) {
                              idx++;
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(milliseconds: 500),
                                    content: Text('Importing $idx of ${selected.length}...'),
                                  ),
                                );
                              }
                              final phone = c.phones.isEmpty ? '' : c.phones.first.number;
                              if (phone.isEmpty) continue;
                              final body = {
                                'business_id': widget.businessId,
                                if (_userId != null) 'user_id': _userId,
                                'name': c.displayName.trim().isEmpty ? phone : c.displayName.trim(),
                                'phone': phone.trim(),
                                'email': c.emails.isEmpty ? '' : c.emails.first.address,
                                'tags': const <String>[],
                                'notes': '[source:contacts_import]',
                              };
                              final res = await BusinessService.addCustomer(_token!, body);
                              if (res.success) ok++;
                            }
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ok clients imported')));
                            _load();
                          },
                    child: Text('Import (${selected.length})'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDebt = _customers.fold<double>(0, (s, e) => s + e.totalDebt);
    final withDebt = _customers.where((e) => e.totalDebt > 0).length;
    final tags = [..._presetTags, ..._customTags];
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pillBtn('New Customer', Icons.person_add_rounded, () => _showAddEditSheet()),
                        _pillBtn('Import Contacts', Icons.contacts_rounded, _importContacts, outlined: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(_applyFilter),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: _kCardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(10)),
                child: Text('Total clients: ${_customers.length} · With debt: $withDebt · Total owed: TZS ${_nf.format(totalDebt)}'),
              ),
            ),
            if (_syncNotice != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _syncNotice!,
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('All', _filter == 'all', () => setState(() {
                        _filter = 'all';
                        _applyFilter();
                      })),
                  _chip('With Debt', _filter == 'debt', () => setState(() {
                        _filter = 'debt';
                        _applyFilter();
                      })),
                  _chip('Inactive', _filter == 'inactive', () => setState(() {
                        _filter = 'inactive';
                        _applyFilter();
                      })),
                  ...tags.map((t) => _chip(t, _activeTagFilters.contains(t), () {
                        setState(() {
                          if (_activeTagFilters.contains(t)) {
                            _activeTagFilters.remove(t);
                          } else {
                            _activeTagFilters.add(t);
                          }
                          _applyFilter();
                        });
                      })),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 44, color: _kSecondary),
          const SizedBox(height: 8),
          Text(_error!),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.person_outline_rounded, size: 58, color: _kSecondary),
          const SizedBox(height: 10),
          const Text('No customers yet'),
          const SizedBox(height: 4),
          const Text("Use 'New Customer' to add your first customer", style: TextStyle(color: _kSecondary)),
          const SizedBox(height: 10),
          FilledButton(onPressed: () => _showAddEditSheet(), child: const Text('Add First Client')),
        ]),
      );
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length + (_todayReminders.isNotEmpty ? 1 : 0),
        itemBuilder: (_, i) {
          if (_todayReminders.isNotEmpty && i == 0) {
            return _todayRemindersCard();
          }
          final offset = _todayReminders.isNotEmpty ? 1 : 0;
          final c = _filtered[i - offset];
          final tags = c.id == null ? const <String>{} : (_clientTags[c.id!] ?? const <String>{});
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientProfilePage(
                    businessId: widget.businessId,
                    token: _token!,
                    customer: c,
                    initialTags: tags.toList(),
                  ),
                ),
              );
              _load();
            },
            onLongPress: () => _deleteCustomer(c),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _kPrimary.withValues(alpha: 0.1),
                    child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase(), style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if ((c.phone ?? '').isNotEmpty)
                          Text(c.phone!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                        const SizedBox(height: 4),
                        Text('Sales: TZS ${_nf.format(c.totalPurchases)}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                        const SizedBox(height: 2),
                        Text(_activityText(c), style: const TextStyle(fontSize: 11, color: _kSecondary)),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: tags.take(3).map((e) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(e, style: const TextStyle(fontSize: 10)),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (c.totalDebt > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                          child: Text('Owes TZS ${_nf.format(c.totalDebt)}', style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((c.phone ?? '').isNotEmpty)
                            IconButton(visualDensity: VisualDensity.compact, onPressed: () => _call(c.phone), icon: const Icon(Icons.call_rounded, size: 18)),
                          if ((c.phone ?? '').isNotEmpty)
                            IconButton(visualDensity: VisualDensity.compact, onPressed: () => _wa(c.phone), icon: const Icon(Icons.chat_rounded, size: 18)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _todayRemindersCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ..._todayReminders.take(4).map((r) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(r.customerName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(r.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(DateFormat('HH:mm').format(r.when)),
              )),
        ],
      ),
    );
  }

  Widget _pillBtn(String label, IconData icon, VoidCallback onTap, {bool outlined = false}) {
    return SizedBox(
      height: 34,
      child: outlined
          ? OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 14), label: Text(label))
          : FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              onPressed: onTap,
              icon: Icon(icon, size: 14),
              label: Text(label),
            ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {TextInputType type = TextInputType.text, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        minLines: lines,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _kBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

const List<String> _presetTags = ['VIP', 'Wholesale', 'Retail', 'Inactive'];

class _TodayReminderItem {
  final int customerId;
  final String customerName;
  final String text;
  final DateTime when;
  _TodayReminderItem({
    required this.customerId,
    required this.customerName,
    required this.text,
    required this.when,
  });
}

