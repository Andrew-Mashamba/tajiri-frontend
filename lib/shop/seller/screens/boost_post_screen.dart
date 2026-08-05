import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

class _PostOption {
  final int id;
  final String title;
  final String reach;

  const _PostOption(
      {required this.id, required this.title, required this.reach});
}

/// Boost an existing product post — select post, set budget and duration.
class BoostPostScreen extends StatefulWidget {
  const BoostPostScreen({super.key});

  @override
  State<BoostPostScreen> createState() => _BoostPostScreenState();
}

class _BoostPostScreenState extends State<BoostPostScreen> {
  bool _loading = true;
  int? _selectedPostId;
  int _budgetIndex = 1;
  int _durationDays = 3;
  bool _submitting = false;

  final List<_PostOption> _posts = [];
  final List<int> _budgets = [500, 1000, 2000, 5000];
  final List<int> _durations = [1, 3, 7, 14];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _posts.addAll([
        const _PostOption(
            id: 1,
            title: 'Blue Leso — Traditional Fabric',
            reach: '1.2K views'),
        const _PostOption(
            id: 2, title: 'Handmade Leather Bag', reach: '890 views'),
        const _PostOption(
            id: 3, title: 'Kitenge Dress — Size S–XL', reach: '2.4K views'),
      ]);
    });
  }

  int get _budget => _budgets[_budgetIndex];
  double get _estimatedReach => _budget * 12.0;

  void _submit() async {
    if (_selectedPostId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a post to boost')),
      );
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post boost submitted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _kSurface,
            elevation: 0,
            pinned: true,
            centerTitle: false,
            title: const Text(
              'Boost Post',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kText),
            ),
            iconTheme: const IconThemeData(color: _kText),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                _Section(
                  title: '1. Select post to boost',
                  child: Column(
                    children: _posts.map((p) {
                      final selected = _selectedPostId == p.id;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedPostId = p.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  selected ? _kText : _kDivider,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: HeroIcon(
                                  HeroIcons.photo,
                                  style: HeroIconStyle.outline,
                                  color: _kMuted,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: _kText),
                                  ),
                                  Text(
                                    p.reach,
                                    style: const TextStyle(
                                        fontSize: 11, color: _kFaint),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const HeroIcon(HeroIcons.checkCircle,
                                  style: HeroIconStyle.solid,
                                  color: _kText,
                                  size: 20),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                _Section(
                  title: '2. Set daily budget',
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_budgets.length, (i) {
                        final sel = _budgetIndex == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _budgetIndex = i),
                            child: Container(
                              margin:
                                  const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? _kText : _kSurface,
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel
                                      ? _kText
                                      : _kDivider,
                                ),
                              ),
                              child: Column(children: [
                                Text(
                                  'TZS',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: sel
                                          ? Colors.white70
                                          : _kFaint),
                                ),
                                Text(
                                  '${_budgets[i]}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: sel
                                          ? Colors.white
                                          : _kText),
                                ),
                              ]),
                            ),
                          ),
                        );
                      }),
                    ),
                  ]),
                ),

                _Section(
                  title: '3. Duration',
                  child: Column(children: [
                    Row(
                      children: _durations.map((d) {
                        final sel = _durationDays == d;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _durationDays = d),
                            child: Container(
                              margin:
                                  const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? _kText : _kSurface,
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel
                                      ? _kText
                                      : _kDivider,
                                ),
                              ),
                              child: Column(children: [
                                Text(
                                  '$d',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: sel
                                          ? Colors.white
                                          : _kText),
                                ),
                                Text(
                                  d == 1 ? 'day' : 'days',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: sel
                                          ? Colors.white70
                                          : _kFaint),
                                ),
                              ]),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ]),
                ),

                // Summary
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [_kCardShadow],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Spend',
                                style: TextStyle(
                                    fontSize: 12, color: _kMuted)),
                            Text(
                              'TZS ${_budget * _durationDays}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _kText),
                            ),
                          ]),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Est. Reach',
                                style: TextStyle(
                                    fontSize: 12, color: _kMuted)),
                            Text(
                              '~${(_estimatedReach * _durationDays).toStringAsFixed(0)} people',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kText),
                            ),
                          ]),
                    ],
                  ),
                ),

                // CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kText,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Text('Boost Now',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kText)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}
