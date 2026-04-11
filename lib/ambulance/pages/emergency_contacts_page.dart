// lib/ambulance/pages/emergency_contacts_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';
import '../widgets/emergency_contact_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});
  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final AmbulanceService _service = AmbulanceService();
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getEmergencyContacts();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) _contacts = result.items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _addContact() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String relationship = _isSwahili ? 'Ndugu' : 'Family';

    final relationships = _isSwahili
        ? ['Ndugu', 'Mke/Mume', 'Mtoto', 'Mzazi', 'Rafiki', 'Jirani', 'Daktari']
        : ['Family', 'Spouse', 'Child', 'Parent', 'Friend', 'Neighbor', 'Doctor'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(_isSwahili
              ? 'Ongeza Mawasiliano'
              : 'Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: _isSwahili ? 'Jina' : 'Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: _isSwahili ? 'Simu' : 'Phone',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: relationship,
                  decoration: InputDecoration(
                    labelText: _isSwahili ? 'Uhusiano' : 'Relationship',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: relationships
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => relationship = v);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Ghairi' : 'Cancel',
                  style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: Text(_isSwahili ? 'Ongeza' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      return;
    }

    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    nameCtrl.dispose();
    phoneCtrl.dispose();

    if (name.isEmpty || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isSwahili
                ? 'Jina na simu vinahitajika'
                : 'Name and phone are required')),
      );
      return;
    }

    try {
      final result = await _service.addEmergencyContact(
        name: name,
        phone: phone,
        relationship: relationship,
      );
      if (!mounted) return;
      if (result.success) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isSwahili ? 'Imeongezwa' : 'Contact added'),
              backgroundColor: _kPrimary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _removeContact(EmergencyContact contact) async {
    if (contact.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Ondoa Mawasiliano' : 'Remove Contact'),
        content: Text(_isSwahili
            ? 'Una uhakika unataka kuondoa ${contact.name}?'
            : 'Are you sure you want to remove ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSwahili ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCC0000)),
            child: Text(_isSwahili ? 'Ondoa' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _service.removeEmergencyContact(contact.id!);
      if (!mounted) return;
      if (result.success) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isSwahili ? 'Imeondolewa' : 'Contact removed'),
              backgroundColor: _kPrimary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Mawasiliano ya Dharura' : 'Emergency Contacts',
          style:
              const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: _addContact,
              icon: const Icon(Icons.add_rounded, color: _kPrimary),
              tooltip: _isSwahili ? 'Ongeza' : 'Add',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.contacts_rounded,
                          size: 48, color: _kSecondary),
                      const SizedBox(height: 12),
                      Text(
                        _isSwahili
                            ? 'Hakuna mawasiliano ya dharura'
                            : 'No emergency contacts yet',
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addContact,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(
                            _isSwahili ? 'Ongeza Kwanza' : 'Add First Contact'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          minimumSize: const Size(180, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contacts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = _contacts[i];
                      return EmergencyContactCard(
                        contact: c,
                        isSwahili: _isSwahili,
                        onRemove: () => _removeContact(c),
                      );
                    },
                  ),
                ),
      floatingActionButton: _contacts.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addContact,
              backgroundColor: _kPrimary,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}
