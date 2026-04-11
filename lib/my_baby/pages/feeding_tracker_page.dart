// lib/my_baby/pages/feeding_tracker_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FeedingTrackerPage extends StatefulWidget {
  final Baby baby;
  final FeedingType? initialType;
  final BreastSide? initialSide;

  const FeedingTrackerPage({
    super.key,
    required this.baby,
    this.initialType,
    this.initialSide,
  });

  @override
  State<FeedingTrackerPage> createState() => _FeedingTrackerPageState();
}

class _FeedingTrackerPageState extends State<FeedingTrackerPage> {
  final MyBabyService _service = MyBabyService();
  String? _token;
  int? _currentUserId;

  // Tab state
  late FeedingType _selectedType;

  // Breastfeeding timer
  late BreastSide _selectedSide;
  bool _isTimerRunning = false;
  int _timerSeconds = 0;
  Timer? _timer;

  // Bottle
  final _amountController = TextEditingController();

  // Solid
  final _foodController = TextEditingController();

  // History
  List<FeedingLog> _history = [];
  bool _isLoadingHistory = true;
  bool _isSaving = false;

  // Selected date
  DateTime _selectedDate = DateTime.now();

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? FeedingType.breast;
    _selectedSide = widget.initialSide ?? BreastSide.left;
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _currentUserId = LocalStorageService.instanceSync?.getUser()?.userId;
    _loadHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amountController.dispose();
    _foodController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoadingHistory = false);
      return;
    }
    setState(() => _isLoadingHistory = true);
    final result =
        await _service.getFeedingHistory(_token!, widget.baby.id, _selectedDate);
    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
        if (result.success) _history = result.items;
      });
    }
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      _timerSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _timerSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  Future<void> _saveBreastFeeding() async {
    if (_token == null) return;
    final sw = _sw;
    if (_timerSeconds < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sw ? 'Anza timer kwanza' : 'Start the timer first')),
      );
      return;
    }
    _stopTimer();
    setState(() => _isSaving = true);

    final durationMinutes = (_timerSeconds / 60).ceil();
    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.logFeeding(
      token: _token!,
      babyId: widget.baby.id,
      type: FeedingType.breast,
      side: _selectedSide,
      durationMinutes: durationMinutes,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _timerSeconds = 0;
      });
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Kunyonyesha kumehifadhiwa' : 'Breastfeeding saved')),
        );
        _loadHistory();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ?? (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    }
  }

  Future<void> _saveBottleFeeding() async {
    if (_token == null) return;
    final sw = _sw;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sw ? 'Weka kiasi cha maziwa (ml)' : 'Enter milk amount (ml)')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.logFeeding(
      token: _token!,
      babyId: widget.baby.id,
      type: FeedingType.bottle,
      amountMl: amount,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        _amountController.clear();
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Chupa imehifadhiwa' : 'Bottle feeding saved')),
        );
        _loadHistory();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ?? (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    }
  }

  Future<void> _saveSolidFeeding() async {
    if (_token == null) return;
    final sw = _sw;
    final food = _foodController.text.trim();
    if (food.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sw ? 'Andika aina ya chakula' : 'Enter food type')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.logFeeding(
      token: _token!,
      babyId: widget.baby.id,
      type: FeedingType.solid,
      foodDescription: food,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        _foodController.clear();
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Chakula kimehifadhiwa' : 'Solid food saved')),
        );
        _loadHistory();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ?? (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    }
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final canShowSolids = widget.baby.ageInMonths >= 6;
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Kufuatilia Kulisha' : 'Feeding Tracker',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Type selector
          Row(
            children: [
              _TypeTab(
                label: sw ? 'Kunyonyesha' : 'Breastfeeding',
                icon: Icons.woman_rounded,
                isSelected: _selectedType == FeedingType.breast,
                onTap: () =>
                    setState(() => _selectedType = FeedingType.breast),
              ),
              const SizedBox(width: 8),
              _TypeTab(
                label: sw ? 'Chupa' : 'Bottle',
                icon: Icons.local_drink_rounded,
                isSelected: _selectedType == FeedingType.bottle,
                onTap: () =>
                    setState(() => _selectedType = FeedingType.bottle),
              ),
              if (canShowSolids) ...[
                const SizedBox(width: 8),
                _TypeTab(
                  label: sw ? 'Chakula' : 'Solid Food',
                  icon: Icons.restaurant_rounded,
                  isSelected: _selectedType == FeedingType.solid,
                  onTap: () =>
                      setState(() => _selectedType = FeedingType.solid),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Input area based on type
          if (_selectedType == FeedingType.breast) _buildBreastfeedingInput(sw),
          if (_selectedType == FeedingType.bottle) _buildBottleInput(sw),
          if (_selectedType == FeedingType.solid) _buildSolidInput(sw),

          const SizedBox(height: 24),

          // Date selector for history
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sw ? 'Historia ya Kulisha' : 'Feeding History',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary),
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: widget.baby.dateOfBirth,
                    lastDate: DateTime.now(),
                    helpText: sw ? 'Chagua tarehe' : 'Select date',
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    _loadHistory();
                  }
                },
                child: Row(
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(
                          fontSize: 13, color: _kSecondary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: _kSecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // History list
          if (_isLoadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary),
              ),
            )
          else if (_history.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.restaurant_rounded,
                      size: 36, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    sw ? 'Hakuna rekodi kwa tarehe hii' : 'No records for this date',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            ..._history.map((f) => _HistoryItem(
                  feeding: f,
                  isSwahili: sw,
                  currentUserId: _currentUserId,
                )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBreastfeedingInput(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Side selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text(sw ? 'Kushoto' : 'Left'),
                selected: _selectedSide == BreastSide.left,
                onSelected: (v) {
                  if (v) setState(() => _selectedSide = BreastSide.left);
                },
                selectedColor: _kPrimary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: _selectedSide == BreastSide.left
                      ? _kPrimary
                      : _kSecondary,
                  fontWeight: _selectedSide == BreastSide.left
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: Text(sw ? 'Kulia' : 'Right'),
                selected: _selectedSide == BreastSide.right,
                onSelected: (v) {
                  if (v) setState(() => _selectedSide = BreastSide.right);
                },
                selectedColor: _kPrimary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: _selectedSide == BreastSide.right
                      ? _kPrimary
                      : _kSecondary,
                  fontWeight: _selectedSide == BreastSide.right
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Timer display
          Text(
            _formatTimer(_timerSeconds),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: _isTimerRunning ? _kPrimary : _kSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Timer buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isTimerRunning)
                SizedBox(
                  width: 140,
                  height: 48,
                  child: FilledButton(
                    onPressed: _startTimer,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(sw ? 'Anza' : 'Start',
                        style: const TextStyle(fontSize: 15)),
                  ),
                ),
              if (_isTimerRunning) ...[
                SizedBox(
                  width: 120,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _stopTimer,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(sw ? 'Simama' : 'Stop',
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveBreastFeeding,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(sw ? 'Hifadhi' : 'Save',
                            style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ],
          ),
          if (_timerSeconds > 0 && !_isTimerRunning) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveBreastFeeding,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottleInput(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Kiasi cha Maziwa' : 'Milk Amount',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: sw ? 'Mfano: 120' : 'e.g. 120',
              suffixText: 'ml',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          // Quick amount buttons
          Wrap(
            spacing: 8,
            children: [30, 60, 90, 120, 150, 180].map((ml) {
              return ActionChip(
                label: Text('$ml ml'),
                onPressed: () => _amountController.text = '$ml',
                labelStyle:
                    const TextStyle(fontSize: 12, color: _kPrimary),
                side: BorderSide(color: Colors.grey.shade300),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveBottleFeeding,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(sw ? 'Hifadhi' : 'Save',
                      style: const TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolidInput(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Aina ya Chakula' : 'Food Type',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _foodController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: sw
                  ? 'Mfano: Uji wa mtama, matunda ya ndizi...'
                  : 'e.g. Millet porridge, banana...',
              hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          // Quick food buttons
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: (sw
                    ? ['Uji', 'Ndizi', 'Avokado', 'Viazi', 'Maharagwe', 'Mboga']
                    : ['Porridge', 'Banana', 'Avocado', 'Potato', 'Beans', 'Vegetables'])
                .map((food) {
              return ActionChip(
                label: Text(food),
                onPressed: () {
                  final current = _foodController.text.trim();
                  _foodController.text =
                      current.isEmpty ? food : '$current, $food';
                },
                labelStyle:
                    const TextStyle(fontSize: 12, color: _kPrimary),
                side: BorderSide(color: Colors.grey.shade300),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveSolidFeeding,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(sw ? 'Hifadhi' : 'Save',
                      style: const TextStyle(fontSize: 15)),
            ),
          ),
          if (widget.baby.ageInMonths < 6) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded,
                      size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sw
                          ? 'WHO inapendekeza kunyonyesha peke yake kwa miezi 6 ya kwanza.'
                          : 'WHO recommends exclusive breastfeeding for the first 6 months.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? _kPrimary : _kCardBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon,
                    size: 22,
                    color: isSelected ? Colors.white : _kSecondary),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _kSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final FeedingLog feeding;
  final bool isSwahili;
  final int? currentUserId;

  const _HistoryItem({
    required this.feeding,
    required this.isSwahili,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    String details = '';
    if (feeding.type == FeedingType.breast) {
      final side = feeding.side?.localizedName(isSwahili: isSwahili) ?? '';
      final dur = feeding.durationMinutes ?? 0;
      details = isSwahili ? '$side - Dakika $dur' : '$side - $dur min';
    } else if (feeding.type == FeedingType.bottle) {
      details = '${feeding.amountMl?.toStringAsFixed(0) ?? '0'} ml';
    } else if (feeding.type == FeedingType.solid) {
      details = feeding.foodDescription ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPrimary.withValues(alpha: 0.08),
            ),
            child: Icon(
              feeding.type == FeedingType.breast
                  ? Icons.woman_rounded
                  : feeding.type == FeedingType.bottle
                      ? Icons.local_drink_rounded
                      : Icons.restaurant_rounded,
              size: 18,
              color: _kPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feeding.type.localizedName(isSwahili: isSwahili),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // Caregiver attribution
                if (feeding.loggedBy != null &&
                    currentUserId != null &&
                    feeding.loggedBy != currentUserId)
                  Text(
                    isSwahili ? 'na Mlezi' : 'by Caregiver',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${feeding.date.hour.toString().padLeft(2, '0')}:${feeding.date.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kSecondary),
          ),
        ],
      ),
    );
  }
}
