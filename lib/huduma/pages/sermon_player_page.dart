// lib/huduma/pages/sermon_player_page.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/huduma_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class SermonPlayerPage extends StatefulWidget {
  final Sermon sermon;
  const SermonPlayerPage({super.key, required this.sermon});
  @override
  State<SermonPlayerPage> createState() => _SermonPlayerPageState();
}

class _SermonPlayerPageState extends State<SermonPlayerPage> {
  bool _isPlaying = false;
  double _progress = 0.0;
  double _speed = 1.0;

  @override
  Widget build(BuildContext context) {
    final s = widget.sermon;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 22),
            onPressed: () {
              final text = '${s.title} - ${s.speakerName}';
              SharePlus.instance.share(ShareParams(text: text));
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 22),
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Download coming soon')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            // Speaker avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  s.speakerPhoto != null ? NetworkImage(s.speakerPhoto!) : null,
              child: s.speakerPhoto == null
                  ? const Icon(Icons.person_rounded, size: 40, color: _kSecondary)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(s.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
                textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(s.speakerName,
                style: const TextStyle(fontSize: 15, color: _kSecondary)),
            if (s.scriptureRef != null) ...[
              const SizedBox(height: 4),
              Text(s.scriptureRef!,
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: _kSecondary)),
            ],
            const SizedBox(height: 8),
            Text(s.date,
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
            const Spacer(),

            // Progress
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _progress,
                activeColor: _kPrimary,
                inactiveColor: Colors.grey.shade300,
                onChanged: (v) => setState(() => _progress = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration((_progress * s.durationSeconds).round()),
                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  Text(s.durationFormatted,
                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Speed
                GestureDetector(
                  onTap: _toggleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${_speed}x',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  ),
                ),
                const SizedBox(width: 20),
                // Rewind
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, size: 32, color: _kPrimary),
                  onPressed: () => setState(() => _progress = (_progress - 0.05).clamp(0.0, 1.0)),
                ),
                const SizedBox(width: 8),
                // Play/Pause
                GestureDetector(
                  onTap: () => setState(() => _isPlaying = !_isPlaying),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Forward
                IconButton(
                  icon: const Icon(Icons.forward_30_rounded, size: 32, color: _kPrimary),
                  onPressed: () => setState(() => _progress = (_progress + 0.05).clamp(0.0, 1.0)),
                ),
                const SizedBox(width: 20),
                // Bookmark
                IconButton(
                  icon: const Icon(Icons.bookmark_border_rounded, size: 28, color: _kPrimary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sermon bookmarked')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _toggleSpeed() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final idx = speeds.indexOf(_speed);
    setState(() => _speed = speeds[(idx + 1) % speeds.length]);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}
