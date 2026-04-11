// lib/newton/widgets/newton_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/newton_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NewtonBubble extends StatelessWidget {
  final NewtonMessage message;
  final VoidCallback? onBookmark;
  final VoidCallback? onFlag;
  final bool isSwahili;

  const NewtonBubble({
    super.key,
    required this.message,
    this.onBookmark,
    this.onFlag,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? Radius.zero : null,
            bottomLeft: !isUser ? Radius.zero : null,
          ),
          border: isUser ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Newton header
            if (!isUser) ...[
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Newton',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const Spacer(),
                  if (message.isBookmarked)
                    Icon(Icons.bookmark_rounded,
                        size: 14, color: Colors.amber.shade700),
                  if (message.isFlagged)
                    const Icon(Icons.flag_rounded,
                        size: 14, color: Colors.red),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Image preview
            if (message.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => Container(
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image_rounded,
                          color: _kSecondary, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Message content
            SelectableText(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : _kPrimary,
                height: 1.5,
              ),
            ),

            // Action buttons for AI messages
            if (!isUser) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Copy
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    tooltip: isSwahili ? 'Nakili' : 'Copy',
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: message.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isSwahili
                              ? 'Imenakiliwa'
                              : 'Copied to clipboard'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // Bookmark
                  if (onBookmark != null)
                    _ActionButton(
                      icon: message.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      tooltip: isSwahili ? 'Hifadhi' : 'Bookmark',
                      onTap: onBookmark!,
                    ),
                  const SizedBox(width: 4),
                  // Flag
                  if (onFlag != null)
                    _ActionButton(
                      icon: message.isFlagged
                          ? Icons.flag_rounded
                          : Icons.flag_outlined,
                      tooltip: isSwahili ? 'Ripoti' : 'Report',
                      color: message.isFlagged ? Colors.red : null,
                      onTap: onFlag!,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color ?? _kSecondary),
        ),
      ),
    );
  }
}
