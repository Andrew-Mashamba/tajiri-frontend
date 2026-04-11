// lib/doctor/pages/find_doctor_page.dart
import 'package:flutter/material.dart';
import '../models/doctor_models.dart';
import '../services/doctor_service.dart';
import '../widgets/doctor_card.dart';
import '../widgets/specialty_chip.dart';
import 'doctor_profile_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FindDoctorPage extends StatefulWidget {
  final int userId;
  final MedicalSpecialty? initialSpecialty;
  const FindDoctorPage({super.key, required this.userId, this.initialSpecialty});
  @override
  State<FindDoctorPage> createState() => _FindDoctorPageState();
}

class _FindDoctorPageState extends State<FindDoctorPage> {
  final DoctorService _service = DoctorService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Doctor> _doctors = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  MedicalSpecialty? _selectedSpecialty;
  bool _onlineOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedSpecialty = widget.initialSpecialty;
    _scrollController.addListener(_onScroll);
    _loadDoctors();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7) {
      _loadMore();
    }
  }

  Future<void> _loadDoctors() async {
    setState(() { _isLoading = true; _page = 1; });

    final result = await _service.findDoctors(
      specialty: _selectedSpecialty?.name,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      onlineOnly: _onlineOnly ? true : null,
      page: 1,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _doctors = result.items;
          _hasMore = result.items.length >= 20;
          _page = 2;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final result = await _service.findDoctors(
      specialty: _selectedSpecialty?.name,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      onlineOnly: _onlineOnly ? true : null,
      page: _page,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _doctors.addAll(result.items);
          _hasMore = result.items.length >= 20;
          _page++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Tafuta Daktari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadDoctors(),
              decoration: InputDecoration(
                hintText: 'Tafuta kwa jina au hospitali...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _kSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchController.clear(); _loadDoctors(); },
                      )
                    : null,
                filled: true, fillColor: _kCardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filters: specialties scroll + online toggle
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Online toggle
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
                        SizedBox(width: 4),
                        Text('Mtandaoni', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    selected: _onlineOnly,
                    selectedColor: _kPrimary.withValues(alpha: 0.15),
                    onSelected: (v) { setState(() => _onlineOnly = v); _loadDoctors(); },
                  ),
                ),
                // All specialties
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SpecialtyChip(
                    specialty: MedicalSpecialty.generalPractice,
                    isSelected: _selectedSpecialty == null,
                    onTap: () { setState(() => _selectedSpecialty = null); _loadDoctors(); },
                  ),
                ),
                ...MedicalSpecialty.values.where((s) => s != MedicalSpecialty.generalPractice).map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SpecialtyChip(
                      specialty: s,
                      isSelected: _selectedSpecialty == s,
                      onTap: () {
                        setState(() => _selectedSpecialty = _selectedSpecialty == s ? null : s);
                        _loadDoctors();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _doctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Hakuna daktari aliyepatikana', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDoctors,
                        color: _kPrimary,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _doctors.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _doctors.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: DoctorCard(
                                doctor: _doctors[index],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DoctorProfilePage(
                                      userId: widget.userId,
                                      doctor: _doctors[index],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
