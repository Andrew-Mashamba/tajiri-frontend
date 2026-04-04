import 'package:http/http.dart' as http;

class LinkPreviewService {
  static final Map<String, LinkPreviewData?> _cache = {};

  static Future<LinkPreviewData?> fetchPreview(String url) async {
    if (_cache.containsKey(url)) return _cache[url];
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return null;
      final body = resp.body;
      final title = _extractMeta(body, 'og:title') ?? _extractTitle(body);
      final description = _extractMeta(body, 'og:description');
      final image = _extractMeta(body, 'og:image');
      final domain = Uri.parse(url).host;
      final preview = LinkPreviewData(url: url, title: title, description: description, image: image, domain: domain);
      _cache[url] = preview;
      return preview;
    } catch (_) {
      _cache[url] = null;
      return null;
    }
  }

  static String? _extractMeta(String html, String property) {
    final regex = RegExp('<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']+)["\']', caseSensitive: false);
    final match = regex.firstMatch(html);
    if (match != null) return match.group(1);
    final regex2 = RegExp('<meta[^>]+name=["\']$property["\'][^>]+content=["\']([^"\']+)["\']', caseSensitive: false);
    return regex2.firstMatch(html)?.group(1);
  }

  static String? _extractTitle(String html) {
    final regex = RegExp('<title>([^<]+)</title>', caseSensitive: false);
    return regex.firstMatch(html)?.group(1)?.trim();
  }
}

class LinkPreviewData {
  final String url;
  final String? title;
  final String? description;
  final String? image;
  final String? domain;
  const LinkPreviewData({required this.url, this.title, this.description, this.image, this.domain});

  Map<String, dynamic> toJson() => {
    'url': url, 'title': title, 'description': description, 'image': image, 'domain': domain,
  };
}
