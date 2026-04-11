// lib/my_baby/pages/my_baby_home_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';
import 'baby_dashboard_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class MyBabyHomePage extends StatefulWidget {
  final int userId;
  const MyBabyHomePage({super.key, required this.userId});
  @override
  State<MyBabyHomePage> createState() => _MyBabyHomePageState();
}

class _MyBabyHomePageState extends State<MyBabyHomePage> {
  final MyBabyService _service = MyBabyService();

  bool _isLoading = true;
  List<Baby> _babies = [];
  String? _token;

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getMyBabies(_token!, widget.userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) _babies = result.items;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isSwahili
              ? 'Imeshindikana kupakia watoto'
              : 'Failed to load babies')),
        );
      }
    }
  }

  void _showRegisterBabyDialog() {
    final nameController = TextEditingController();
    DateTime birthDate = DateTime.now();
    String? gender;
    final weightController = TextEditingController();
    final lengthController = TextEditingController();
    final sw = _isSwahili;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Sajili Mtoto' : 'Register Baby',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: sw ? 'Jina la Mtoto' : "Baby's Name",
                      labelStyle:
                          const TextStyle(fontSize: 13, color: _kSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: birthDate,
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 1825)),
                        lastDate: DateTime.now(),
                        helpText: sw
                            ? 'Tarehe ya kuzaliwa'
                            : 'Date of Birth',
                      );
                      if (picked != null) {
                        setSheetState(() => birthDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: _kSecondary),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sw
                                    ? 'Tarehe ya Kuzaliwa'
                                    : 'Date of Birth',
                                style: const TextStyle(
                                    fontSize: 11, color: _kSecondary),
                              ),
                              Text(
                                '${birthDate.day}/${birthDate.month}/${birthDate.year}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(sw ? 'Jinsia:' : 'Gender:',
                          style: const TextStyle(
                              fontSize: 13, color: _kSecondary)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: Text(sw ? 'Mvulana' : 'Boy'),
                        selected: gender == 'male',
                        onSelected: (v) =>
                            setSheetState(() => gender = v ? 'male' : null),
                        selectedColor: _kPrimary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: gender == 'male' ? _kPrimary : _kSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(sw ? 'Msichana' : 'Girl'),
                        selected: gender == 'female',
                        onSelected: (v) =>
                            setSheetState(() => gender = v ? 'female' : null),
                        selectedColor: _kPrimary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color:
                              gender == 'female' ? _kPrimary : _kSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: sw
                          ? 'Uzito wa kuzaliwa (gramu)'
                          : 'Birth weight (grams)',
                      labelStyle:
                          const TextStyle(fontSize: 13, color: _kSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: lengthController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: sw
                          ? 'Urefu wa kuzaliwa (cm)'
                          : 'Birth length (cm)',
                      hintText: sw ? 'Mfano: 50.0' : 'e.g. 50.0',
                      labelStyle:
                          const TextStyle(fontSize: 13, color: _kSecondary),
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final result = await _service.registerBaby(
                            token: _token!,
                            userId: widget.userId,
                            name: nameController.text.trim(),
                            dateOfBirth: birthDate,
                            gender: gender,
                            birthWeightGrams:
                                int.tryParse(weightController.text.trim()),
                            birthLengthCm:
                                double.tryParse(lengthController.text.trim()),
                          );
                          if (result.success) {
                            messenger.showSnackBar(SnackBar(
                                content: Text(sw
                                    ? 'Mtoto amesajiliwa'
                                    : 'Baby registered')));
                            _loadData();
                          } else {
                            messenger.showSnackBar(SnackBar(
                                content: Text(result.message ??
                                    (sw
                                        ? 'Imeshindwa kusajili mtoto'
                                        : 'Failed to register baby'))));
                          }
                        } catch (e) {
                          messenger.showSnackBar(SnackBar(
                              content: Text(sw
                                  ? 'Hitilafu imetokea'
                                  : 'An error occurred')));
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(sw ? 'Sajili' : 'Register',
                          style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Baby list
          if (_babies.isNotEmpty) ...[
            Text(
              sw ? 'Watoto Wangu' : 'My Babies',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
            ),
            const SizedBox(height: 12),
            ..._babies.map((baby) => _BabyCard(
                  baby: baby,
                  isSwahili: sw,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BabyDashboardPage(
                        baby: baby,
                        userId: widget.userId,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) _loadData();
                  }),
                )),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _showRegisterBabyDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(sw
                    ? 'Sajili Mtoto Mwingine'
                    : 'Register Another Baby'),
                style: TextButton.styleFrom(foregroundColor: _kPrimary),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Empty state
          if (_babies.isEmpty) ...[
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.child_friendly_rounded,
                        size: 56, color: _kPrimary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    sw ? 'Mtoto Wangu' : 'My Baby',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      sw
                          ? 'Fuatilia chanjo, kulisha, na maendeleo ya mtoto wako.'
                          : "Track your baby's vaccinations, feeding, and development.",
                      style:
                          const TextStyle(fontSize: 14, color: _kSecondary),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: FilledButton(
                      onPressed: _showRegisterBabyDialog,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        sw ? 'Sajili Mtoto' : 'Register Baby',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ],
      ),
    );
  }
}

// ─── Baby Card ────────────────────────────────────────────────

class _BabyCard extends StatelessWidget {
  final Baby baby;
  final bool isSwahili;
  final VoidCallback onTap;

  const _BabyCard({
    required this.baby,
    required this.isSwahili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    baby.gender == 'male'
                        ? Icons.boy_rounded
                        : baby.gender == 'female'
                            ? Icons.girl_rounded
                            : Icons.child_care_rounded,
                    size: 24,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        baby.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        baby.ageLabelLocalized(isSwahili: isSwahili),
                        style:
                            const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _kSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
