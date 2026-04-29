import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../events/models/event_booking.dart';
import '../../events/pages/book_event_package_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec §10 travel/safari variant: BookEventPackagePage + itinerary builder
/// + travelers list. NIDA/passport stored as plain JSON in v1; field-level
/// encryption is the data-protection foundational work (same deferral as F7).
class BookSafariPage extends BookEventPackagePage {
  const BookSafariPage({
    super.key,
    required super.customerUserId,
    super.package,
    super.partnerUserId,
    super.partnerId,
    super.partnerName,
    super.skillCategory,
  }) : super(initialKind: EventKind.safari);

  @override
  State<BookSafariPage> createState() => _BookSafariPageState();
}

class _ItineraryDayDraft {
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController activityCtrl = TextEditingController();
  final TextEditingController accommodationCtrl = TextEditingController();
  final TextEditingController mealsCtrl = TextEditingController();
  void dispose() {
    locationCtrl.dispose();
    activityCtrl.dispose();
    accommodationCtrl.dispose();
    mealsCtrl.dispose();
  }
}

class _TravelerDraft {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController idCtrl = TextEditingController();
  final TextEditingController dietaryCtrl = TextEditingController();
  final TextEditingController medicalCtrl = TextEditingController();
  final TextEditingController emergencyCtrl = TextEditingController();
  void dispose() {
    nameCtrl.dispose();
    idCtrl.dispose();
    dietaryCtrl.dispose();
    medicalCtrl.dispose();
    emergencyCtrl.dispose();
  }
}

class _BookSafariPageState extends BookEventPackagePageState<BookSafariPage> {
  final List<_ItineraryDayDraft> _days = [_ItineraryDayDraft()];
  final List<_TravelerDraft> _travelers = [_TravelerDraft()];

  @override
  void dispose() {
    for (final d in _days) {
      d.dispose();
    }
    for (final t in _travelers) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  bool get isSafariReady {
    if (_travelers.isEmpty) return false;
    final first = _travelers.first;
    if (first.nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isSwahili
            ? 'Andika jina la msafiri wa kwanza'
            : 'Add at least one traveler name'),
      ));
      return false;
    }
    return true;
  }

  @override
  List<ItineraryDay>? get safariItinerary {
    final list = <ItineraryDay>[];
    for (var i = 0; i < _days.length; i++) {
      final d = _days[i];
      list.add(ItineraryDay(
        day: i + 1,
        location: _nullIfEmpty(d.locationCtrl.text),
        activity: _nullIfEmpty(d.activityCtrl.text),
        accommodation: _nullIfEmpty(d.accommodationCtrl.text),
        includedMeals: _nullIfEmpty(d.mealsCtrl.text),
      ));
    }
    return list;
  }

  @override
  List<Traveler>? get safariTravelers {
    final list = <Traveler>[];
    for (final t in _travelers) {
      final name = t.nameCtrl.text.trim();
      if (name.isEmpty) continue;
      list.add(Traveler(
        name: name,
        nidaOrPassport: _nullIfEmpty(t.idCtrl.text),
        dietary: _nullIfEmpty(t.dietaryCtrl.text),
        medical: _nullIfEmpty(t.medicalCtrl.text),
        emergencyContact: _nullIfEmpty(t.emergencyCtrl.text),
      ));
    }
    return list;
  }

  @override
  List<Step> extraSteps() {
    return [
      Step(
        title: Text(isSwahili ? 'Ratiba ya safari' : 'Itinerary'),
        isActive: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._days.asMap().entries.map((e) => _dayCard(e.key, e.value)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _days.add(_ItineraryDayDraft())),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(isSwahili ? 'Ongeza siku' : 'Add day'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kBorder),
              ),
            ),
          ],
        ),
      ),
      Step(
        title: Text(isSwahili ? 'Wasafiri' : 'Travelers'),
        isActive: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSwahili
                  ? 'Maelezo ya wasafiri yanahifadhiwa kwa siri (encryption foundational TODO).'
                  : 'Traveler details are stored confidentially (encryption foundational TODO).',
              style: const TextStyle(fontSize: 11, color: _kMuted),
            ),
            const SizedBox(height: 8),
            ..._travelers.asMap().entries.map((e) => _travelerCard(e.key, e.value)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _travelers.add(_TravelerDraft())),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(isSwahili ? 'Ongeza msafiri' : 'Add traveler'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kBorder),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _dayCard(int index, _ItineraryDayDraft d) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${isSwahili ? "Siku" : "Day"} ${index + 1}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              if (_days.length > 1)
                IconButton(
                  onPressed: () => setState(() {
                    d.dispose();
                    _days.removeAt(index);
                  }),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: d.locationCtrl,
            decoration: _input(isSwahili ? 'Mahali (mfano: Lake Manyara)' : 'Location'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: d.activityCtrl,
            decoration: _input(isSwahili ? 'Shughuli' : 'Activity'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: d.accommodationCtrl,
                  decoration: _input(isSwahili ? 'Malazi' : 'Accommodation'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: d.mealsCtrl,
                  decoration: _input(isSwahili ? 'Chakula' : 'Meals'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _travelerCard(int index, _TravelerDraft t) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${isSwahili ? "Msafiri" : "Traveler"} ${index + 1}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              if (_travelers.length > 1)
                IconButton(
                  onPressed: () => setState(() {
                    t.dispose();
                    _travelers.removeAt(index);
                  }),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: t.nameCtrl,
            decoration: _input(isSwahili ? 'Jina kamili' : 'Full name'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: t.idCtrl,
            decoration: _input(isSwahili ? 'NIDA / Passport' : 'NIDA / Passport'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: t.dietaryCtrl,
            decoration: _input(isSwahili ? 'Lishe (hiari)' : 'Dietary (optional)'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: t.medicalCtrl,
            decoration: _input(isSwahili ? 'Maelezo ya kiafya (hiari)' : 'Medical (optional)'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: t.emergencyCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
            decoration: _input(isSwahili ? 'Simu ya dharura' : 'Emergency phone'),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  String? _nullIfEmpty(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
      );
}
