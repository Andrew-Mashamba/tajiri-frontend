import 'dart:convert';

import 'package:flutter/material.dart';

import '../../fitness/widgets/spot_picker_canvas.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F6 #42 — Partner-side editor for the studio floor plan.
///
/// Partner picks a grid size (rows × cols), then taps cells to toggle them
/// between empty (aisle / no spot) and a numbered spot. Saves to
/// `partner_studio_layouts` via `StudioLayoutService.save`.
class StudioLayoutEditorPage extends StatefulWidget {
  final int partnerUserId;
  final int partnerId;
  const StudioLayoutEditorPage({
    super.key,
    required this.partnerUserId,
    required this.partnerId,
  });

  @override
  State<StudioLayoutEditorPage> createState() => _StudioLayoutEditorPageState();
}

class _StudioLayoutEditorPageState extends State<StudioLayoutEditorPage> {
  int _rows = 4;
  int _cols = 5;
  bool _loading = true;
  bool _saving = false;
  // grid[r][c] holds spot id (1-indexed) or null for empty.
  late List<List<int?>> _grid;

  @override
  void initState() {
    super.initState();
    _grid = List.generate(_rows, (_) => List<int?>.filled(_cols, null));
    _load();
  }

  Future<void> _load() async {
    final raw = await StudioLayoutService.show(widget.partnerId);
    if (!mounted) return;
    if (raw != null && raw['layout_json'] != null) {
      final j = raw['layout_json'];
      Map<String, dynamic>? layout;
      if (j is String) {
        try {
          layout = (jsonDecode(j) as Map).cast<String, dynamic>();
        } catch (_) {}
      } else if (j is Map) {
        layout = j.cast<String, dynamic>();
      }
      if (layout != null && layout['grid'] is List) {
        final gridRaw = layout['grid'] as List;
        final loaded = <List<int?>>[];
        for (final row in gridRaw) {
          if (row is List) {
            loaded.add(row
                .map((c) => c is num ? c.toInt() : null)
                .toList(growable: false));
          }
        }
        if (loaded.isNotEmpty) {
          _grid = loaded;
          _rows = loaded.length;
          _cols = loaded.first.length;
        }
      }
    }
    setState(() => _loading = false);
  }

  void _resize(int rows, int cols) {
    final next = List.generate(rows, (r) {
      return List<int?>.generate(cols, (c) {
        if (r < _grid.length && c < _grid[r].length) return _grid[r][c];
        return null;
      });
    });
    setState(() {
      _rows = rows;
      _cols = cols;
      _grid = next;
    });
  }

  void _toggleCell(int r, int c) {
    setState(() {
      if (_grid[r][c] != null) {
        _grid[r][c] = null;
        _renumber();
      } else {
        // Insert with the next available id.
        final used = <int>{};
        for (final row in _grid) {
          for (final v in row) {
            if (v != null) used.add(v);
          }
        }
        var next = 1;
        while (used.contains(next)) {
          next++;
        }
        _grid[r][c] = next;
        _renumber();
      }
    });
  }

  /// Compact spot ids 1..N in row-major order so saved layout has stable ids.
  void _renumber() {
    var next = 1;
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (_grid[r][c] != null) {
          _grid[r][c] = next++;
        }
      }
    }
  }

  List<Map<String, dynamic>> _spotsList() {
    final out = <Map<String, dynamic>>[];
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final id = _grid[r][c];
        if (id == null) continue;
        out.add({
          'id': id,
          'label': _idToLabel(id),
          'x': c,
          'y': r,
        });
      }
    }
    return out;
  }

  String _idToLabel(int id) {
    // Friendly labels A1, A2, ..., B1 ...
    final row = (id - 1) ~/ _cols;
    final col = (id - 1) % _cols;
    final letter = String.fromCharCode('A'.codeUnitAt(0) + row);
    return '$letter${col + 1}';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await StudioLayoutService.save(
      partnerUserId: widget.partnerUserId,
      layout: {
        'grid': _grid,
        'spots': _spotsList(),
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Imehifadhiwa' : 'Imeshindikana')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final layout = StudioLayout(
      grid: _grid,
      spotLabels: {
        for (final s in _spotsList())
          s['id'] as int: (s['label'] as String?) ?? '${s['id']}',
      },
    );
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Tengeneza ramani' : 'Floor plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: isSw ? 'Hifadhi' : 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  isSw
                      ? 'Bonyeza kisanduku kuongeza/kuondoa nafasi.'
                      : 'Tap a cell to add or remove a spot.',
                  style: const TextStyle(color: Color(0xFF666666)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _stepRow(
                        label: isSw ? 'Mistari' : 'Rows',
                        value: _rows,
                        min: 1,
                        max: 12,
                        onChanged: (v) => _resize(v, _cols),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _stepRow(
                        label: isSw ? 'Safu' : 'Cols',
                        value: _cols,
                        min: 1,
                        max: 12,
                        onChanged: (v) => _resize(_rows, v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AbsorbPointer(
                  absorbing: false,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: _editableGrid(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSw ? 'Onesho la mteja' : 'Customer preview',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: SpotPickerCanvas(
                    layout: layout,
                    takenSpotIds: const {},
                    selectedSpotId: null,
                    onPick: (_) {},
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stepRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 24,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  Widget _editableGrid() {
    return LayoutBuilder(
      builder: (ctx, c) {
        final cellSize = (c.maxWidth - (_cols - 1) * 6) / _cols;
        return Column(
          children: List.generate(_rows, (r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (int col = 0; col < _cols; col++) ...[
                    if (col > 0) const SizedBox(width: 6),
                    SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: InkWell(
                        onTap: () => _toggleCell(r, col),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _grid[r][col] != null
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFFAFAFA),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: _grid[r][col] != null
                              ? Text(
                                  _idToLabel(_grid[r][col]!),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
