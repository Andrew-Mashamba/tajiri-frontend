// lib/my_family/pages/emergency_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/my_family_models.dart';
import '../services/my_family_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmergencyPage extends StatefulWidget {
  final int userId;
  final List<FamilyMember> members;

  const EmergencyPage({
    super.key,
    required this.userId,
    required this.members,
  });

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final MyFamilyService _service = MyFamilyService();

  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final result = await _service.getEmergencyContacts(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _contacts = result.items;
      });
    }
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa Mawasiliano'),
        content:
            Text('Una uhakika unataka kufuta "${contact.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hapana',
                style: TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ndio, Futa',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _service.deleteEmergencyContact(contact.id);
      if (result.success && mounted) _loadContacts();
    }
  }

  void _showAddContactSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    bool isPrimary = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: _kCardBg,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ongeza Mawasiliano ya Dharura',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(
                          fontSize: 14, color: _kPrimary),
                      decoration: InputDecoration(
                        labelText: 'Jina',
                        labelStyle: const TextStyle(
                            fontSize: 13, color: _kSecondary),
                        prefixIcon: const Icon(Icons.person_rounded,
                            size: 20, color: _kSecondary),
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                          fontSize: 14, color: _kPrimary),
                      decoration: InputDecoration(
                        labelText: 'Namba ya Simu',
                        labelStyle: const TextStyle(
                            fontSize: 13, color: _kSecondary),
                        prefixIcon: const Icon(Icons.phone_rounded,
                            size: 20, color: _kSecondary),
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Relationship
                    TextField(
                      controller: relationCtrl,
                      style: const TextStyle(
                          fontSize: 14, color: _kPrimary),
                      decoration: InputDecoration(
                        labelText:
                            'Uhusiano (mfano: Daktari, Jirani)',
                        labelStyle: const TextStyle(
                            fontSize: 13, color: _kSecondary),
                        prefixIcon: const Icon(
                            Icons.people_rounded,
                            size: 20,
                            color: _kSecondary),
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Primary toggle
                    Row(
                      children: [
                        Switch(
                          value: isPrimary,
                          onChanged: (v) =>
                              setSheetState(() => isPrimary = v),
                          activeTrackColor: _kPrimary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Mawasiliano Kuu ya Dharura',
                          style: TextStyle(
                              fontSize: 13, color: _kPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Save
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty ||
                              phoneCtrl.text.trim().isEmpty) {
                            return;
                          }
                          final result =
                              await _service.addEmergencyContact(
                            userId: widget.userId,
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            relationship:
                                relationCtrl.text.trim().isNotEmpty
                                    ? relationCtrl.text.trim()
                                    : null,
                            isPrimary: isPrimary,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (result.success && mounted) {
                            _loadContacts();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hifadhi',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Dharura',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadContacts,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ─── Emergency Services ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emergency_rounded,
                                size: 22, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Huduma za Dharura - Tanzania',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _EmergencyServiceRow(
                          icon: Icons.local_hospital_rounded,
                          label: 'Dharura / Ambulensi',
                          number: '112',
                          onCall: () => _callNumber('112'),
                        ),
                        const SizedBox(height: 8),
                        _EmergencyServiceRow(
                          icon: Icons.local_police_rounded,
                          label: 'Polisi',
                          number: '112',
                          onCall: () => _callNumber('112'),
                        ),
                        const SizedBox(height: 8),
                        _EmergencyServiceRow(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Zima Moto',
                          number: '114',
                          onCall: () => _callNumber('114'),
                        ),
                        const SizedBox(height: 8),
                        _EmergencyServiceRow(
                          icon: Icons.health_and_safety_rounded,
                          label: 'NHIF Msaada',
                          number: '0800 110 300',
                          onCall: () => _callNumber('0800110300'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Emergency Contacts ─────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mawasiliano ya Dharura',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAddContactSheet,
                        child: const Icon(Icons.add_rounded,
                            size: 22, color: _kPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_contacts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Bado hauna mawasiliano ya dharura.\nOngeza ili kuwa salama.',
                          style: TextStyle(
                              fontSize: 13, color: _kSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._contacts.map((contact) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _EmergencyContactCard(
                            contact: contact,
                            onCall: () => _callNumber(contact.phone),
                            onDelete: () => _deleteContact(contact),
                          ),
                        )),
                  const SizedBox(height: 20),

                  // ─── Family Medical Quick View ──────────────
                  const Text(
                    'Taarifa za Mharaka za Afya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Taarifa muhimu za kimatibabu kwa kila mwanafamilia',
                    style: TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                  const SizedBox(height: 10),
                  if (widget.members.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Ongeza wanafamilia kwanza',
                          style: TextStyle(
                              fontSize: 13, color: _kSecondary),
                        ),
                      ),
                    )
                  else
                    ...widget.members
                        .map((m) => _MedicalInfoCard(member: m)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _EmergencyServiceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String number;
  final VoidCallback onCall;

  const _EmergencyServiceRow({
    required this.icon,
    required this.label,
    required this.number,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.red.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.red.shade800,
            ),
          ),
        ),
        GestureDetector(
          onTap: onCall,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.call_rounded,
                    size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onDelete;

  const _EmergencyContactCard({
    required this.contact,
    required this.onCall,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: contact.isPrimary
                    ? Colors.red.withValues(alpha: 0.1)
                    : _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                contact.isPrimary
                    ? Icons.star_rounded
                    : Icons.person_rounded,
                size: 22,
                color: contact.isPrimary ? Colors.red : _kPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact.isPrimary) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color:
                                Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'KUU',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    contact.phone,
                    style: const TextStyle(
                        fontSize: 12, color: _kSecondary),
                  ),
                  if (contact.relationship != null)
                    Text(
                      contact.relationship!,
                      style: const TextStyle(
                          fontSize: 11, color: _kSecondary),
                    ),
                ],
              ),
            ),
            // Call button
            GestureDetector(
              onTap: onCall,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  size: 20,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.delete_outline_rounded,
                  size: 18,
                  color: _kSecondary.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalInfoCard extends StatelessWidget {
  final FamilyMember member;

  const _MedicalInfoCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final hasInfo = member.bloodType != BloodType.unknown ||
        member.allergies.isNotEmpty ||
        member.chronicConditions.isNotEmpty ||
        (member.nhifNumber != null && member.nhifNumber!.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      member.relationship.displayName,
                      style: const TextStyle(
                          fontSize: 11, color: _kSecondary),
                    ),
                  ],
                ),
              ),
              if (member.bloodType != BloodType.unknown)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    member.bloodType.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
            ],
          ),
          if (hasInfo) ...[
            const SizedBox(height: 10),
            if (member.allergies.isNotEmpty)
              _InfoRow(
                icon: Icons.warning_amber_rounded,
                label: 'Mizio',
                value: member.allergies.join(', '),
                color: Colors.orange,
              ),
            if (member.chronicConditions.isNotEmpty)
              _InfoRow(
                icon: Icons.monitor_heart_rounded,
                label: 'Magonjwa',
                value: member.chronicConditions.join(', '),
                color: Colors.red,
              ),
            if (member.nhifNumber != null &&
                member.nhifNumber!.isNotEmpty)
              _InfoRow(
                icon: Icons.badge_rounded,
                label: 'NHIF',
                value: member.nhifNumber!,
                color: _kPrimary,
              ),
            if (member.emergencyPhone != null &&
                member.emergencyPhone!.isNotEmpty)
              _InfoRow(
                icon: Icons.phone_rounded,
                label: 'Simu',
                value: member.emergencyPhone!,
                color: const Color(0xFF4CAF50),
              ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Hakuna taarifa za kimatibabu zilizohifadhiwa',
              style: TextStyle(
                fontSize: 11,
                color: _kSecondary.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
