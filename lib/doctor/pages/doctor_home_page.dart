// lib/doctor/pages/doctor_home_page.dart
import 'package:flutter/material.dart';
import '../models/doctor_models.dart';
import '../services/doctor_service.dart';
import '../widgets/doctor_card.dart';
import '../widgets/appointment_card.dart';
import '../widgets/specialty_chip.dart';
import 'find_doctor_page.dart';
import 'doctor_profile_page.dart';
import 'my_appointments_page.dart';
import 'doctor_registration_page.dart';
import 'consultation_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class DoctorHomePage extends StatefulWidget {
  final int userId;
  const DoctorHomePage({super.key, required this.userId});
  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final DoctorService _service = DoctorService();

  List<Doctor> _featuredDoctors = [];
  List<Appointment> _upcomingAppointments = [];
  bool _isLoading = true;
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _service.findDoctors(onlineOnly: true, perPage: 5),
      _service.getMyAppointments(userId: widget.userId, status: 'upcoming'),
      _service.getMyDoctorProfile(widget.userId),
    ]);

    if (mounted) {
      final doctorsResult = results[0] as DoctorListResult<Doctor>;
      final appointmentsResult = results[1] as DoctorListResult<Appointment>;
      final myDoctorResult = results[2] as DoctorResult<Doctor>;

      setState(() {
        _isLoading = false;
        if (doctorsResult.success) _featuredDoctors = doctorsResult.items;
        if (appointmentsResult.success) _upcomingAppointments = appointmentsResult.items;
        _isDoctor = myDoctorResult.success && myDoctorResult.data != null;
      });
    }
  }

  void _openDoctor(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DoctorProfilePage(userId: widget.userId, doctor: doctor)),
    ).then((_) { if (mounted) _loadData(); });
  }

  void _joinConsultation(Appointment appt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationPage(
          userId: widget.userId,
          appointment: appt,
        ),
      ),
    ).then((_) { if (mounted) _loadData(); });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Emergency banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.emergency_rounded, color: Colors.red.shade700, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Emergency? Call 112 or go to the nearest hospital.',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.search_rounded,
                  label: 'Find Doctor',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FindDoctorPage(userId: widget.userId)),
                  ).then((_) { if (mounted) _loadData(); }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.calendar_month_rounded,
                  label: 'My Appointments',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyAppointmentsPage(userId: widget.userId)),
                  ).then((_) { if (mounted) _loadData(); }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: _isDoctor ? Icons.medical_services_rounded : Icons.how_to_reg_rounded,
                  label: _isDoctor ? 'Doctor Account' : 'Register as Doctor',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DoctorRegistrationPage(userId: widget.userId)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Specialties scroll
          const Text(
            'Specialties',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: MedicalSpecialty.values.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SpecialtyChip(
                    specialty: s,
                    isSelected: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FindDoctorPage(
                          userId: widget.userId,
                          initialSpecialty: s,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Upcoming appointments
          if (_upcomingAppointments.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Upcoming Appointments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyAppointmentsPage(userId: widget.userId)),
                  ),
                  child: const Text('All', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._upcomingAppointments.take(3).map((appt) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppointmentCard(
                    appointment: appt,
                    onJoin: appt.canJoin ? () => _joinConsultation(appt) : null,
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Online doctors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Doctors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FindDoctorPage(userId: widget.userId)),
                ),
                child: const Text('View All', style: TextStyle(fontSize: 13, color: _kSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_featuredDoctors.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Icon(Icons.medical_services_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No doctors online right now', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            )
          else
            ..._featuredDoctors.map((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DoctorCard(doctor: doc, onTap: () => _openDoctor(doc)),
                )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
