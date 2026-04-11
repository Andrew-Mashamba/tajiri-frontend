// lib/career/pages/career_home_page.dart
import 'package:flutter/material.dart';
import '../models/career_models.dart';
import '../services/career_service.dart';
import 'job_detail_page.dart';
import 'applications_page.dart';
import 'cv_builder_page.dart';
import '../widgets/job_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CareerHomePage extends StatefulWidget {
  final int userId;
  const CareerHomePage({super.key, required this.userId});
  @override
  State<CareerHomePage> createState() => _CareerHomePageState();
}

class _CareerHomePageState extends State<CareerHomePage> {
  final CareerService _service = CareerService();
  List<JobListing> _jobs = [];
  bool _isLoading = true;
  JobType? _selectedType;
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    final result = await _service.getJobs(
      type: _selectedType?.name,
      search: _searchC.text.trim().isEmpty ? null : _searchC.text.trim(),
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _jobs = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadJobs,
          color: _kPrimary,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.work_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text('Kazi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
                SizedBox(height: 6),
                Text('Career — jobs, internships & CV builder', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),
            // Quick actions
            Row(children: [
              _action(Icons.description_rounded, 'CV Builder', () => Navigator.push(context, MaterialPageRoute(builder: (_) => CvBuilderPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              _action(Icons.track_changes_rounded, 'Maombi', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicationsPage(userId: widget.userId)))),
            ]),
            const SizedBox(height: 16),
            // Search
            TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: 'Tafuta kazi, kampuni...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
              onSubmitted: (_) => _loadJobs(),
            ),
            const SizedBox(height: 12),
            // Type filter
            SizedBox(
              height: 36,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                  label: const Text('Zote', style: TextStyle(fontSize: 12)),
                  selected: _selectedType == null, selectedColor: _kPrimary,
                  labelStyle: TextStyle(color: _selectedType == null ? Colors.white : _kPrimary),
                  onSelected: (_) { setState(() => _selectedType = null); _loadJobs(); },
                )),
                ...JobType.values.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t.displayName, style: const TextStyle(fontSize: 12)),
                    selected: _selectedType == t, selectedColor: _kPrimary,
                    labelStyle: TextStyle(color: _selectedType == t ? Colors.white : _kPrimary),
                    onSelected: (_) { setState(() => _selectedType = t); _loadJobs(); },
                  ),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
            else if (_jobs.isEmpty)
              Container(padding: const EdgeInsets.all(48), alignment: Alignment.center, child: const Column(children: [
                Icon(Icons.work_off_rounded, size: 48, color: _kSecondary),
                SizedBox(height: 8),
                Text('Hakuna kazi kwa sasa', style: TextStyle(color: _kSecondary)),
                Text('No job listings found', style: TextStyle(color: _kSecondary, fontSize: 12)),
              ]))
            else
              ..._jobs.map((j) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: JobCard(job: j, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailPage(job: j, userId: widget.userId)))),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Icon(icon, size: 20, color: _kPrimary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary)),
        ]),
      ),
    ));
  }
}
