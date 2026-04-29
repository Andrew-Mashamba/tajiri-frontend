import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../tajirika/models/tajirika_models.dart';
import '../../tajirika/services/partner_product_service.dart';
import '../../tajirika/services/tajirika_service.dart';
import '../../tajirika/widgets/slot_picker.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kAccent = Color(0xFF2E7D32);
const Color _kMuted = Color(0xFF9E9E9E);

class BookAppointmentPage extends StatefulWidget {
  final int userId;
  final AppointmentVertical vertical;
  final List<String> skillFilter;
  final bool allowRecurring;
  final TajirikaPartner? preselectedPartner;
  final PartnerProduct? preselectedProduct;

  const BookAppointmentPage({
    super.key,
    required this.userId,
    required this.vertical,
    required this.skillFilter,
    this.allowRecurring = false,
    this.preselectedPartner,
    this.preselectedProduct,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  int _step = 0;

  TajirikaPartner? _partner;
  bool _loadingPartners = false;
  List<TajirikaPartner> _partners = const [];
  String? _partnerError;

  bool _loadingCatalog = false;
  List<PartnerProduct> _catalog = const [];
  PartnerProduct? _selectedProduct;
  final _customTitleCtrl = TextEditingController();
  final _customPriceCtrl = TextEditingController();
  final _customDurationCtrl = TextEditingController(text: '60');

  LocationKind _location = LocationKind.salon;
  DateTime? _startsAt;
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isRecurring = false;
  final Set<int> _weekdays = <int>{};
  DateTime? _recurringUntil;

  bool _anyProfessionalMode = false;

  bool _submitting = false;
  String? _serviceError;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _partner = widget.preselectedPartner;
    _selectedProduct = widget.preselectedProduct;
  }

  @override
  void dispose() {
    _customTitleCtrl.dispose();
    _customPriceCtrl.dispose();
    _customDurationCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadPartners() async {
    setState(() {
      _loadingPartners = true;
      _partnerError = null;
    });
    final token = LocalStorageService.instanceSync?.getAuthToken() ?? '';
    final partners = await TajirikaService.searchPartners(
      token,
      skills: widget.skillFilter,
    );
    if (!mounted) return;
    setState(() {
      _loadingPartners = false;
      _partners = partners;
      if (partners.isEmpty) {
        _partnerError = _isSwahili
            ? 'Hakuna mafundi waliosajiliwa.'
            : 'No partners registered yet.';
      }
    });
  }

  Future<void> _loadCatalog() async {
    if (_partner == null) return;
    setState(() {
      _loadingCatalog = true;
      _catalog = const [];
    });
    final res = await PartnerProductService.listProducts(
      partnerId: _partner!.id,
      activeOnly: true,
      limit: 30,
    );
    if (!mounted) return;
    setState(() {
      _loadingCatalog = false;
      if (res.success) {
        _catalog = res.products;
      }
    });
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final initial = _startsAt ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now.add(const Duration(hours: 1)) : initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickRecurringUntil() async {
    final now = DateTime.now();
    final initial = _recurringUntil ?? now.add(const Duration(days: 30));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.add(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    setState(() => _recurringUntil = date);
  }

  bool _validate(int step) {
    switch (step) {
      case 0:
        if (_partner == null) {
          _toast(_isSwahili ? 'Chagua fundi' : 'Pick a partner');
          return false;
        }
        return true;
      case 1:
        if (_selectedProduct != null) {
          setState(() => _serviceError = null);
          return true;
        }
        if (_customTitleCtrl.text.trim().isEmpty) {
          setState(() => _serviceError = _isSwahili ? 'Andika huduma' : 'Service required');
          return false;
        }
        if (int.tryParse(_customPriceCtrl.text.trim()) == null) {
          setState(() => _serviceError = _isSwahili ? 'Bei sahihi (TZS)' : 'Valid price (TZS)');
          return false;
        }
        if ((int.tryParse(_customDurationCtrl.text.trim()) ?? 0) <= 0) {
          setState(() => _serviceError = _isSwahili ? 'Muda sahihi' : 'Valid duration');
          return false;
        }
        setState(() => _serviceError = null);
        return true;
      case 2:
        return true;
      case 3:
        if (_startsAt == null) {
          _toast(_isSwahili ? 'Chagua siku na saa' : 'Pick a date and time');
          return false;
        }
        if (_startsAt!.isBefore(DateTime.now())) {
          _toast(_isSwahili ? 'Saa imeshapita' : 'That time has passed');
          return false;
        }
        return true;
      case 4:
        if (_location == LocationKind.home && _addressCtrl.text.trim().length < 6) {
          _toast(_isSwahili ? 'Andika anwani kamili' : 'Enter your address');
          return false;
        }
        return true;
      case 5:
        if (_isRecurring) {
          if (_weekdays.isEmpty) {
            _toast(_isSwahili ? 'Chagua siku' : 'Pick at least one weekday');
            return false;
          }
          if (_recurringUntil == null) {
            _toast(_isSwahili ? 'Chagua tarehe ya mwisho' : 'Pick an end date');
            return false;
          }
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    for (var i = 0; i <= 5; i++) {
      if (!_validate(i)) {
        setState(() => _step = i);
        return;
      }
    }
    final title = _selectedProduct?.title ?? _customTitleCtrl.text.trim();
    final price = _selectedProduct?.basePriceTzs ?? int.parse(_customPriceCtrl.text.trim());
    final duration = _selectedProduct?.leadTimeHours != null && _selectedProduct!.leadTimeHours > 0
        ? _selectedProduct!.leadTimeHours * 60
        : int.parse(_customDurationCtrl.text.trim());
    final skillRaw = _selectedProduct?.skillCategoryRaw ??
        (widget.skillFilter.isNotEmpty ? widget.skillFilter.first : null);
    setState(() => _submitting = true);
    final res = await AppointmentService.create(
      userId: widget.userId,
      targetPartnerUserId: _partner!.userId,
      vertical: widget.vertical,
      serviceTitle: title,
      servicePriceTzs: price,
      durationMin: duration,
      locationKind: _location,
      startsAt: _startsAt!,
      partnerProductId: _selectedProduct?.id,
      skillCategory: skillRaw,
      customerAddress: _location == LocationKind.home ? _addressCtrl.text.trim() : null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isRecurring: _isRecurring,
      recurringPattern: _isRecurring
          ? RecurringPattern(
              weekdays: _weekdays.toList()..sort(),
              until: _recurringUntil,
            )
          : null,
      anyProfessionalMode: _anyProfessionalMode,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success && res.appointment != null) {
      _toast(_isSwahili
          ? 'Ombi limewekwa. Subiri uthibitisho.'
          : 'Booking sent. Awaiting confirmation.');
      Navigator.of(context).pop(res.appointment);
    } else {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    final lastStep = widget.allowRecurring ? 6 : 6;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSw
            ? 'Weka Miadi - ${widget.vertical.labelSwahili}'
            : 'Book - ${widget.vertical.label}'),
      ),
      body: SafeArea(
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _step,
          onStepTapped: (i) => setState(() => _step = i),
          onStepContinue: () async {
            if (!_validate(_step)) return;
            if (_step == 0 && _partner != null && _catalog.isEmpty) {
              await _loadCatalog();
            }
            if (_step < lastStep) {
              setState(() => _step += 1);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_step > 0) setState(() => _step -= 1);
          },
          controlsBuilder: (context, details) {
            final isLast = _step == lastStep;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                  onPressed: _submitting ? null : details.onStepContinue,
                  child: _submitting && isLast
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isLast
                          ? (isSw ? 'Tuma Ombi' : 'Send Booking')
                          : (isSw ? 'Endelea' : 'Continue')),
                ),
                const SizedBox(width: 12),
                if (_step > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(isSw ? 'Rudi' : 'Back'),
                  ),
              ]),
            );
          },
          steps: [
            _stepPartner(isSw),
            _stepService(isSw),
            _stepLocation(isSw),
            _stepTime(isSw),
            _stepAddress(isSw),
            _stepExtras(isSw),
            _stepReview(isSw),
          ],
        ),
      ),
    );
  }

  Step _stepPartner(bool isSw) => Step(
        title: Text(isSw ? 'Chagua fundi' : 'Pick partner'),
        isActive: _step >= 0,
        state: _partner != null && _step > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_partner != null)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_rounded, color: _kAccent),
                  title: Text(_partner!.name),
                  subtitle: Text(
                      '${_partner!.aggregateRating.toStringAsFixed(1)}★ • ${_partner!.jobsCompleted} ${isSw ? "kazi" : "jobs"}'),
                  trailing: TextButton(
                    onPressed: () => setState(() {
                      _partner = null;
                      _selectedProduct = null;
                      _catalog = const [];
                    }),
                    child: Text(isSw ? 'Badili' : 'Change'),
                  ),
                ),
              ),
            if (_partner == null) ...[
              if (_loadingPartners)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
                ),
              if (_partnerError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_partnerError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (!_loadingPartners && _partners.isEmpty)
                TextButton.icon(
                  onPressed: _loadPartners,
                  icon: const Icon(Icons.search_rounded),
                  label: Text(isSw ? 'Tafuta mafundi' : 'Find partners'),
                ),
              if (!_loadingPartners && _partners.isNotEmpty)
                ..._partners.take(8).map((p) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: p.photoUrl.isNotEmpty
                            ? NetworkImage(ApiConfig.sanitizeUrl(p.photoUrl) ?? p.photoUrl)
                            : null,
                        child: p.photoUrl.isEmpty ? const Icon(Icons.person_rounded) : null,
                      ),
                      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${p.aggregateRating.toStringAsFixed(1)}★ • ${p.jobsCompleted} ${isSw ? "kazi" : "jobs"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => setState(() => _partner = p),
                    )),
            ],
          ],
        ),
      );

  Step _stepService(bool isSw) => Step(
        title: Text(isSw ? 'Huduma' : 'Service'),
        isActive: _step >= 1,
        state: _step > 1 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedProduct?.requiresPatchTest == true) _patchTestBanner(isSw),
            if (_loadingCatalog)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
              ),
            if (!_loadingCatalog && _catalog.isNotEmpty) ...[
              Text(isSw ? 'Toka kwenye orodha:' : 'From catalog:',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ..._catalog.map((p) {
                final selected = _selectedProduct?.id == p.id;
                return Card(
                  color: selected ? _kPrimary.withValues(alpha: 0.05) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: selected ? _kPrimary : Colors.grey.shade300,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${_fmtTzs(p.basePriceTzs)} TZS${p.leadTimeHours > 0 ? ' • ${p.leadTimeHours * 60} min' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: selected ? const Icon(Icons.check_circle_rounded, color: _kAccent) : null,
                    onTap: () => setState(() => _selectedProduct = p),
                  ),
                );
              }),
              const Divider(height: 24),
            ],
            Text(
              _catalog.isEmpty
                  ? (isSw ? 'Andika huduma:' : 'Custom service:')
                  : (isSw ? 'Au andika nyingine:' : 'Or custom:'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _customTitleCtrl,
              enabled: _selectedProduct == null,
              decoration: InputDecoration(
                labelText: isSw ? 'Huduma' : 'Service',
                hintText: isSw ? 'Mfano: Manicure' : 'e.g. Manicure',
                border: const OutlineInputBorder(),
                errorText: _serviceError,
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _customPriceCtrl,
                  enabled: _selectedProduct == null,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: isSw ? 'Bei (TZS)' : 'Price (TZS)',
                    hintText: '5000',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _customDurationCtrl,
                  enabled: _selectedProduct == null,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: isSw ? 'Dakika' : 'Minutes',
                    hintText: '60',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
          ],
        ),
      );

  Step _stepLocation(bool isSw) => Step(
        title: Text(isSw ? 'Mahali' : 'Location'),
        isActive: _step >= 2,
        state: _step > 2 ? StepState.complete : StepState.indexed,
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LocationKind.values.map((k) {
            final selected = _location == k;
            return ChoiceChip(
              avatar: Icon(k.icon, size: 18),
              label: Text(isSw ? k.labelSwahili : k.label),
              selected: selected,
              onSelected: (_) => setState(() => _location = k),
            );
          }).toList(),
        ),
      );

  Step _stepTime(bool isSw) {
    final skillScope = _selectedProduct?.skillCategoryRaw ??
        (widget.skillFilter.isNotEmpty ? widget.skillFilter.first : null);
    return Step(
      title: Text(isSw ? 'Muda' : 'Time'),
      isActive: _step >= 3,
      state: _startsAt != null && _step > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_partner != null)
            SlotPicker(
              partnerUserId: _partner!.userId,
              skillCategory: skillScope,
              selected: _startsAt,
              onSelected: (dt) => setState(() => _startsAt = dt),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickStart,
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text(_startsAt == null
                ? (isSw ? 'Au chagua wakati mwingine' : 'Or pick custom time')
                : _formatDateTime(_startsAt!)),
          ),
        ],
      ),
    );
  }

  Step _stepAddress(bool isSw) => Step(
        title: Text(isSw ? 'Anwani' : 'Address'),
        isActive: _step >= 4,
        state: _step > 4 ? StepState.complete : StepState.indexed,
        content: _location == LocationKind.home
            ? TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isSw ? 'Anwani yako' : 'Your address',
                  hintText: isSw
                      ? 'Mfano: Mikocheni B, Mtaa wa Tunisia, Nyumba 12'
                      : 'e.g. Mikocheni B, Tunisia Street, House 12',
                  border: const OutlineInputBorder(),
                ),
              )
            : Text(
                isSw
                    ? 'Hatuhitaji anwani kwa huduma ya ${_location.labelSwahili.toLowerCase()}.'
                    : 'No address needed for ${_location.label.toLowerCase()}.',
                style: const TextStyle(color: _kMuted),
              ),
      );

  Step _stepExtras(bool isSw) => Step(
        title: Text(isSw ? 'Maelezo' : 'Notes'),
        isActive: _step >= 5,
        state: _step > 5 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: isSw ? 'Maelezo (hiari)' : 'Notes (optional)',
                hintText: isSw
                    ? 'Mfano: Una mzio? Una bidhaa zako mwenyewe?'
                    : 'e.g. Allergies, bringing your own products?',
                border: const OutlineInputBorder(),
              ),
            ),
            if (widget.allowRecurring) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(isSw ? 'Rudia kila wiki' : 'Repeat weekly'),
                subtitle: Text(isSw
                    ? 'Tengeneza miadi ya kila wiki kwa siku ulizochagua'
                    : 'Auto-create weekly sessions on selected days'),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                contentPadding: EdgeInsets.zero,
              ),
              if (_isRecurring) ...[
                Text(isSw ? 'Siku za wiki' : 'Weekdays',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _weekdayChips(isSw),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickRecurringUntil,
                  icon: const Icon(Icons.event_busy_rounded),
                  label: Text(_recurringUntil == null
                      ? (isSw ? 'Tarehe ya mwisho' : 'End date')
                      : _formatDate(_recurringUntil!)),
                ),
              ],
            ],
          ],
        ),
      );

  List<Widget> _weekdayChips(bool isSw) {
    final labelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final labelsSw = ['Jtatu', 'Jnne', 'Jtano', 'Alh', 'Iju', 'Jmosi', 'Jpili'];
    // Carbon convention: 0=Sun, 1=Mon..6=Sat. We display Mon→Sun so map index 6 to 0.
    return List.generate(7, (i) {
      final wd = (i + 1) % 7;
      final selected = _weekdays.contains(wd);
      return FilterChip(
        label: Text(isSw ? labelsSw[i] : labelsEn[i]),
        selected: selected,
        onSelected: (v) => setState(() {
          if (v) {
            _weekdays.add(wd);
          } else {
            _weekdays.remove(wd);
          }
        }),
      );
    });
  }

  Step _stepReview(bool isSw) => Step(
        title: Text(isSw ? 'Hakiki' : 'Review'),
        isActive: _step >= 6,
        state: _step >= 6 ? StepState.editing : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(isSw ? 'Fundi:' : 'Partner', _partner?.name ?? '—'),
            _row(isSw ? 'Huduma:' : 'Service',
                _selectedProduct?.title ?? _customTitleCtrl.text.trim()),
            _row(isSw ? 'Bei:' : 'Price',
                '${_fmtTzs(_selectedProduct?.basePriceTzs ?? int.tryParse(_customPriceCtrl.text.trim()) ?? 0)} TZS'),
            _row(isSw ? 'Mahali:' : 'Location', isSw ? _location.labelSwahili : _location.label),
            _row(isSw ? 'Muda:' : 'When', _startsAt == null ? '—' : _formatDateTime(_startsAt!)),
            if (_location == LocationKind.home && _addressCtrl.text.trim().isNotEmpty)
              _row(isSw ? 'Anwani:' : 'Address', _addressCtrl.text.trim()),
            if (_notesCtrl.text.trim().isNotEmpty)
              _row(isSw ? 'Maelezo:' : 'Notes', _notesCtrl.text.trim()),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                isSw ? 'Mtaalamu yeyote / Any professional' : 'Any professional',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                isSw
                    ? 'Mfumo atachagua mtaalamu aliye bora zaidi'
                    : 'System will pick the best available professional',
                style: const TextStyle(fontSize: 11, color: _kMuted),
              ),
              value: _anyProfessionalMode,
              onChanged: (v) => setState(() => _anyProfessionalMode = v),
            ),
            if (_anyProfessionalMode)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSw
                      ? 'Mtaalamu atachaguliwa kiotomatiki na mfumo.'
                      : 'A professional will be auto-assigned by the system.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF0D47A1)),
                ),
              ),
            // #34 surcharge line items from selected product
            if (_selectedProduct != null) ...[
              const Divider(),
              _surchargeRow(isSw, 'Usafiri / Travel', _selectedProduct?.travelSurchargeTzs),
              _surchargeRow(isSw, 'Baada ya masaa / After-hours', _selectedProduct?.afterHoursSurchargeTzs),
              _surchargeRow(isSw, 'Sikukuu / Holiday', _selectedProduct?.holidayPremiumTzs),
              _surchargeRow(isSw, 'Maegesho / Parking', _selectedProduct?.parkingPassThroughTzs),
            ],
            if (_isRecurring) ...[
              _row(
                  isSw ? 'Rudia:' : 'Repeats',
                  _weekdays.isEmpty
                      ? (isSw ? 'Hakuna siku' : 'No weekdays')
                      : (_weekdays.toList()
                          ..sort((a, b) => (a == 0 ? 7 : a).compareTo(b == 0 ? 7 : b)))
                          .map(_weekdayShort)
                          .join(', ')),
              if (_recurringUntil != null)
                _row(isSw ? 'Hadi:' : 'Until', _formatDate(_recurringUntil!)),
            ],
          ],
        ),
      );

  /// Spec line 626 — patch-test gating banner. Shown when the selected
  /// product is flagged `requires_patch_test=true` (e.g. hair colour, deep
  /// chemical peel). The customer must book a separate patch-test
  /// appointment ≥24h before the actual service.
  Widget _patchTestBanner(bool isSw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        border: Border.all(color: const Color(0xFFFFB74D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_rounded, size: 18, color: Color(0xFFB15400)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isSw ? 'Kipimo cha mzio kinahitajika' : 'Patch test required',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFB15400)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isSw
                ? 'Huduma hii inahitaji kipimo cha mzio kabla ya saa 24. Weka kipimo kwanza, kisha rudi kuagiza huduma.'
                : 'This service requires a patch test ≥24h before. Book the test first, then come back to schedule.',
            style: const TextStyle(fontSize: 11, color: _kPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 96,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ]),
      );

  Widget _surchargeRow(bool isSw, String label, int? amount) {
    if (amount == null || amount <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
          ),
          Expanded(
            child: Text(
              '+ ${_fmtTzs(amount)} TZS',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB71C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTzs(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _weekdayShort(int wd) {
    // Carbon convention: 0=Sun..6=Sat.
    const en = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (wd < 0 || wd > 6) return '?';
    return en[wd];
  }

  String _formatDateTime(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd $hh:$mi';
  }

  String _formatDate(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
  }
}
