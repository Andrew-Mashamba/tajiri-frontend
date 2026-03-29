import 'package:flutter/material.dart';

/// Horizontal scrollable year chip picker with smart default selection.
/// Used in education steps to quickly pick graduation years.
class YearChipSelector extends StatefulWidget {
  /// Center year for the chip range (typically calculated from DOB).
  final int defaultYear;

  /// Number of years to show on each side of defaultYear. Range = ±[yearRange].
  final int yearRange;

  /// Currently selected year (null = none selected).
  final int? selectedYear;

  /// Called when user taps a year chip.
  final ValueChanged<int> onYearSelected;

  const YearChipSelector({
    super.key,
    required this.defaultYear,
    this.yearRange = 3,
    this.selectedYear,
    required this.onYearSelected,
  });

  @override
  State<YearChipSelector> createState() => _YearChipSelectorState();
}

class _YearChipSelectorState extends State<YearChipSelector> {
  static const Color _primary = Color(0xFF1A1A1A);
  late final ScrollController _scrollController;

  List<int> get _years {
    final start = widget.defaultYear - widget.yearRange;
    final end = widget.defaultYear + widget.yearRange;
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  void _scrollToSelected() {
    final targetYear = widget.selectedYear ?? widget.defaultYear;
    final index = _years.indexOf(targetYear);
    if (index >= 0 && _scrollController.hasClients) {
      final offset = (index * 72.0) - (MediaQuery.of(context).size.width / 2) + 36;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _years.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final year = _years[index];
          final isSelected = year == widget.selectedYear;
          return GestureDetector(
            onTap: () => widget.onYearSelected(year),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _primary : Colors.white,
                border: Border.all(
                  color: isSelected ? _primary : const Color(0xFFE0E0E0),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$year',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : _primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
