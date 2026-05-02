// Accelerator row — single suggestion that helps the creator unlock a
// locked source faster. Spec §5 (accelerators) and §11 (deeplink target).

import 'package:flutter/material.dart';
import '../models/income_source.dart';

class AcceleratorRow extends StatelessWidget {
  final Accelerator accelerator;
  final VoidCallback? onTap;

  const AcceleratorRow({
    super.key,
    required this.accelerator,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IconBubble(icon: accelerator.icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        accelerator.title.forContext(context),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (accelerator.subtitle.forContext(context).isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          accelerator.subtitle.forContext(context),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF666666),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFF666666),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final String? icon;
  const _IconBubble({this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E5E5),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        icon ?? '·',
        style: const TextStyle(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
