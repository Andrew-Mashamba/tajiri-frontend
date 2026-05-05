// CoverUploadOverlay — inline progress + cancel + retry rendered on the
// cover canvas during upload. Replaces the SnackBar pattern per playbook.
// Spec: docs/superpowers/specs/2026-05-02-cover-photo-upload-design.md §3 (step 5)

import 'package:flutter/material.dart';
import '../../../l10n/app_strings_scope.dart';

/// State the overlay can be in.
enum CoverUploadState { idle, uploading, error }

class CoverUploadOverlay extends StatelessWidget {
  final CoverUploadState state;

  /// 0.0..1.0 — drives the progress bar when [state] is uploading.
  final double progress;

  /// User-facing message (already localized) shown in the error state.
  final String? errorMessage;

  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  const CoverUploadOverlay({
    super.key,
    required this.state,
    this.progress = 0,
    this.errorMessage,
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (state == CoverUploadState.idle) return const SizedBox.shrink();
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x99000000), // 60% black scrim
        child: Center(
          child: state == CoverUploadState.uploading
              ? _UploadingBody(
                  progress: progress,
                  isSw: isSw,
                  onCancel: onCancel,
                )
              : _ErrorBody(
                  errorMessage: errorMessage,
                  isSw: isSw,
                  onRetry: onRetry,
                  onCancel: onCancel,
                ),
        ),
      ),
    );
  }
}

class _UploadingBody extends StatelessWidget {
  final double progress;
  final bool isSw;
  final VoidCallback? onCancel;
  const _UploadingBody({
    required this.progress,
    required this.isSw,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSw ? 'Inapakia… $pct%' : 'Uploading… $pct%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0x33FFFFFF),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFAFAFA)),
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 36,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFAFAFA),
                ),
                child: Text(
                  isSw ? 'Ghairi' : 'Cancel',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String? errorMessage;
  final bool isSw;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const _ErrorBody({
    required this.errorMessage,
    required this.isSw,
    this.onRetry,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          border: Border.all(color: const Color(0xFFEF9A9A)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: Color(0xFFC62828),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage ??
                        (isSw
                            ? 'Imeshindwa kupakia. Jaribu tena.'
                            : 'Upload failed. Try again.'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B0000),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8B0000),
                      minimumSize: const Size(64, 36),
                    ),
                    child: Text(
                      isSw ? 'Ghairi' : 'Cancel',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 4),
                if (onRetry != null)
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isSw ? 'Jaribu tena' : 'Retry',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
