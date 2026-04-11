// lib/business/pages/customers_page.dart
// Customer database with search, add/edit, delete, and history.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class CustomersPage extends StatefulWidget {
  final int businessId;
  const CustomersPage({super.key, required this.businessId});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String? _token;
  bool _loading = true;
  String? _error;
  List<Customer> _customers = [];
  List<Customer> _filtered = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await BusinessService.getCustomers(_token!, widget.businessId);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _customers = res.data;
            _applyFilter();
          } else {
            _error = res.message ?? 'Failed to load customers';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Connection error. Pull to retry.';
        });
      }
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_customers);
    } else {
      _filtered = _customers
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              (c.phone ?? '').contains(q) ||
              (c.email ?? '').toLowerCase().contains(q))
          .toList();
    }
  }

  void _showAddEditDialog({Customer? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    final notesCtrl = TextEditingController(text: customer?.notes ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                customer == null ? 'Add Customer' : 'Edit Customer',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary),
              ),
              const SizedBox(height: 16),
              _inputField(nameCtrl, 'Full Name', Icons.person_rounded),
              const SizedBox(height: 10),
              _inputField(phoneCtrl, 'Phone Number', Icons.phone_rounded,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _inputField(emailCtrl, 'Email', Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _inputField(
                  addressCtrl, 'Address', Icons.location_on_rounded),
              const SizedBox(height: 10),
              _inputField(notesCtrl, 'Notes', Icons.note_rounded,
                  maxLines: 2),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Customer name is required')));
                            return;
                          }
                          setLocal(() => saving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final body = {
                            'business_id': widget.businessId,
                            'name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'address': addressCtrl.text.trim(),
                            'notes': notesCtrl.text.trim(),
                          };
                          try {
                            final res = customer == null
                                ? await BusinessService.addCustomer(
                                    _token!, body)
                                : await BusinessService.updateCustomer(
                                    _token!, customer.id!, body);
                            if (ctx.mounted) Navigator.pop(ctx);
                            messenger.showSnackBar(SnackBar(
                                content: Text(res.success
                                    ? (customer == null
                                        ? 'Customer added'
                                        : 'Customer updated')
                                    : res.message ?? 'Failed')));
                          } catch (e) {
                            messenger.showSnackBar(const SnackBar(
                                content: Text('Connection error')));
                          }
                          _load();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(customer == null ? 'Add' : 'Save',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCustomer(Customer c) async {
    if (_token == null || c.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text(
            'Are you sure you want to delete ${c.name}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await BusinessService.deleteCustomer(_token!, c.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.success ? 'Customer deleted' : 'Failed to delete')));
      if (res.success) _load();
    }
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: _kSecondary),
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _showCustomerDetail(Customer c) {
    final nf = NumberFormat('#,###', 'en');
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _kPrimary.withValues(alpha: 0.08),
                    child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: _kPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (c.phone != null)
                          Text(c.phone!,
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                      ],
                    ),
                  ),
                  // Delete button
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteCustomer(c);
                    },
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.red.shade700),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(
                  'Total Purchases', 'TZS ${nf.format(c.totalPurchases)}'),
              _detailRow('Total Debt', 'TZS ${nf.format(c.totalDebt)}',
                  valueColor: c.totalDebt > 0
                      ? Colors.red.shade700
                      : Colors.green.shade700),
              if (c.email != null && c.email!.isNotEmpty)
                _detailRow('Email', c.email!),
              if (c.address != null && c.address!.isNotEmpty)
                _detailRow('Address', c.address!),
              if (c.notes != null && c.notes!.isNotEmpty)
                _detailRow('Notes', c.notes!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddEditDialog(customer: c);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (c.phone != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          launchUrl(Uri.parse('tel:${c.phone}'));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Icon(Icons.call_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          final phone = c.phone!.replaceAll('+', '');
                          launchUrl(
                              Uri.parse('https://wa.me/$phone'));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Icon(Icons.chat_rounded, size: 18),
                      ),
                    ),
                  ],
                ],
              ),
              if (c.phone != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/search',
                          arguments: {'query': c.phone});
                    },
                    icon:
                        const Icon(Icons.person_search_rounded, size: 18),
                    label: const Text('Find on TAJIRI'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kSecondary,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Flexible(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: _kPrimary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(_applyFilter),
              decoration: InputDecoration(
                hintText: 'Search customer...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _kSecondary),
                filled: true,
                fillColor: _kCardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14)),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded,
                                  size: 18),
                              label: const Text('Retry'),
                              style: TextButton.styleFrom(
                                  foregroundColor: _kPrimary),
                            ),
                          ],
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('No customers yet',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                    'Tap + to add your first customer',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: _kPrimary,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final c = _filtered[i];
                                return GestureDetector(
                                  onTap: () => _showCustomerDetail(c),
                                  onLongPress: () => _deleteCustomer(c),
                                  child: Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _kCardBg,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade100),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              _kPrimary.withValues(
                                                  alpha: 0.08),
                                          child: Text(
                                            c.name.isNotEmpty
                                                ? c.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                color: _kPrimary,
                                                fontWeight:
                                                    FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(c.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _kPrimary,
                                                      fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis),
                                              if (c.phone != null)
                                                Text(c.phone!,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            _kSecondary)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (c.totalDebt > 0)
                                              Text(
                                                'Debt: TZS ${nf.format(c.totalDebt)}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Colors
                                                        .red.shade700),
                                              ),
                                            Text(
                                              'Sales: TZS ${nf.format(c.totalPurchases)}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: _kSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
