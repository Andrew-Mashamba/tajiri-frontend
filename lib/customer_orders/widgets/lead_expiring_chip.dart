import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

/// F3 #17 — countdown chip for quote-bid sources.
/// Shows when minutes_left > 0 and status is pending.
class LeadExpiringChip extends StatelessWidget {
  final int? minutesLeft;
  final int? competitorCount;
  final bool isSwahili;

  const LeadExpiringChip({
    super.key,
    this.minutesLeft,
    this.competitorCount,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    final mins = minutesLeft;
    if (mins == null || mins <= 0) return const SizedBox.shrink();
    final comp = competitorCount ?? 0;
    final urgent = mins <= 10;
    final bg = urgent ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1);
    final fg = urgent ? const Color(0xFFB71C1C) : const Color(0xFFE65100);
    final label = isSwahili
        ? 'Muda unaisha: ${mins}m${comp > 0 ? ' · Washindani $comp' : ''}'
        : 'Expiring: ${mins}m${comp > 0 ? ' · $comp competitors' : ''}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Lightweight inline fetch for lead-expiring data on vertical detail pages.
class LeadExpiringChipFetcher extends StatelessWidget {
  final int orderId;
  final String sourceApiValue;
  final bool isSwahili;

  const LeadExpiringChipFetcher({
    super.key,
    required this.orderId,
    required this.sourceApiValue,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetch(),
      builder: (_, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        final mins = (data['minutes_left'] as num?)?.toInt();
        final comp = (data['competitor_count'] as num?)?.toInt();
        return LeadExpiringChip(
          minutesLeft: mins,
          competitorCount: comp,
          isSwahili: isSwahili,
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetch() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/partner-inbox/lead-expiring')
          .replace(queryParameters: {
        'source': sourceApiValue,
        'id': '$orderId',
      });
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          return (body['data'] as Map).cast<String, dynamic>();
        }
      }
    } catch (_) {}
    return null;
  }
}
