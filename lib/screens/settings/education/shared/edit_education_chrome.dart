import 'package:flutter/material.dart';
import '../../../../l10n/app_strings_scope.dart';

/// Shared scaffold + states for all 5 education edit screens. Each page
/// follows the same skeleton: AppBar, optional "Currently saved" card,
/// scrollable content (the picker), Save + Clear buttons. Pulled out so
/// the per-level screens stay focused on their picker wiring.
class EditEducationChrome extends StatelessWidget {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _bg = Color(0xFFFAFAFA);
  static const double _minTouch = 48.0;

  final String title;
  final bool loading;
  final String? loadError;
  final VoidCallback onRetry;
  final bool saving;
  final VoidCallback? onSave;
  final bool hasExisting;
  final VoidCallback onClear;
  final String? currentSummary;
  final Widget child;
  /// When true, the inner widget is responsible for triggering save
  /// (e.g. UniversityProgrammePicker has its own "Continue" button).
  /// The chrome will hide its outer Save button.
  final bool hideSaveButton;

  const EditEducationChrome({
    super.key,
    required this.title,
    required this.loading,
    required this.loadError,
    required this.onRetry,
    required this.saving,
    this.onSave,
    required this.hasExisting,
    required this.onClear,
    required this.currentSummary,
    required this.child,
    this.hideSaveButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : loadError != null
                ? _buildError(s)
                : _buildBody(s),
      ),
    );
  }

  Widget _buildError(dynamic s) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(loadError ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF666666))),
            const SizedBox(height: 24),
            SizedBox(
              height: _minTouch,
              child: TextButton(
                onPressed: onRetry,
                child: Text(s?.retry ?? 'Retry'),
              ),
            ),
          ],
        ),
      );

  Widget _buildBody(dynamic s) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentSummary != null) ...[
              _CurrentCard(
                label: s?.currentlyShowing ?? 'Currently saved',
                summary: currentSummary!,
                hint: s?.tapToReselect ?? 'Pick again below to update',
              ),
              const SizedBox(height: 16),
            ],
            child,
            if (!hideSaveButton) ...[
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (saving || onSave == null) ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(s?.save ?? 'Save'),
                ),
              ),
            ] else
              const SizedBox(height: 16),
            if (hasExisting) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: _minTouch,
                child: TextButton.icon(
                  onPressed: saving ? null : onClear,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(
                    s?.clearSection ?? 'Clear this level',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      );
}

class _CurrentCard extends StatelessWidget {
  final String label;
  final String summary;
  final String hint;
  const _CurrentCard({
    required this.label,
    required this.summary,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              summary,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
}

/// Shared start/grad year row (used by Primary/Secondary/Postsecondary —
/// the A-Level and University pickers ship their own year fields inside
/// the picker widget itself).
class YearRow extends StatelessWidget {
  final int? startYear;
  final int? gradYear;
  final ValueChanged<int?> onStartChanged;
  final ValueChanged<int?> onGradChanged;

  const YearRow({
    super.key,
    required this.startYear,
    required this.gradYear,
    required this.onStartChanged,
    required this.onGradChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final now = DateTime.now().year;
    final years = List<int>.generate(60, (i) => now - i);
    return Row(
      children: [
        Expanded(
          child: _yearDropdown(
            label: s?.startYearLabel ?? 'Start year',
            value: startYear,
            years: years,
            onChanged: onStartChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _yearDropdown(
            label: s?.graduationYearLabel ?? 'Graduation year',
            value: gradYear,
            years: years,
            onChanged: onGradChanged,
          ),
        ),
      ],
    );
  }

  Widget _yearDropdown({
    required String label,
    required int? value,
    required List<int> years,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('—')),
        ...years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))),
      ],
      onChanged: onChanged,
    );
  }
}
