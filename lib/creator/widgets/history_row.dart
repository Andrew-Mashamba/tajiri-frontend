// History row — a single transaction (tip / gift / super chat / etc.) in
// the source detail or activity screen.

import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/income_source.dart';

class HistoryRowTile extends StatelessWidget {
  final HistoryItem item;
  final bool last;
  final VoidCallback? onActorTap;

  const HistoryRowTile({
    super.key,
    required this.item,
    this.last = false,
    this.onActorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0)),
              ),
            ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(item: item, onTap: onActorTap),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _whoText(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitleText(context),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF666666),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${formatTzsMinorBare(item.netMinor)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _whoText() {
    final username = item.actorUsername;
    if (username == null || username.isEmpty) return '·';
    return '@$username';
  }

  String _subtitleText(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final parts = <String>[];
    if (item.message != null && item.message!.isNotEmpty) {
      parts.add('"${item.message!}"');
    }
    parts.add(_relativeTime(item.occurredAt, isSw: isSw));
    return parts.join(' · ');
  }

  static String _relativeTime(DateTime t, {required bool isSw}) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return isSw ? 'sasa hivi' : 'just now';
    if (diff.inMinutes < 60) {
      return isSw ? 'dakika ${diff.inMinutes} zilizopita' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isSw ? 'saa ${diff.inHours} zilizopita' : '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return isSw ? 'jana' : 'yesterday';
    if (diff.inDays < 7) {
      return isSw ? 'siku ${diff.inDays} zilizopita' : '${diff.inDays}d ago';
    }
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';
  }
}

class _Avatar extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback? onTap;
  const _Avatar({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = (item.actorUsername ?? '?').isNotEmpty
        ? (item.actorUsername!).substring(0, 1).toUpperCase()
        : '?';
    final url = item.actorAvatarUrl;
    final safeUrl = (url != null && url.isNotEmpty) ? ApiConfig.sanitizeUrl(url) : null;
    final widget = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        shape: BoxShape.circle,
        image: safeUrl != null
            ? DecorationImage(
                image: NetworkImage(safeUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: safeUrl != null
          ? null
          : Text(
              initial,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
    );
    if (onTap == null) return widget;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: widget,
      ),
    );
  }
}
