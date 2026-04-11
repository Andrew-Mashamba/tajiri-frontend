import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';

class PartnerSettingsPage extends StatefulWidget {
  const PartnerSettingsPage({super.key});

  @override
  State<PartnerSettingsPage> createState() => _PartnerSettingsPageState();
}

class _PartnerSettingsPageState extends State<PartnerSettingsPage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  bool _isLoading = true;
  TajirikaPartner? _partner;

  // Availability schedule
  late List<_AvailabilityRow> _schedule;

  // Notification preferences (local only)
  bool _notifVerification = true;
  bool _notifTierChanges = true;
  bool _notifReferrals = true;
  bool _notifTraining = true;
  bool _notifEarnings = true;

  bool _isSavingAvailability = false;

  @override
  void initState() {
    super.initState();
    _schedule = _defaultSchedule();
    _loadData();
  }

  List<_AvailabilityRow> _defaultSchedule() {
    return List.generate(7, (i) {
      final day = i + 1; // 1=Mon ... 7=Sun
      final isWeekday = day <= 5;
      return _AvailabilityRow(
        dayOfWeek: day,
        isAvailable: isWeekday,
        startTime: '08:00',
        endTime: '17:00',
      );
    });
  }

  int? _userId;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      _userId = storage.getUser()?.userId;
      if (token == null || _userId == null) return;

      final result = await TajirikaService.getMyPartnerProfile(token, _userId!);

      if (!mounted) return;
      if (result.success && result.partner != null) {
        setState(() {
          _partner = result.partner;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          isSwahili ? 'Mipangilio ya Mshirika' : 'Partner Settings',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildServiceAreaSection(isSwahili),
                      const SizedBox(height: 16),
                      _buildAvailabilitySection(isSwahili),
                      const SizedBox(height: 16),
                      _buildPayoutSection(isSwahili),
                      const SizedBox(height: 16),
                      _buildNotificationsSection(isSwahili),
                      const SizedBox(height: 16),
                      _buildAccountActionsSection(isSwahili),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ==================== SERVICE AREA ====================

  Widget _buildServiceAreaSection(bool isSwahili) {
    final area = _partner?.serviceArea;
    final hasArea = area != null && !area.isEmpty;

    return _sectionCard(
      title: isSwahili ? 'Eneo la Huduma' : 'Service Area',
      icon: Icons.location_on_rounded,
      trailing: TextButton(
        onPressed: () => _showServiceAreaDialog(isSwahili),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        child: Text(
          isSwahili ? 'Badilisha' : 'Edit',
          style: const TextStyle(color: _kPrimary, fontSize: 13),
        ),
      ),
      child: hasArea
          ? Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...area.regionNames.map((n) => _locationChip(n, Icons.map_rounded)),
                ...area.districtNames.map((n) => _locationChip(n, Icons.location_city_rounded)),
                ...area.wardNames.map((n) => _locationChip(n, Icons.place_rounded)),
              ],
            )
          : Text(
              isSwahili
                  ? 'Bado hujaweka eneo la huduma'
                  : 'No service area set',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
    );
  }

  Widget _locationChip(String name, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 14, color: _kSecondary),
      label: Text(
        name,
        style: const TextStyle(fontSize: 12, color: _kPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showServiceAreaDialog(bool isSwahili) {
    final regionCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final wardCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            isSwahili ? 'Badilisha Eneo la Huduma' : 'Edit Service Area',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSwahili
                      ? 'Andika majina yaliyotenganishwa na koma'
                      : 'Enter names separated by commas',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: regionCtrl,
                  decoration: InputDecoration(
                    labelText: isSwahili ? 'Mikoa' : 'Regions',
                    labelStyle: const TextStyle(fontSize: 14),
                    hintText: isSwahili ? 'mfano: Dar es Salaam, Arusha' : 'e.g. Dar es Salaam, Arusha',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: districtCtrl,
                  decoration: InputDecoration(
                    labelText: isSwahili ? 'Wilaya' : 'Districts',
                    labelStyle: const TextStyle(fontSize: 14),
                    hintText: isSwahili ? 'mfano: Ilala, Kinondoni' : 'e.g. Ilala, Kinondoni',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: wardCtrl,
                  decoration: InputDecoration(
                    labelText: isSwahili ? 'Kata' : 'Wards',
                    labelStyle: const TextStyle(fontSize: 14),
                    hintText: isSwahili ? 'mfano: Kariakoo, Manzese' : 'e.g. Kariakoo, Manzese',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                isSwahili ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _saveServiceArea(
                  regionCtrl.text,
                  districtCtrl.text,
                  wardCtrl.text,
                  isSwahili,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(isSwahili ? 'Hifadhi' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveServiceArea(
    String regions,
    String districts,
    String wards,
    bool isSwahili,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (token == null || userId == null) return;

      // For now, send empty ID lists since we only have names
      // The backend should resolve names to IDs
      final result = await TajirikaService.updateServiceArea(
        token,
        userId,
        [], // regionIds
        [], // districtIds
        [], // wardIds
      );

      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Eneo limehifadhiwa' : 'Service area saved',
            ),
          ),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ==================== AVAILABILITY ====================

  Widget _buildAvailabilitySection(bool isSwahili) {
    return _sectionCard(
      title: isSwahili ? 'Ratiba ya Upatikanaji' : 'Availability Schedule',
      icon: Icons.schedule_rounded,
      child: Column(
        children: [
          ..._schedule.map((row) => _buildAvailabilityRow(row, isSwahili)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSavingAvailability ? null : _saveAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSavingAvailability
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isSwahili ? 'Hifadhi Ratiba' : 'Save Schedule',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityRow(_AvailabilityRow row, bool isSwahili) {
    final slot = AvailabilitySlot(dayOfWeek: row.dayOfWeek);
    final dayName = isSwahili ? slot.dayLabelSwahili : slot.dayLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              dayName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Switch(
              value: row.isAvailable,
              activeColor: _kPrimary,
              onChanged: (val) {
                setState(() => row.isAvailable = val);
              },
            ),
          ),
          if (row.isAvailable) ...[
            const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickTime(row, isStart: true),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    row.startTime,
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('-', style: TextStyle(color: _kSecondary)),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickTime(row, isStart: false),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    row.endTime,
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                ),
              ),
            ),
          ] else
            Expanded(
              child: Text(
                isSwahili ? 'Hapatikani' : 'Unavailable',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickTime(_AvailabilityRow row, {required bool isStart}) async {
    final current = isStart ? row.startTime : row.endTime;
    final parts = current.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          row.startTime = formatted;
        } else {
          row.endTime = formatted;
        }
      });
    }
  }

  Future<void> _saveAvailability() async {
    final messenger = ScaffoldMessenger.of(context);
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;

    setState(() => _isSavingAvailability = true);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (token == null || userId == null) return;

      final slots = _schedule
          .map((r) => AvailabilitySlot(
                dayOfWeek: r.dayOfWeek,
                startTime: r.startTime,
                endTime: r.endTime,
                isAvailable: r.isAvailable,
              ))
          .toList();

      final result = await TajirikaService.updateAvailability(token, userId, slots);

      if (!mounted) return;
      setState(() => _isSavingAvailability = false);

      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Ratiba imehifadhiwa' : 'Schedule saved',
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingAvailability = false);
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ==================== PAYOUT ACCOUNT ====================

  Widget _buildPayoutSection(bool isSwahili) {
    final method = _partner?.payoutMethod ?? '';
    final account = _partner?.payoutAccount ?? '';
    final hasAccount = method.isNotEmpty && account.isNotEmpty;

    String methodLabel;
    switch (method) {
      case 'mpesa':
        methodLabel = 'M-Pesa';
        break;
      case 'tigopesa':
        methodLabel = 'Tigo Pesa';
        break;
      case 'airtelmoney':
        methodLabel = 'Airtel Money';
        break;
      case 'bank':
        methodLabel = isSwahili ? 'Benki' : 'Bank Transfer';
        break;
      default:
        methodLabel = method;
    }

    return _sectionCard(
      title: isSwahili ? 'Akaunti ya Malipo' : 'Payout Account',
      icon: Icons.account_balance_wallet_rounded,
      trailing: TextButton(
        onPressed: () => _showPayoutDialog(isSwahili),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        child: Text(
          isSwahili ? 'Badilisha' : 'Edit',
          style: const TextStyle(color: _kPrimary, fontSize: 13),
        ),
      ),
      child: hasAccount
          ? Row(
              children: [
                Icon(
                  method == 'bank'
                      ? Icons.account_balance_rounded
                      : Icons.phone_android_rounded,
                  size: 20,
                  color: _kSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        methodLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        account,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Text(
              isSwahili
                  ? 'Bado hujaweka akaunti ya malipo'
                  : 'No payout account set',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
    );
  }

  void _showPayoutDialog(bool isSwahili) {
    String selectedMethod = _partner?.payoutMethod ?? 'mpesa';
    final accountCtrl = TextEditingController(
      text: _partner?.payoutAccount ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                isSwahili ? 'Badilisha Akaunti ya Malipo' : 'Edit Payout Account',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Njia ya malipo' : 'Payment method',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'mpesa', label: Text('M-Pesa', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 'tigopesa', label: Text('Tigo', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 'airtelmoney', label: Text('Airtel', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 'bank', label: Text('Bank', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {selectedMethod},
                      onSelectionChanged: (val) {
                        setDialogState(() => selectedMethod = val.first);
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: _kPrimary,
                        selectedForegroundColor: Colors.white,
                        foregroundColor: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: accountCtrl,
                      decoration: InputDecoration(
                        labelText: selectedMethod == 'bank'
                            ? (isSwahili ? 'Namba ya akaunti' : 'Account number')
                            : (isSwahili ? 'Namba ya simu' : 'Phone number'),
                        labelStyle: const TextStyle(fontSize: 14),
                        hintText: selectedMethod == 'bank'
                            ? '0123456789'
                            : '+255...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text(
                    isSwahili ? 'Ghairi' : 'Cancel',
                    style: const TextStyle(color: _kSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _savePayoutAccount(
                      selectedMethod,
                      accountCtrl.text.trim(),
                      isSwahili,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(isSwahili ? 'Hifadhi' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _savePayoutAccount(
    String method,
    String account,
    bool isSwahili,
  ) async {
    if (account.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (token == null || userId == null) return;

      final result = await TajirikaService.updatePayoutAccount(token, userId, {
        'method': method,
        'account': account,
      });

      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Akaunti imehifadhiwa' : 'Payout account saved',
            ),
          ),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ==================== NOTIFICATIONS ====================

  Widget _buildNotificationsSection(bool isSwahili) {
    return _sectionCard(
      title: isSwahili ? 'Arifa' : 'Notifications',
      icon: Icons.notifications_rounded,
      child: Column(
        children: [
          _notifToggle(
            isSwahili ? 'Sasisho za uthibitisho' : 'Verification updates',
            _notifVerification,
            (v) => setState(() => _notifVerification = v),
          ),
          _notifToggle(
            isSwahili ? 'Mabadiliko ya kiwango' : 'Tier changes',
            _notifTierChanges,
            (v) => setState(() => _notifTierChanges = v),
          ),
          _notifToggle(
            isSwahili ? 'Arifa za rufaa' : 'Referral alerts',
            _notifReferrals,
            (v) => setState(() => _notifReferrals = v),
          ),
          _notifToggle(
            isSwahili ? 'Vikumbusho vya mafunzo' : 'Training reminders',
            _notifTraining,
            (v) => setState(() => _notifTraining = v),
          ),
          _notifToggle(
            isSwahili ? 'Arifa za mapato' : 'Earnings notifications',
            _notifEarnings,
            (v) => setState(() => _notifEarnings = v),
          ),
        ],
      ),
    );
  }

  Widget _notifToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Switch(
            value: value,
            activeColor: _kPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ==================== ACCOUNT ACTIONS ====================

  Widget _buildAccountActionsSection(bool isSwahili) {
    return _sectionCard(
      title: isSwahili ? 'Hatua za Akaunti' : 'Account Actions',
      icon: Icons.settings_rounded,
      child: SizedBox(
        height: 48,
        child: TextButton(
          onPressed: () => _showDeactivateDialog(isSwahili),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            alignment: Alignment.centerLeft,
          ),
          child: Text(
            isSwahili
                ? 'Zima Akaunti ya Mshirika'
                : 'Deactivate Partner Account',
            style: const TextStyle(
              color: Color(0xFFF44336),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeactivateDialog(bool isSwahili) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            isSwahili
                ? 'Zima Akaunti ya Mshirika?'
                : 'Deactivate Partner Account?',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          content: Text(
            isSwahili
                ? 'Tafadhali wasiliana na timu ya msaada kuzima akaunti yako ya mshirika.\n\nBarua pepe: support@tajiri.co.tz'
                : 'Please contact the support team to deactivate your partner account.\n\nEmail: support@tajiri.co.tz',
            style: const TextStyle(fontSize: 14, color: _kSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                isSwahili ? 'Sawa' : 'OK',
                style: const TextStyle(color: _kPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ==================== HELPER CLASS ====================

class _AvailabilityRow {
  final int dayOfWeek;
  bool isAvailable;
  String startTime;
  String endTime;

  _AvailabilityRow({
    required this.dayOfWeek,
    this.isAvailable = true,
    this.startTime = '08:00',
    this.endTime = '17:00',
  });
}
