// Cross-module hooks for Hair & Nails (calendar events, budget, shop, doctor, Tea, Tajirika).
import 'package:flutter/material.dart';

import '../../doctor/models/doctor_models.dart';
import '../../doctor/pages/find_doctor_page.dart';
import '../../screens/feed/tea_chat_screen.dart';
import '../../screens/shop/shop_screen.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/expenditure_service.dart';
import '../models/hair_nails_models.dart';
import '../pages/hair_nails_partners_page.dart';

/// Optional actions after a successful salon booking.
Future<void> showHairBookingIntegrationsSheet({
  required BuildContext context,
  required int userId,
  required Booking booking,
  required DateTime appointmentLocal,
  String? salonAddress,
  double? salonLat,
  double? salonLng,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFFAFAFA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF666666).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Endelea',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ongeza kwenye kalenda, rekodi matumizi, au nunua bidhaa za nywele.',
              style: TextStyle(fontSize: 13, color: const Color(0xFF666666).withValues(alpha: 0.95)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await _createCalendarEvent(
                    userId: userId,
                    booking: booking,
                    appointmentLocal: appointmentLocal,
                    salonAddress: salonAddress,
                    salonLat: salonLat,
                    salonLng: salonLng,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Tukio limeongezwa kwenye matukio.'
                              : 'Hatukuweza kuongeza tukio. Jaribu tena baadaye.',
                        ),
                        backgroundColor: const Color(0xFF1A1A1A),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.event_rounded, size: 20),
                label: const Text('Weka kwenye matukio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(color: Color(0xFF1A1A1A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await _recordSalonExpenditure(
                    booking: booking,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Matumizi yamerekodiwa kwenye bajeti.'
                              : 'Hatukuweza kurekodi matumizi (hakuna token au mtandao).',
                        ),
                        backgroundColor: const Color(0xFF1A1A1A),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                label: const Text('Rekodi matumizi (bajeti)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(color: Color(0xFF1A1A1A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ShopScreen(
                        currentUserId: userId,
                        initialSearchQuery: 'hair oil shampoo conditioner',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.storefront_outlined, size: 20),
                label: const Text('Fungua Duka — bidhaa za nywele'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> _createCalendarEvent({
  required int userId,
  required Booking booking,
  required DateTime appointmentLocal,
  String? salonAddress,
  double? salonLat,
  double? salonLng,
}) async {
  final svc = EventService();
  final startTime =
      '${appointmentLocal.hour.toString().padLeft(2, '0')}:${appointmentLocal.minute.toString().padLeft(2, '0')}';
  final endDt = appointmentLocal.add(const Duration(hours: 1));
  final endTime =
      '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}';
  final res = await svc.createEvent(
    creatorId: userId,
    name: 'Saluni: ${booking.serviceName}',
    startDate: DateTime(appointmentLocal.year, appointmentLocal.month, appointmentLocal.day),
    description: 'Miadi #${booking.id} — ${booking.salonName}',
    endDate: DateTime(endDt.year, endDt.month, endDt.day),
    startTime: startTime,
    endTime: endTime,
    isAllDay: false,
    locationName: booking.salonName,
    locationAddress: salonAddress,
    latitude: salonLat,
    longitude: salonLng,
    category: 'personal',
    privacy: 'private',
  );
  return res.success;
}

Future<bool> _recordSalonExpenditure({
  required Booking booking,
}) async {
  final token = await AuthService.instance.getValidAccessToken();
  if (token == null || token.isEmpty) return false;
  final rec = await ExpenditureService.recordExpenditure(
    token: token,
    amount: booking.totalAmount,
    category: 'beauty',
    description: 'Saluni: ${booking.serviceName} (${booking.salonName})',
    sourceModule: 'hair_nails',
    referenceId: 'hair_booking_${booking.id}',
    date: booking.dateTime,
  );
  return rec != null;
}

void openFindDermatologist(BuildContext context, {required int userId}) {
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => FindDoctorPage(
        userId: userId,
        initialSpecialty: MedicalSpecialty.dermatology,
      ),
    ),
  );
}

void openTeaHairAssistant(BuildContext context, {HairProfile? profile}) {
  final buf = StringBuffer(
    'Nina maswali kuhusu nywele na saluni katika TAJIRI. Toa ushauri mfupi kulingana na muktadha wa Tanzania. ',
  );
  if (profile != null) {
    buf.write(
      'Profaili: aina ${profile.hairType.displayName}, porosity ${profile.porosity.displayName}, lengo: ${profile.goals.join(", ")}. ',
    );
  }
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => TeaChatScreen(initialMessage: buf.toString()),
    ),
  );
}

void openHairNailsPartners(BuildContext context, {required int userId}) {
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => HairNailsPartnersPage(userId: userId),
    ),
  );
}
