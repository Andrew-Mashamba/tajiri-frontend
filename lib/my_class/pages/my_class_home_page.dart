// lib/my_class/pages/my_class_home_page.dart
import 'package:flutter/material.dart';
import '../models/my_class_models.dart';
import '../services/my_class_service.dart';
import 'create_class_page.dart';
import 'class_detail_page.dart';
import '../widgets/class_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MyClassHomePage extends StatefulWidget {
  final int userId;
  const MyClassHomePage({super.key, required this.userId});
  @override
  State<MyClassHomePage> createState() => _MyClassHomePageState();
}

class _MyClassHomePageState extends State<MyClassHomePage> {
  final MyClassService _service = MyClassService();
  List<StudentClass> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyClasses();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _classes = result.items;
      });
    }
  }

  void _joinClass() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jiunge na Darasa / Join Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Weka nambari ya darasa / Enter class code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi / Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _service.joinClass(controller.text.trim());
              if (mounted) {
                if (res.success) {
                  _loadClasses();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Failed to join class')));
                }
              }
            },
            child: const Text('Jiunge / Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadClasses,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.school_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text('Darasa Langu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                            'My Classes — ${_classes.length} darasa',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => CreateClassPage(userId: widget.userId))).then((_) => _loadClasses()),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Unda Darasa / Create'),
                          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, minimumSize: const Size(0, 48)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _joinClass,
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('Jiunge / Join'),
                          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, minimumSize: const Size(0, 48)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Classes list
                    if (_classes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(48),
                        alignment: Alignment.center,
                        child: const Column(children: [
                          Icon(Icons.school_rounded, size: 48, color: _kSecondary),
                          SizedBox(height: 8),
                          Text('Huna darasa bado', style: TextStyle(color: _kSecondary, fontSize: 14)),
                          Text('No classes yet', style: TextStyle(color: _kSecondary, fontSize: 12)),
                        ]),
                      )
                    else
                      ..._classes.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ClassCard(
                              studentClass: c,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => ClassDetailPage(classId: c.id, userId: widget.userId))),
                            ),
                          )),
                  ],
                ),
              ),
      ),
    );
  }
}
