// lib/my_pregnancy/pages/birth_plan_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/my_pregnancy_models.dart';
import '../services/my_pregnancy_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BirthPlanPage extends StatefulWidget {
  final Pregnancy pregnancy;

  const BirthPlanPage({super.key, required this.pregnancy});

  @override
  State<BirthPlanPage> createState() => _BirthPlanPageState();
}

class _BirthPlanPageState extends State<BirthPlanPage> {
  final MyPregnancyService _service = MyPregnancyService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocatingFacility = false;

  String? get _token =>
      LocalStorageService.instanceSync?.getAuthToken();

  // Delivery preferences
  String _deliveryType = 'natural'; // natural | caesarean
  Set<String> _painRelief = {};
  final TextEditingController _presentController = TextEditingController();
  final TextEditingController _specialRequestsController =
      TextEditingController();

  // Facility
  final TextEditingController _facilityNameController = TextEditingController();
  final TextEditingController _facilityPhoneController =
      TextEditingController();

  // Hospital bag checklist
  final Map<String, bool> _motherItems = {};
  final Map<String, bool> _babyItems = {};

  // Emergency contacts
  List<Map<String, String>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _initChecklists();
    _loadBirthPlan();
  }

  @override
  void dispose() {
    _presentController.dispose();
    _specialRequestsController.dispose();
    _facilityNameController.dispose();
    _facilityPhoneController.dispose();
    super.dispose();
  }

  void _initChecklists() {
    for (final item in _motherChecklistItems) {
      _motherItems[item['key']!] = false;
    }
    for (final item in _babyChecklistItems) {
      _babyItems[item['key']!] = false;
    }
  }

  Future<void> _loadBirthPlan() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getBirthPlan(widget.pregnancy.id, token: _token);
      if (mounted && result.success && result.data != null) {
        final data = result.data!;
        setState(() {
          _deliveryType =
              data['delivery_type'] as String? ?? 'natural';
          final relief = data['pain_relief'];
          if (relief is List) {
            _painRelief = relief.cast<String>().toSet();
          }
          _presentController.text =
              data['who_present'] as String? ?? '';
          _specialRequestsController.text =
              data['special_requests'] as String? ?? '';
          _facilityNameController.text =
              data['facility_name'] as String? ?? '';
          _facilityPhoneController.text =
              data['facility_phone'] as String? ?? '';

          // Restore checklist states
          final motherChecked = data['mother_bag'];
          if (motherChecked is Map) {
            for (final key in motherChecked.keys) {
              if (_motherItems.containsKey(key)) {
                _motherItems[key] = motherChecked[key] == true;
              }
            }
          }
          final babyChecked = data['baby_bag'];
          if (babyChecked is Map) {
            for (final key in babyChecked.keys) {
              if (_babyItems.containsKey(key)) {
                _babyItems[key] = babyChecked[key] == true;
              }
            }
          }

          // Restore emergency contacts
          final contacts = data['emergency_contacts'];
          if (contacts is List) {
            _emergencyContacts = contacts
                .map<Map<String, String>>((c) => {
                      'name': (c['name'] ?? '') as String,
                      'phone': (c['phone'] ?? '') as String,
                    })
                .toList();
          }
        });
      }
    } catch (_) {
      // Ignore load errors — user starts fresh
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'delivery_type': _deliveryType,
        'pain_relief': _painRelief.toList(),
        'who_present': _presentController.text.trim(),
        'special_requests': _specialRequestsController.text.trim(),
        'facility_name': _facilityNameController.text.trim(),
        'facility_phone': _facilityPhoneController.text.trim(),
        'mother_bag': _motherItems,
        'baby_bag': _babyItems,
        'emergency_contacts': _emergencyContacts,
      };

      final result = await _service.saveBirthPlan(
        pregnancyId: widget.pregnancy.id,
        userId: widget.pregnancy.userId,
        data: data,
        token: _token,
      );

      if (mounted) {
        final sw = _isSw;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? (sw ? 'Mpango umehifadhiwa' : 'Plan saved')
                : (result.message ??
                    (sw
                        ? 'Imeshindwa kuhifadhi'
                        : 'Failed to save'))),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  _isSw ? 'Kosa: $e' : 'Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  bool get _isSw =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _openNearbyHospitals() async {
    setState(() => _isLocatingFacility = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLocatingFacility = false);
        _openGenericMaps();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) setState(() => _isLocatingFacility = false);

      final url =
          'https://www.google.com/maps/search/hospital/@${position.latitude},${position.longitude},14z';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _openGenericMaps();
      }
    } catch (_) {
      if (mounted) setState(() => _isLocatingFacility = false);
      _openGenericMaps();
    }
  }

  void _openGenericMaps() async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/hospital+near+me');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Silent fallback
    }
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final sw = AppStringsScope.of(ctx)?.isSwahili ?? false;
        return AlertDialog(
          title: Text(
            sw ? 'Ongeza Mtu wa Dharura' : 'Add Emergency Contact',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: sw ? 'Jina' : 'Name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: sw ? 'Nambari ya Simu' : 'Phone Number',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(sw ? 'Ghairi' : 'Cancel',
                  style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  setState(() {
                    _emergencyContacts
                        .add({'name': name, 'phone': phone});
                  });
                  Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary),
              child: Text(sw ? 'Ongeza' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
  }

  // ─── Static data ─────────────────────────────────────────────

  static const List<Map<String, String>> _motherChecklistItems = [
    {'key': 'id', 'sw': 'Kitambulisho (ID)', 'en': 'ID Document'},
    {'key': 'clinic_card', 'sw': 'Kadi ya kliniki', 'en': 'Clinic Card'},
    {'key': 'clothes', 'sw': 'Nguo za kubadilisha', 'en': 'Change of clothes'},
    {'key': 'towel', 'sw': 'Taulo', 'en': 'Towel'},
    {'key': 'soap', 'sw': 'Sabuni', 'en': 'Soap'},
    {'key': 'slippers', 'sw': 'Viatu vya ndani', 'en': 'Slippers'},
    {'key': 'snacks', 'sw': 'Chakula kidogo', 'en': 'Snacks'},
    {
      'key': 'phone_charger',
      'sw': 'Simu + charger',
      'en': 'Phone + charger'
    },
    {'key': 'money', 'sw': 'Pesa', 'en': 'Money'},
  ];

  static const List<Map<String, String>> _babyChecklistItems = [
    {
      'key': 'baby_clothes',
      'sw': 'Nguo za mtoto (seti 3)',
      'en': 'Baby clothes (3 sets)'
    },
    {'key': 'blanket', 'sw': 'Blanketi', 'en': 'Blanket'},
    {'key': 'diapers', 'sw': 'Nepi', 'en': 'Diapers'},
    {'key': 'cap', 'sw': 'Kofia', 'en': 'Cap'},
    {'key': 'socks', 'sw': 'Soksi', 'en': 'Socks'},
  ];

  @override
  Widget build(BuildContext context) {
    final sw = _isSw;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          sw ? 'Mpango wa Kujifungua' : 'Birth Plan',
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          if (!_isLoading)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kPrimary)),
                  )
                : IconButton(
                    icon: const Icon(Icons.check_rounded),
                    tooltip: sw ? 'Hifadhi' : 'Save',
                    onPressed: _save,
                  ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimary))
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeliveryPreferences(sw),
                    const SizedBox(height: 24),
                    _buildFacilitySection(sw),
                    const SizedBox(height: 24),
                    _buildHospitalBag(sw),
                    const SizedBox(height: 24),
                    _buildEmergencyContacts(sw),
                    const SizedBox(height: 32),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                sw ? 'Hifadhi Mpango' : 'Save Plan',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── Section 1: Delivery Preferences ──────────────────────────

  Widget _buildDeliveryPreferences(bool sw) {
    return _SectionCard(
      title: sw ? 'Aina ya Kujifungua' : 'Delivery Preferences',
      children: [
        // Delivery type
        Text(
          sw ? 'Aina ya kujifungua' : 'Delivery type',
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kSecondary),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'natural',
              label: Text(
                sw ? 'Kawaida' : 'Natural',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              icon: const Icon(Icons.favorite_rounded, size: 18),
            ),
            ButtonSegment(
              value: 'caesarean',
              label: Text(
                sw ? 'Upasuaji' : 'Caesarean',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              icon: const Icon(Icons.local_hospital_rounded, size: 18),
            ),
          ],
          selected: {_deliveryType},
          onSelectionChanged: (v) =>
              setState(() => _deliveryType = v.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: _kPrimary,
            selectedForegroundColor: Colors.white,
            foregroundColor: _kPrimary,
          ),
        ),
        const SizedBox(height: 20),

        // Pain relief
        Text(
          sw ? 'Kupunguza maumivu' : 'Pain relief preference',
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildPainChip('none', sw ? 'Hakuna' : 'None'),
            _buildPainChip('breathing', sw ? 'Kupumua' : 'Breathing'),
            _buildPainChip('epidural', sw ? 'Dawa' : 'Epidural'),
          ],
        ),
        const SizedBox(height: 20),

        // Who's present
        TextField(
          controller: _presentController,
          decoration: InputDecoration(
            labelText: sw ? 'Nani atakuwepo?' : "Who's present?",
            hintText: sw ? 'Mke/Mume, Mama, Dada...' : 'Spouse, Mother, Sister...',
            border: const OutlineInputBorder(),
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 16),

        // Special requests
        TextField(
          controller: _specialRequestsController,
          decoration: InputDecoration(
            labelText: sw ? 'Maombi maalum' : 'Special requests',
            hintText: sw
                ? 'Muziki, mwanga, nk.'
                : 'Music, lighting, etc.',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          minLines: 1,
        ),
      ],
    );
  }

  Widget _buildPainChip(String value, String label) {
    final selected = _painRelief.contains(value);
    return FilterChip(
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      selected: selected,
      selectedColor: _kPrimary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : _kPrimary,
      ),
      onSelected: (sel) {
        setState(() {
          if (sel) {
            _painRelief.add(value);
          } else {
            _painRelief.remove(value);
          }
        });
      },
    );
  }

  // ─── Section 2: Hospital/Facility ─────────────────────────────

  static const _facilityTypes = [
    {'sw': 'Hospitali ya Wilaya', 'en': 'District Hospital'},
    {'sw': 'Kituo cha Afya', 'en': 'Health Center'},
    {'sw': 'Zahanati', 'en': 'Dispensary'},
    {'sw': 'Hospitali Binafsi', 'en': 'Private Hospital'},
  ];

  Widget _buildFacilitySection(bool sw) {
    return _SectionCard(
      title: sw ? 'Hospitali / Kituo' : 'Hospital / Facility',
      children: [
        // Quick select chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _facilityTypes.map((type) {
            final label = sw ? type['sw']! : type['en']!;
            return ActionChip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              avatar: const Icon(Icons.local_hospital_rounded, size: 16),
              onPressed: () {
                _facilityNameController.text = label;
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _facilityNameController,
                decoration: InputDecoration(
                  labelText: sw ? 'Jina la hospitali' : 'Facility name',
                  hintText: sw
                      ? 'Chagua hapo juu au andika jina'
                      : 'Pick above or type a name',
                  prefixIcon: const Icon(Icons.local_hospital_rounded),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isLocatingFacility ? null : _openNearbyHospitals,
                icon: _isLocatingFacility
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kPrimary),
                      )
                    : const Icon(Icons.my_location_rounded, size: 16),
                label: Text(
                  sw ? 'Tafuta' : 'Find',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _facilityPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: sw ? 'Simu ya hospitali' : 'Facility phone',
            prefixIcon: const Icon(Icons.phone_rounded),
            border: const OutlineInputBorder(),
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  // ─── Section 3: Hospital Bag Checklist ────────────────────────

  Widget _buildHospitalBag(bool sw) {
    return _SectionCard(
      title: sw ? 'Mfuko wa Hospitali' : 'Hospital Bag Checklist',
      children: [
        // Mother items
        Text(
          sw ? 'Vitu vya Mama' : 'Mother Items',
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kPrimary),
        ),
        const SizedBox(height: 4),
        ..._motherChecklistItems.map((item) => _buildCheckItem(
              item['key']!,
              sw ? item['sw']! : item['en']!,
              _motherItems,
            )),
        const SizedBox(height: 16),

        // Baby items
        Text(
          sw ? 'Vitu vya Mtoto' : 'Baby Items',
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kPrimary),
        ),
        const SizedBox(height: 4),
        ..._babyChecklistItems.map((item) => _buildCheckItem(
              item['key']!,
              sw ? item['sw']! : item['en']!,
              _babyItems,
            )),

        // Progress indicator
        const SizedBox(height: 12),
        _buildBagProgress(sw),
      ],
    );
  }

  Widget _buildCheckItem(
      String key, String label, Map<String, bool> items) {
    return CheckboxListTile(
      value: items[key] ?? false,
      onChanged: (v) => setState(() => items[key] = v ?? false),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: (items[key] ?? false) ? _kSecondary : _kPrimary,
          decoration:
              (items[key] ?? false) ? TextDecoration.lineThrough : null,
        ),
      ),
      activeColor: _kPrimary,
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBagProgress(bool sw) {
    final total = _motherItems.length + _babyItems.length;
    final checked = _motherItems.values.where((v) => v).length +
        _babyItems.values.where((v) => v).length;
    final pct = total > 0 ? checked / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? '$checked / $total vimekamilika' : '$checked / $total packed',
          style: const TextStyle(fontSize: 13, color: _kSecondary),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFE0E0E0),
            color: _kPrimary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ─── Section 4: Emergency Contacts ────────────────────────────

  Widget _buildEmergencyContacts(bool sw) {
    return _SectionCard(
      title: sw ? 'Watu wa Dharura' : 'Emergency Contacts',
      children: [
        if (_emergencyContacts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              sw
                  ? 'Hakuna watu wa dharura. Ongeza hapa chini.'
                  : 'No emergency contacts. Add below.',
              style: const TextStyle(
                  fontSize: 14, color: _kSecondary),
            ),
          ),
        ..._emergencyContacts.asMap().entries.map((entry) {
          final idx = entry.key;
          final contact = entry.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: _kPrimary,
              radius: 20,
              child:
                  Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
            title: Text(
              contact['name'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: _kPrimary),
            ),
            subtitle: Text(
              contact['phone'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _kSecondary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: _kSecondary),
              tooltip: sw ? 'Ondoa' : 'Remove',
              onPressed: () => _removeContact(idx),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.add_rounded, color: _kPrimary),
            label: Text(
              sw ? 'Ongeza Mtu' : 'Add Contact',
              style: const TextStyle(color: _kPrimary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Section Card Widget ──────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
