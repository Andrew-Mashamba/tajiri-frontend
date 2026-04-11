// lib/doctor/pages/my_appointments_page.dart
import 'package:flutter/material.dart';
import '../models/doctor_models.dart';
import '../services/doctor_service.dart';
import '../widgets/appointment_card.dart';
import 'consultation_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class MyAppointmentsPage extends StatefulWidget {
  final int userId;
  const MyAppointmentsPage({super.key, required this.userId});
  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DoctorService _service = DoctorService();

  List<Appointment> _upcoming = [];
  List<Appointment> _past = [];
  bool _isLoadingUpcoming = true;
  bool _isLoadingPast = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadUpcoming(), _loadPast()]);
  }

  Future<void> _loadUpcoming() async {
    setState(() => _isLoadingUpcoming = true);
    final result = await _service.getMyAppointments(userId: widget.userId, status: 'upcoming');
    if (mounted) {
      setState(() {
        _isLoadingUpcoming = false;
        if (result.success) _upcoming = result.items;
      });
    }
  }

  Future<void> _loadPast() async {
    setState(() => _isLoadingPast = true);
    final result = await _service.getMyAppointments(userId: widget.userId, status: 'completed');
    if (mounted) {
      setState(() {
        _isLoadingPast = false;
        if (result.success) _past = result.items;
      });
    }
  }

  void _joinConsultation(Appointment appt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConsultationPage(userId: widget.userId, appointment: appt)),
    ).then((_) { if (mounted) _loadAll(); });
  }

  Future<void> _cancelAppointment(Appointment appt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghairi Miadi'),
        content: const Text('Una uhakika unataka kughairi miadi hii?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hapana')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ndiyo, Ghairi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _service.cancelAppointment(appt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.success ? 'Miadi imeghairiwa' : (result.message ?? 'Imeshindwa'))),
        );
        if (result.success) _loadAll();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Miadi Yangu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: 'Ijayo (${_upcoming.length})'),
            Tab(text: 'Iliyopita (${_past.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_upcoming, _isLoadingUpcoming, isUpcoming: true),
          _buildList(_past, _isLoadingPast, isUpcoming: false),
        ],
      ),
    );
  }

  Widget _buildList(List<Appointment> appointments, bool isLoading, {required bool isUpcoming}) {
    if (isLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));

    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'Hakuna miadi ijayo' : 'Hakuna miadi iliyopita',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: isUpcoming ? _loadUpcoming : _loadPast,
      color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appt = appointments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppointmentCard(
              appointment: appt,
              onJoin: appt.canJoin ? () => _joinConsultation(appt) : null,
              onCancel: isUpcoming ? () => _cancelAppointment(appt) : null,
            ),
          );
        },
      ),
    );
  }
}
