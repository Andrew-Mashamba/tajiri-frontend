import 'package:flutter/material.dart';

/// A lazy version of [IndexedStack] that only builds children
/// when they are first selected. Once built, children stay alive
/// (same behavior as IndexedStack for return visits).
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget Function()> builders;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.builders,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  final Set<int> _activated = {};
  final Map<int, Widget> _built = {};

  @override
  void initState() {
    super.initState();
    _activated.add(widget.index);
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _activated.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < widget.builders.length; i++) {
      if (_activated.contains(i)) {
        _built[i] ??= widget.builders[i]();
        children.add(_built[i]!);
      } else {
        children.add(const SizedBox.shrink());
      }
    }
    return IndexedStack(
      index: widget.index,
      children: children,
    );
  }
}
