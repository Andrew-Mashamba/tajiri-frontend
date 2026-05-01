import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec F6 #31 — Multi-staff group-booking cart for hair_nails. The customer
/// declares N participants, each with their own service and (optionally)
/// preferred staff member. Backend creates a multi_staff_bookings row + child
/// participant entries, blocking a single shared time slot.
class _Participant {
  final TextEditingController nameCtrl;
  final TextEditingController serviceIdCtrl;
  final TextEditingController staffIdCtrl;
  _Participant()
      : nameCtrl = TextEditingController(),
        serviceIdCtrl = TextEditingController(),
        staffIdCtrl = TextEditingController();
  void dispose() {
    nameCtrl.dispose();
    serviceIdCtrl.dispose();
    staffIdCtrl.dispose();
  }
}

Future<int?> showGroupBookingSheet({
  required BuildContext context,
  required int customerUserId,
}) async {
  final partnerCtrl = TextEditingController();
  final minutesCtrl = TextEditingController(text: '60');
  DateTime? blockStartsAt;
  final participants = <_Participant>[_Participant(), _Participant()];

  final cartId = await showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    builder: (sCtx) => StatefulBuilder(
      builder: (b, setS) {
        Future<void> pickStart() async {
          final now = DateTime.now();
          final pickedDate = await showDatePicker(
            context: sCtx,
            initialDate: now.add(const Duration(days: 1)),
            firstDate: now,
            lastDate: now.add(const Duration(days: 60)),
          );
          if (pickedDate == null) return;
          final pickedTime = await showTimePicker(
            context: sCtx,
            initialTime: const TimeOfDay(hour: 10, minute: 0),
          );
          if (pickedTime == null) return;
          setS(() => blockStartsAt = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              ));
        }

        final isSw = AppStringsScope.of(sCtx)?.isSwahili ?? false;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(sCtx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isSw ? 'Booking ya kikundi' : 'Group booking',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  isSw
                      ? 'Wateja kadhaa, slot moja, salon moja.'
                      : 'Multiple people, one shared salon slot.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: partnerCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: isSw ? 'Salon partner_id' : 'Salon partner_id',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_rounded, size: 16),
                  label: Text(blockStartsAt == null
                      ? (isSw ? 'Chagua tarehe na muda' : 'Pick date & time')
                      : '${blockStartsAt!.toLocal()}'.split('.').first),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: pickStart,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minutesCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: isSw
                        ? 'Muda wa block (dakika)'
                        : 'Block duration (minutes)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSw ? 'Washiriki' : 'Participants',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                for (int i = 0; i < participants.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      border: Border.all(color: _kBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('${i + 1}.',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: participants[i].nameCtrl,
                                decoration: InputDecoration(
                                  labelText: isSw ? 'Jina' : 'Name',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (participants.length > 2)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => setS(() {
                                  participants[i].dispose();
                                  participants.removeAt(i);
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: participants[i].serviceIdCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: InputDecoration(
                                  labelText:
                                      isSw ? 'service_id' : 'service_id',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: participants[i].staffIdCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: InputDecoration(
                                  labelText: isSw
                                      ? 'staff_id (hiari)'
                                      : 'staff_id (optional)',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label:
                      Text(isSw ? 'Ongeza mshiriki' : 'Add participant'),
                  onPressed: () =>
                      setS(() => participants.add(_Participant())),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: _kPrimary),
                  onPressed: () async {
                    final partnerId = int.tryParse(partnerCtrl.text.trim());
                    final minutes = int.tryParse(minutesCtrl.text.trim());
                    if (partnerId == null ||
                        minutes == null ||
                        blockStartsAt == null) {
                      ScaffoldMessenger.of(sCtx).showSnackBar(SnackBar(
                          content: Text(isSw
                              ? 'Jaza taarifa zote'
                              : 'Fill in all fields')));
                      return;
                    }
                    final entries = participants
                        .map((p) {
                          final svc = int.tryParse(p.serviceIdCtrl.text.trim());
                          if (p.nameCtrl.text.trim().isEmpty || svc == null) {
                            return null;
                          }
                          final staff =
                              int.tryParse(p.staffIdCtrl.text.trim());
                          return <String, dynamic>{
                            'name': p.nameCtrl.text.trim(),
                            'service_id': svc,
                            if (staff != null) 'staff_id': staff,
                          };
                        })
                        .whereType<Map<String, dynamic>>()
                        .toList();
                    if (entries.length < 2) {
                      ScaffoldMessenger.of(sCtx).showSnackBar(SnackBar(
                          content: Text(isSw
                              ? 'Washiriki angalau 2'
                              : 'At least 2 participants')));
                      return;
                    }
                    final id = await MultiStaffCartService.create(
                      cartOwnerUserId: customerUserId,
                      partnerId: partnerId,
                      participants: entries,
                      blockStartsAt: blockStartsAt!,
                      blockMinutes: minutes,
                    );
                    if (!sCtx.mounted) return;
                    Navigator.pop(sCtx, id);
                  },
                  child:
                      Text(isSw ? 'Tuma ombi' : 'Submit group booking'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  partnerCtrl.dispose();
  minutesCtrl.dispose();
  for (final p in participants) {
    p.dispose();
  }
  return cartId;
}
