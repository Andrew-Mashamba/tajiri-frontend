// lib/events/pages/event_calendar_page.dart
import 'package:flutter/material.dart';
import '../models/event_strings.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventCalendarPage extends StatelessWidget {
  final int userId;

  const EventCalendarPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: Localizations.localeOf(context).languageCode == 'sw');

    return Scaffold(
      backgroundColor: _kBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 40,
                  color: _kSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.isSwahili ? 'Mwonekano wa Kalenda' : 'Calendar View',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.isSwahili
                    ? 'Kipengele hiki kinakuja hivi karibuni'
                    : 'Calendar view coming soon',
                style: const TextStyle(
                  fontSize: 14,
                  color: _kSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(strings.back),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
