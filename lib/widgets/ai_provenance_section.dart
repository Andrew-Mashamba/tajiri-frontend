// lib/widgets/ai_provenance_section.dart
//
// UW-005 / posts.md §XII (rows 89-92). Reusable AI-declaration block —
// drop into any composer screen so creators can disclose AI use. The
// composer is responsible for calling `PostService.declareAiProvenance`
// after post creation when `declaredAiUsed=true`.
//
// Engineering playbook: monochrome (#1A1A1A primary), 48dp targets,
// _rounded icons, AppStringsScope bilingual, maxLines+ellipsis.

import 'package:flutter/material.dart';

import '../l10n/app_strings_scope.dart';

class AiProvenanceSection extends StatelessWidget {
  final bool declaredAiUsed;
  final String? aiModelUsed;

  /// Called when the toggle flips. Pass `false` to clear the model selection.
  final ValueChanged<bool> onDeclaredChanged;

  /// Called when a model chip is tapped. `null` = deselected.
  final ValueChanged<String?> onModelChanged;

  /// Default model options. The image composer used Midjourney / DALL-E /
  /// Stable Diffusion / Other; audio composers can override with TTS / dub
  /// providers etc.
  final List<String> models;

  const AiProvenanceSection({
    super.key,
    required this.declaredAiUsed,
    required this.aiModelUsed,
    required this.onDeclaredChanged,
    required this.onModelChanged,
    this.models = const ['Midjourney', 'DALL-E', 'Stable Diffusion', 'Other'],
  });

  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kTertiary = Color(0xFF999999);
  static const _kBorder = Color(0xFFE5E5E5);

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSw ? 'Imeundwa kwa AI' : 'AI-generated content',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
              Switch(
                value: declaredAiUsed,
                activeThumbColor: _kPrimary,
                onChanged: (v) {
                  onDeclaredChanged(v);
                  if (!v) onModelChanged(null);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isSw
                ? 'Tangaza ikiwa AI imetumika. Uadilifu unajenga uaminifu.'
                : 'Disclose if AI generated or modified this content. Honest disclosure builds trust.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          if (declaredAiUsed) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: models.map((m) {
                final selected = aiModelUsed == m;
                return InkWell(
                  onTap: () => onModelChanged(selected ? null : m),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? _kPrimary : _kBorder),
                    ),
                    child: Text(
                      m,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : _kPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (declaredAiUsed && aiModelUsed == null) ...[
            const SizedBox(height: 6),
            Text(
              isSw ? 'Chagua mtindo (hiari).' : 'Pick the model used (optional).',
              style: const TextStyle(fontSize: 11, color: _kTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
