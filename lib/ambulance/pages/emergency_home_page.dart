// lib/ambulance/pages/emergency_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';
import '../widgets/sos_button.dart';
import 'accident_report_page.dart';
import 'aed_map_page.dart';
import 'ambulance_tracking_page.dart';
import 'emergency_contacts_page.dart';
import 'emergency_history_page.dart';
import 'family_profiles_page.dart';
import 'first_aid_guide_page.dart';
import 'hospital_directory_page.dart';
import 'insurance_page.dart';
import 'medical_profile_page.dart';
import 'medication_reference_page.dart';
import 'preparedness_page.dart';
import 'subscription_plans_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kRed = Color(0xFFCC0000);

class EmergencyHomePage extends StatefulWidget {
  final int userId;
  const EmergencyHomePage({super.key, required this.userId});
  @override
  State<EmergencyHomePage> createState() => _EmergencyHomePageState();
}

class _EmergencyHomePageState extends State<EmergencyHomePage> {
  final AmbulanceService _service = AmbulanceService();
  MedicalProfile? _profile;
  List<Hospital> _nearbyHospitals = [];
  List<EmergencyContact> _contacts = [];
  List<FirstResponder> _nearbyResponders = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingResponders = false;
  late final bool _isSwahili;
  double? _userLat;
  double? _userLng;
  bool _silentMode = false;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _silentMode = LocalStorageService.instanceSync
            ?.getBool('ambulance_silent_mode') ??
        false;
    _acquireLocation();
    _loadData();
  }

  /// FEATURE 2: Acquire real GPS location using Geolocator
  Future<void> _acquireLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium));
      if (!mounted) return;
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    } catch (_) {
      // Fallback to manual address — GPS failed silently
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getMedicalProfile(),
        _service.getHospitals(page: 1),
        _service.getEmergencyContacts(),
      ]);
      if (!mounted) return;
      final profileResult = results[0] as SingleResult<MedicalProfile>;
      final hospitalResult = results[1] as PaginatedResult<Hospital>;
      final contactResult = results[2] as PaginatedResult<EmergencyContact>;
      setState(() {
        _isLoading = false;
        if (profileResult.success) _profile = profileResult.data;
        if (hospitalResult.success) {
          _nearbyHospitals = hospitalResult.items.take(3).toList();
        }
        if (contactResult.success) {
          _contacts = contactResult.items.take(4).toList();
        }
      });
      // Load nearby responders in background (FIX 1c)
      _loadNearbyResponders();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  // FIX 1c: Load nearby responders
  Future<void> _loadNearbyResponders() async {
    setState(() => _isLoadingResponders = true);
    try {
      final result = await _service.getNearbyResponders(
        lat: _userLat ?? -6.7924,
        lng: _userLng ?? 39.2083,
      );
      if (!mounted) return;
      setState(() {
        _isLoadingResponders = false;
        if (result.success) {
          _nearbyResponders = result.items.take(3).toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingResponders = false);
    }
  }

  // FEATURE 2, 7, 10, 41/42/44: SOS with real GPS, silent mode, SMS fallback, insurance pre-auth
  Future<void> _triggerSOS() async {
    if (_isSending) return;

    // FEATURE 10: Silent mode state for the dialog
    bool dialogSilent = _silentMode;

    final addressController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            _isSwahili ? 'Thibitisha Eneo Lako' : 'Confirm Your Location',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userLat != null
                    ? (_isSwahili
                        ? 'GPS imepatikana. Ingiza anwani kama inahitajika.'
                        : 'GPS acquired. Enter address if needed.')
                    : (_isSwahili
                        ? 'GPS haipatikani. Tafadhali ingiza anwani yako.'
                        : 'GPS unavailable. Please enter your address.'),
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: _isSwahili
                      ? 'Anwani (hiari)...'
                      : 'Address (optional)...',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: _kSecondary),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              // FEATURE 10: Silent mode toggle
              Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 32,
                    child: Switch(
                      value: dialogSilent,
                      onChanged: (v) => setDialogState(() => dialogSilent = v),
                      activeTrackColor: _kPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isSwahili ? 'Hali ya Kimya' : 'Silent Mode',
                      style:
                          const TextStyle(fontSize: 13, color: _kPrimary),
                    ),
                  ),
                  Icon(
                    dialogSilent
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 18,
                    color: _kSecondary,
                  ),
                ],
              ),
              Text(
                _isSwahili
                    ? 'SOS itatuma bila sauti/mtetemo'
                    : 'SOS will trigger without sound/vibration',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                _isSwahili ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary),
              ),
            ),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: _kRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _isSwahili ? 'Tuma SOS' : 'Send SOS',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      addressController.dispose();
      return;
    }

    // FEATURE 10: Persist silent mode preference
    _silentMode = dialogSilent;
    LocalStorageService.instanceSync?.saveBool(
        'ambulance_silent_mode', _silentMode);

    final address = addressController.text.trim().isNotEmpty
        ? addressController.text.trim()
        : null;
    addressController.dispose();

    setState(() => _isSending = true);

    // FEATURE 10: Only vibrate if not in silent mode
    if (!_silentMode) {
      HapticFeedback.heavyImpact();
    }

    // FEATURE 2: Use real GPS coordinates, fallback to Dar es Salaam defaults
    final lat = _userLat ?? -6.7924;
    final lng = _userLng ?? 39.2083;

    try {
      // FEATURE 41/42/44: Insurance pre-auth before dispatch
      if (_profile?.insurancePolicyNo != null &&
          _profile!.insurancePolicyNo!.isNotEmpty) {
        try {
          final preAuth = await _service.preAuthorizeInsurance(
            policyNumber: _profile!.insurancePolicyNo!,
            emergencyType: 'ambulance',
          );
          if (!mounted) return;
          if (preAuth.success && preAuth.data != null) {
            final auth = preAuth.data!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(auth.approved
                    ? (_isSwahili
                        ? 'Bima imeidhinishwa: TZS ${auth.coveredAmount?.toStringAsFixed(0) ?? '0'}'
                        : 'Insurance approved: TZS ${auth.coveredAmount?.toStringAsFixed(0) ?? '0'}')
                    : (_isSwahili
                        ? 'Bima haikuidhinishwa: ${auth.message ?? ''}'
                        : 'Insurance not approved: ${auth.message ?? ''}')),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (_) {
          // Insurance pre-auth failure should not block SOS
        }
      }

      final result = await _service.triggerSOS(
        latitude: lat,
        longitude: lng,
        address: address,
      );

      if (!mounted) return;
      setState(() => _isSending = false);
      final messenger = ScaffoldMessenger.of(context);
      if (result.success && result.data != null) {
        if (!_silentMode) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(_isSwahili
                  ? 'Ambulensi imetumwa!'
                  : 'Ambulance dispatched!'),
              backgroundColor: _kRed,
            ),
          );
        }
        // Notify user that emergency contacts were notified
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isSwahili
                  ? 'Mawasiliano ya dharura yamearifu'
                  : 'Emergency contacts notified'),
            ),
          );
        });
        _nav(AmbulanceTrackingPage(emergencyId: result.data!.id));
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili
                      ? 'Imeshindwa. Jaribu tena.'
                      : 'Failed. Try again.')),
              backgroundColor: _kRed),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);

      // FEATURE 7: SMS fallback on network error
      final addressForSms = address ?? '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
      final messenger = ScaffoldMessenger.of(context);
      final useSms = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            _isSwahili
                ? 'Mtandao Umeshindwa'
                : 'Network Failed',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          content: Text(
            _isSwahili
                ? 'Haikuweza kufikia mtandao. Ungependa kutuma SOS kupitia SMS?'
                : 'Could not reach the network. Would you like to send SOS via SMS?',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                _isSwahili ? 'Hapana' : 'No',
                style: const TextStyle(color: _kSecondary),
              ),
            ),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: _kRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _isSwahili ? 'Tuma SMS' : 'Send SMS',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );

      if (useSms == true) {
        try {
          final smsBody = 'EMERGENCY at $addressForSms';
          final smsUri = Uri.parse(
              'sms:114?body=${Uri.encodeComponent(smsBody)}');
          await launchUrl(smsUri);
        } catch (smsError) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(_isSwahili
                  ? 'Imeshindwa kutuma SMS: $smsError'
                  : 'Failed to send SMS: $smsError'),
              backgroundColor: _kRed,
            ),
          );
        }
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: _kRed),
        );
      }
    }
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse('tel:114');
    try {
      await launchUrl(uri);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindwa kupiga simu: $e'
              : 'Could not launch call: $e'),
        ),
      );
    }
  }

  // FIX 1b: Register as Responder dialog
  Future<void> _showRegisterResponderDialog() async {
    final certController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _isSwahili ? 'Jiandikishe kama Msaidizi' : 'Register as Responder',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSwahili
                  ? 'Ingiza vyeti vyako vya msaada wa kwanza'
                  : 'Enter your first aid certifications',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: certController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: _isSwahili
                    ? 'mfano: CPR, BLS, Msaada wa Kwanza...'
                    : 'e.g. CPR, BLS, First Aid...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: _kSecondary),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _isSwahili ? 'Ghairi' : 'Cancel',
              style: const TextStyle(color: _kSecondary),
            ),
          ),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _isSwahili ? 'Jiandikishe' : 'Register',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || certController.text.trim().isEmpty) {
      certController.dispose();
      return;
    }

    final certs = certController.text
        .trim()
        .split(RegExp(r'[,\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    certController.dispose();

    try {
      final result = await _service.registerResponder({
        'certifications': certs,
      });
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(_isSwahili
                ? 'Umejiandikisha kama msaidizi!'
                : 'Registered as responder!'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message ??
                (_isSwahili ? 'Imeshindwa' : 'Registration failed')),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  // FIX 1d: Blood donors dialog
  Future<void> _showBloodDonorsDialog() async {
    const bloodTypes = [
      'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
    ];

    final selectedType = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          _isSwahili ? 'Chagua Kundi la Damu' : 'Select Blood Type',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        children: bloodTypes.map((type) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, type),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(type,
                style: const TextStyle(fontSize: 15, color: _kPrimary)),
          );
        }).toList(),
      ),
    );

    if (selectedType == null || !mounted) return;

    // Show loading bottom sheet then populate with results
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _BloodDonorSheet(
        service: _service,
        bloodType: selectedType,
        isSwahili: _isSwahili,
      ),
    );
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    // NO AppBar - this is a profile tab content page
    return _isLoading
        ? const Center(
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: _kPrimary,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Medical profile summary card
                GestureDetector(
                  onTap: () =>
                      _nav(MedicalProfilePage(userId: widget.userId)),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _kRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _profile?.bloodType ?? '?',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _kRed),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  _isSwahili
                                      ? 'Profaili ya Afya'
                                      : 'Medical Profile',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _kPrimary)),
                              Text(
                                _profile != null
                                    ? (_isSwahili
                                        ? 'Mzio: ${_profile!.allergies.length} | Hali: ${_profile!.conditions.length}'
                                        : 'Allergies: ${_profile!.allergies.length} | Conditions: ${_profile!.conditions.length}')
                                    : (_isSwahili
                                        ? 'Bonyeza kuanzisha profaili yako'
                                        : 'Tap to set up your medical profile'),
                                style: const TextStyle(
                                    fontSize: 12, color: _kSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: _kSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // SOS Button
                Center(
                  child: SOSButton(
                    onPressed: _triggerSOS,
                    isLoading: _isSending,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                      _isSwahili
                          ? 'Bonyeza kwa Dharura'
                          : 'Tap for Emergency',
                      style: const TextStyle(
                          fontSize: 13, color: _kSecondary)),
                ),
                const SizedBox(height: 16),

                // Emergency Call button
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _callEmergency,
                      icon: const Icon(Icons.phone_rounded,
                          size: 20, color: _kRed),
                      label: Text(
                        _isSwahili
                            ? 'Piga Simu ya Dharura'
                            : 'Call Emergency',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kRed),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kRed),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _isSwahili ? 'Nambari ya dharura: 114' : 'Emergency line: 114',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                ),
                const SizedBox(height: 20),

                // Emergency contacts quick list
                if (_contacts.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            _isSwahili
                                ? 'Mawasiliano ya Dharura'
                                : 'Emergency Contacts',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary)),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _nav(const EmergencyContactsPage()),
                        child: Text(
                          _isSwahili ? 'Ona Zote' : 'See All',
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _contacts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final c = _contacts[i];
                        return GestureDetector(
                          onTap: () =>
                              _nav(const EmergencyContactsPage()),
                          child: SizedBox(
                            width: 64,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      const Color(0xFFE8E8E8),
                                  child: Text(
                                      c.name.isNotEmpty
                                          ? c.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: _kPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                ),
                                const SizedBox(height: 4),
                                Text(c.name,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: _kSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(c.relationship,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: _kSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (_profile != null &&
                    _profile!.emergencyContacts.isNotEmpty) ...[
                  Text(
                      _isSwahili
                          ? 'Mawasiliano ya Dharura'
                          : 'Emergency Contacts',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _profile!.emergencyContacts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final c = _profile!.emergencyContacts[i];
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  const Color(0xFFE8E8E8),
                              child: Text(
                                  c.name.isNotEmpty
                                      ? c.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: _kPrimary,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 4),
                            Text(c.name,
                                style: const TextStyle(
                                    fontSize: 11, color: _kSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Quick actions grid (2 rows of 5 — added responder & blood donor)
                _buildQuickActionsGrid(),
                const SizedBox(height: 20),

                // Nearby hospitals preview
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          _isSwahili
                              ? 'Hospitali za Karibu'
                              : 'Nearby Hospitals',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                    ),
                    GestureDetector(
                      onTap: () => _nav(
                          HospitalDirectoryPage(userId: widget.userId)),
                      child: Text(
                        _isSwahili ? 'Ona Zote' : 'See All',
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_nearbyHospitals.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                          _isSwahili
                              ? 'Hakuna hospitali'
                              : 'No hospitals found',
                          style: const TextStyle(
                              color: _kSecondary, fontSize: 13)),
                    ),
                  )
                else
                  ..._nearbyHospitals.map((h) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            onTap: () => _nav(HospitalDirectoryPage(
                                userId: widget.userId)),
                            leading: const Icon(
                                Icons.local_hospital_rounded,
                                color: _kRed),
                            title: Text(h.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _kPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              h.distanceKm != null
                                  ? '${h.distanceKm!.toStringAsFixed(1)} km ${_isSwahili ? 'mbali' : 'away'}'
                                  : h.type ?? '',
                              style: const TextStyle(
                                  fontSize: 12, color: _kSecondary),
                            ),
                            trailing: h.phone != null
                                ? const Icon(Icons.phone_rounded,
                                    color: _kSecondary, size: 20)
                                : null,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                          ),
                        ),
                      )),
                const SizedBox(height: 20),

                // FIX 1c: Nearby Responders section
                _buildNearbyRespondersSection(),
              ],
            ),
          );
  }

  // FIX 1c: Nearby Responders section widget
  Widget _buildNearbyRespondersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSwahili ? 'Wasaidizi wa Karibu' : 'Nearby Responders',
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        const SizedBox(height: 8),
        if (_isLoadingResponders)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary),
            ),
          )
        else if (_nearbyResponders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                _isSwahili
                    ? 'Hakuna wasaidizi wa karibu'
                    : 'No nearby responders found',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
            ),
          )
        else
          ..._nearbyResponders.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE8E8E8),
                      backgroundImage: r.photoUrl != null
                          ? NetworkImage(r.photoUrl!)
                          : null,
                      child: r.photoUrl == null
                          ? Text(
                              r.name.isNotEmpty
                                  ? r.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: _kPrimary,
                                  fontWeight: FontWeight.w600))
                          : null,
                    ),
                    title: Text(r.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      r.distanceKm != null
                          ? '${r.distanceKm!.toStringAsFixed(1)} km ${_isSwahili ? 'mbali' : 'away'}'
                          : (_isSwahili ? 'Karibu' : 'Nearby'),
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                    trailing: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: r.isAvailable
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFBDBDBD),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                  ),
                ),
              )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      (
        Icons.edit_note_rounded,
        _isSwahili ? 'Profaili' : 'Profile',
        () => _nav(MedicalProfilePage(userId: widget.userId)),
      ),
      (
        Icons.local_hospital_rounded,
        _isSwahili ? 'Hospitali' : 'Hospitals',
        () => _nav(HospitalDirectoryPage(userId: widget.userId)),
      ),
      (
        Icons.medical_services_rounded,
        _isSwahili ? 'Msaada' : 'First Aid',
        () => _nav(const FirstAidGuidePage()),
      ),
      (
        Icons.history_rounded,
        _isSwahili ? 'Historia' : 'History',
        () => _nav(const EmergencyHistoryPage()),
      ),
      (
        Icons.shield_rounded,
        _isSwahili ? 'Bima' : 'Insurance',
        () => _nav(const InsurancePage()),
      ),
      (
        Icons.family_restroom_rounded,
        _isSwahili ? 'Familia' : 'Family',
        () => _nav(const FamilyProfilesPage()),
      ),
      (
        Icons.report_rounded,
        _isSwahili ? 'Ripoti' : 'Report',
        () => _nav(const AccidentReportPage()),
      ),
      (
        Icons.card_membership_rounded,
        _isSwahili ? 'Mipango' : 'Plans',
        () => _nav(const SubscriptionPlansPage()),
      ),
      // Register as Responder
      (
        Icons.volunteer_activism_rounded,
        _isSwahili ? 'Msaidizi' : 'Responder',
        _showRegisterResponderDialog,
      ),
      // Blood Donors
      (
        Icons.bloodtype_rounded,
        _isSwahili ? 'Wafadhili Damu' : 'Blood Donors',
        _showBloodDonorsDialog,
      ),
      // FEATURE 38: Medication Reference
      (
        Icons.medication_rounded,
        _isSwahili ? 'Dawa' : 'Medication',
        () => _nav(const MedicationReferencePage()),
      ),
      // FEATURE 52: AED Map
      (
        Icons.monitor_heart_rounded,
        'AED',
        () => _nav(const AedMapPage()),
      ),
      // FEATURE 55: Preparedness Tips
      (
        Icons.checklist_rounded,
        _isSwahili ? 'Maandalizi' : 'Prepare',
        () => _nav(const PreparednessPage()),
      ),
    ];

    final rows = <List<(IconData, String, VoidCallback)>>[];
    for (var i = 0; i < actions.length; i += 4) {
      rows.add(actions.sublist(
          i, i + 4 > actions.length ? actions.length : i + 4));
    }

    return Column(
      children: [
        for (var ri = 0; ri < rows.length; ri++) ...[
          if (ri > 0) const SizedBox(height: 10),
          Row(
            children: [
              ...rows[ri]
                  .map((a) => _ActionTile(
                        icon: a.$1,
                        label: a.$2,
                        onTap: a.$3,
                      ))
                  .expand((w) => [w, const SizedBox(width: 10)])
                  .toList()
                ..removeLast(),
              // Pad incomplete rows with empty expanded widgets
              if (rows[ri].length < 4)
                ...List.generate(
                  4 - rows[ri].length,
                  (_) => const Expanded(child: SizedBox()),
                ).expand((w) => [const SizedBox(width: 10), w]),
            ],
          ),
        ],
      ],
    );
  }
}

// FIX 1d: Blood Donor bottom sheet (stateful for async loading)
class _BloodDonorSheet extends StatefulWidget {
  final AmbulanceService service;
  final String bloodType;
  final bool isSwahili;

  const _BloodDonorSheet({
    required this.service,
    required this.bloodType,
    required this.isSwahili,
  });

  @override
  State<_BloodDonorSheet> createState() => _BloodDonorSheetState();
}

class _BloodDonorSheetState extends State<_BloodDonorSheet> {
  List<FirstResponder> _donors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDonors();
  }

  Future<void> _loadDonors() async {
    try {
      final result = await widget.service.getBloodDonors(widget.bloodType);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _donors = result.items;
        } else {
          _error = result.message ??
              (widget.isSwahili ? 'Imeshindwa kupakia' : 'Failed to load');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isSwahili
                ? 'Wafadhili wa Damu - ${widget.bloodType}'
                : 'Blood Donors - ${widget.bloodType}',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(_error!,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            )
          else if (_donors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  widget.isSwahili
                      ? 'Hakuna wafadhili wa damu wanaopatikana'
                      : 'No blood donors available',
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                ),
              ),
            )
          else
            ...(_donors.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE8E8E8),
                        child: Text(
                            d.name.isNotEmpty
                                ? d.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: _kPrimary,
                                fontWeight: FontWeight.w600)),
                      ),
                      title: Text(d.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (d.phone != null)
                            Text(d.phone!,
                                style: const TextStyle(
                                    fontSize: 12, color: _kSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          if (d.distanceKm != null)
                            Text(
                              '${d.distanceKm!.toStringAsFixed(1)} km ${widget.isSwahili ? 'mbali' : 'away'}',
                              style: const TextStyle(
                                  fontSize: 12, color: _kSecondary),
                            ),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                    ),
                  ),
                ))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, size: 24, color: _kPrimary),
                const SizedBox(height: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
