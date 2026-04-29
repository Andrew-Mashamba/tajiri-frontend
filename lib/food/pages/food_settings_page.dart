import 'package:flutter/material.dart';

import '../models/food_preferences.dart';
import '../services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);

const List<String> _kDietaryTags = [
  'halal',
  'vegetarian',
  'vegan',
  'no_pork',
  'gluten_free',
  'spicy',
];

const List<String> _kAllergens = [
  'nuts',
  'dairy',
  'eggs',
  'seafood',
  'soy',
  'wheat',
];

const List<String> _kNotificationCategories = [
  'new_listings',
  'homemade_drops',
  'order_updates',
  'reservation_reminders',
  'payback_pricing',
  'saidia_needs',
  'donation_receipts',
  'emergencies',
  'reviews',
];

const List<String> _kPaymentMethods = ['wallet', 'mpesa', 'card', 'cash'];

class FoodSettingsPage extends StatefulWidget {
  final int userId;
  const FoodSettingsPage({super.key, required this.userId});

  @override
  State<FoodSettingsPage> createState() => _FoodSettingsPageState();
}

class _FoodSettingsPageState extends State<FoodSettingsPage> {
  final FoodService _service = FoodService();
  final TextEditingController _wardController = TextEditingController();
  FoodPreferences? _prefs;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _wardController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.getFoodPreferences(userId: widget.userId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _loading = false;
        _prefs = res.data;
        _wardController.text = res.data!.defaultWard ?? '';
      });
    } else {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Imeshindwa kupakia';
      });
    }
  }

  Future<void> _save({
    List<String>? dietaryTags,
    List<String>? allergens,
    String? defaultWard,
    double? maxDeliveryRadiusKm,
    String? defaultPaymentMethod,
    List<String>? notificationCategories,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? showSaidiaRail,
    String? autoTagZakat,
    String? autoTagFungu,
    bool? hideOnLeaderboard,
    bool? hideFromCommunityFeed,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final res = await _service.updateFoodPreferences(
      userId: widget.userId,
      dietaryTags: dietaryTags,
      allergens: allergens,
      defaultWard: defaultWard,
      maxDeliveryRadiusKm: maxDeliveryRadiusKm,
      defaultPaymentMethod: defaultPaymentMethod,
      notificationCategories: notificationCategories,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      showSaidiaRail: showSaidiaRail,
      autoTagZakat: autoTagZakat,
      autoTagFungu: autoTagFungu,
      hideOnLeaderboard: hideOnLeaderboard,
      hideFromCommunityFeed: hideFromCommunityFeed,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (res.success && res.data != null) _prefs = res.data;
    });
    if (!res.success) {
      messenger.showSnackBar(
        SnackBar(content: Text(res.message ?? 'Imeshindwa kuhifadhi')),
      );
    }
  }

  void _toggleTag(String tag) {
    final current = List<String>.from(_prefs!.dietaryTags);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    _save(dietaryTags: current);
  }

  void _toggleAllergen(String tag) {
    final current = List<String>.from(_prefs!.allergens);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    _save(allergens: current);
  }

  void _toggleNotification(String tag) {
    final current = List<String>.from(_prefs!.notificationCategories);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    _save(notificationCategories: current);
  }

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _prefs!.quietHoursStart : _prefs!.quietHoursEnd;
    TimeOfDay initial = const TimeOfDay(hour: 22, minute: 0);
    if (current != null && current.contains(':')) {
      final parts = current.split(':');
      final h = int.tryParse(parts[0]) ?? 22;
      final m = int.tryParse(parts[1]) ?? 0;
      initial = TimeOfDay(hour: h, minute: m);
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    if (start) {
      _save(quietHoursStart: formatted);
    } else {
      _save(quietHoursEnd: formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: const Text(
          'Mapendeleo ya Chakula',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _error != null
                ? _errorState()
                : _body(),
      ),
    );
  }

  Widget _errorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
              const SizedBox(height: 12),
              Text(
                _error ?? '',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Jaribu tena')),
            ],
          ),
        ),
      );

  Widget _body() {
    final p = _prefs!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Lishe',
          subtitle: 'Chagua alama zinazoendana na wewe',
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _kDietaryTags.map((tag) {
              final selected = p.dietaryTags.contains(tag);
              return FilterChip(
                label: Text(_labelForTag(tag)),
                selected: selected,
                onSelected: (_) => _toggleTag(tag),
                selectedColor: _kAccent.withValues(alpha: 0.15),
                checkmarkColor: _kAccent,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected ? _kAccent : _kPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Mzio',
          subtitle: 'Tutakujulisha kabla ya kuonyesha chakula chenye hivi',
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _kAllergens.map((tag) {
              final selected = p.allergens.contains(tag);
              return FilterChip(
                label: Text(_labelForAllergen(tag)),
                selected: selected,
                onSelected: (_) => _toggleAllergen(tag),
                selectedColor: Colors.red.withValues(alpha: 0.12),
                checkmarkColor: Colors.red.shade700,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.red.shade700 : _kPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Eneo la msingi',
          subtitle: 'Kata unayokaa — hutumika kupendekeza chakula cha karibu',
          child: TextField(
            controller: _wardController,
            decoration: InputDecoration(
              hintText: 'mf. Mikocheni',
              hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
              filled: true,
              fillColor: _kBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save_rounded, size: 20, color: _kPrimary),
                onPressed: () => _save(defaultWard: _wardController.text.trim()),
              ),
            ),
            onSubmitted: (v) => _save(defaultWard: v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Umbali wa juu wa usafirishaji',
          subtitle: '${(p.maxDeliveryRadiusKm ?? 5).toStringAsFixed(1)} km',
          child: Slider(
            value: (p.maxDeliveryRadiusKm ?? 5).clamp(0.5, 30.0).toDouble(),
            min: 0.5,
            max: 30,
            divisions: 59,
            activeColor: _kAccent,
            label: '${(p.maxDeliveryRadiusKm ?? 5).toStringAsFixed(1)} km',
            onChanged: (v) => setState(() {
              _prefs = p.copyWith(maxDeliveryRadiusKm: v);
            }),
            onChangeEnd: (v) => _save(maxDeliveryRadiusKm: v),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Njia ya malipo ya kawaida',
          subtitle: 'Itachaguliwa kwanza unapoagiza',
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _kPaymentMethods.map((m) {
              final selected = p.defaultPaymentMethod == m;
              return ChoiceChip(
                label: Text(_labelForPayment(m)),
                selected: selected,
                onSelected: (_) => _save(defaultPaymentMethod: m),
                selectedColor: _kPrimary.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected ? _kPrimary : _kSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Arifa',
          subtitle: 'Chagua ni arifa zipi unataka kupokea',
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _kNotificationCategories.map((n) {
              final selected = p.notificationCategories.contains(n);
              return FilterChip(
                label: Text(_labelForNotification(n)),
                selected: selected,
                onSelected: (_) => _toggleNotification(n),
                selectedColor: _kAccent.withValues(alpha: 0.15),
                checkmarkColor: _kAccent,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected ? _kAccent : _kPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Masaa ya ukimya',
          subtitle: 'Hatukutumi arifa ndani ya masaa haya',
          child: Row(
            children: [
              Expanded(
                child: _timeButton(
                  label: 'Anza',
                  value: p.quietHoursStart,
                  onTap: () => _pickTime(start: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _timeButton(
                  label: 'Mwisho',
                  value: p.quietHoursEnd,
                  onTap: () => _pickTime(start: false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Saidia Sasa',
          subtitle: 'Onyesha mahitaji ya mashirika kwenye ukurasa wa nyumbani',
          child: SwitchListTile.adaptive(
            value: p.showSaidiaRail,
            onChanged: (v) => _save(showSaidiaRail: v),
            activeThumbColor: _kAccent,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Onyesha Saidia Sasa',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Zakat na Fungu la Kumi',
          subtitle: 'Tuulize kabla ya kuweka alama, au tuweke kiotomatiki',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Zakat',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 6),
              _autoTagChips(
                value: p.autoTagZakat,
                contextOption: 'ramadan_only',
                contextLabel: 'Ramadhani tu',
                onChanged: (v) => _save(autoTagZakat: v),
              ),
              const SizedBox(height: 12),
              const Text('Fungu la Kumi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 6),
              _autoTagChips(
                value: p.autoTagFungu,
                contextOption: 'sunday_only',
                contextLabel: 'Jumapili tu',
                onChanged: (v) => _save(autoTagFungu: v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Faragha',
          subtitle: 'Dhibiti uonekano wako kwenye jukwaa',
          child: Column(
            children: [
              SwitchListTile.adaptive(
                value: p.hideOnLeaderboard,
                onChanged: (v) => _save(hideOnLeaderboard: v),
                activeThumbColor: _kPrimary,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Jificha kwenye ubao wa viongozi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
              ),
              SwitchListTile.adaptive(
                value: p.hideFromCommunityFeed,
                onChanged: (v) => _save(hideFromCommunityFeed: v),
                activeThumbColor: _kPrimary,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Usionyeshe michango yangu kwenye feed',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_saving)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionCard({required String title, String? subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _timeButton({required String label, required String? value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 18, color: _kSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    value != null && value.isNotEmpty ? _formatTime(value) : '--:--',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _autoTagChips({
    required String value,
    required String contextOption,
    required String contextLabel,
    required ValueChanged<String> onChanged,
  }) {
    final options = <_AutoTagOption>[
      _AutoTagOption('yes', 'Daima', _kAccent),
      _AutoTagOption(contextOption, contextLabel, _kPrimary),
      _AutoTagOption('ask', 'Niulize', _kSecondary),
      _AutoTagOption('no', 'Kamwe', Colors.red.shade700),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((o) {
        final selected = value == o.value;
        return ChoiceChip(
          label: Text(o.label),
          selected: selected,
          onSelected: (_) => onChanged(o.value),
          selectedColor: o.color.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            fontSize: 11,
            color: selected ? o.color : _kSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(String raw) {
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }

  String _labelForTag(String tag) {
    switch (tag) {
      case 'halal':
        return 'Halali';
      case 'vegetarian':
        return 'Mboga tu';
      case 'vegan':
        return 'Vegan';
      case 'no_pork':
        return 'Bila nguruwe';
      case 'gluten_free':
        return 'Bila ngano';
      case 'spicy':
        return 'Pilipili';
      default:
        return tag;
    }
  }

  String _labelForAllergen(String tag) {
    switch (tag) {
      case 'nuts':
        return 'Karanga';
      case 'dairy':
        return 'Maziwa';
      case 'eggs':
        return 'Mayai';
      case 'seafood':
        return 'Samaki/dagaa';
      case 'soy':
        return 'Soya';
      case 'wheat':
        return 'Ngano';
      default:
        return tag;
    }
  }

  String _labelForPayment(String m) {
    switch (m) {
      case 'wallet':
        return 'Pochi';
      case 'mpesa':
        return 'M-Pesa';
      case 'card':
        return 'Kadi';
      case 'cash':
        return 'Pesa taslimu';
      default:
        return m;
    }
  }

  String _labelForNotification(String n) {
    switch (n) {
      case 'new_listings':
        return 'Vyakula vipya';
      case 'homemade_drops':
        return 'Wapishi wa nyumbani';
      case 'order_updates':
        return 'Hali za oda';
      case 'reservation_reminders':
        return 'Vikumbusho vya bukingi';
      case 'payback_pricing':
        return 'Bei ya Payback';
      case 'saidia_needs':
        return 'Mahitaji ya mashirika';
      case 'donation_receipts':
        return 'Risiti za michango';
      case 'emergencies':
        return 'Dharura';
      case 'reviews':
        return 'Maoni';
      default:
        return n;
    }
  }
}

class _AutoTagOption {
  final String value;
  final String label;
  final Color color;
  const _AutoTagOption(this.value, this.label, this.color);
}
