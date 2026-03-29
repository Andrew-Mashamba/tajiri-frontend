import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../l10n/app_strings_scope.dart';
import '../services/local_storage_service.dart';

/// Horizontal scrolling bar of trending hashtags.
/// Tap a hashtag to insert it into the content field.
class TrendingHashtagsBar extends StatefulWidget {
  final Function(String hashtag) onHashtagTap;

  const TrendingHashtagsBar({super.key, required this.onHashtagTap});

  @override
  State<TrendingHashtagsBar> createState() => _TrendingHashtagsBarState();
}

class _TrendingHashtagsBarState extends State<TrendingHashtagsBar> {
  List<String> _hashtags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/hashtags/trending?limit=15'),
            headers: token != null
                ? ApiConfig.authHeaders(token)
                : ApiConfig.headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final List<dynamic> rawTags =
            data['data'] is List ? data['data'] : [];
        setState(() {
          _hashtags = rawTags
              .map((t) {
                if (t is Map) {
                  return t['name']?.toString() ??
                      t['tag']?.toString() ??
                      '';
                }
                return t.toString();
              })
              .where((t) => t.isNotEmpty)
              .toList();
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _hashtags.isEmpty) return const SizedBox.shrink();

    final strings = AppStringsScope.of(context);
    final isSw = strings?.isSwahili ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 4),
              Text(
                isSw ? 'Zinazovuma' : 'Trending',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _hashtags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => widget.onHashtagTap(_hashtags[index]),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    '#${_hashtags[index]}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
