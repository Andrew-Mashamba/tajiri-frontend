// lib/myjob/widgets/update_task_sheet.dart
import 'package:flutter/material.dart';
import '../models/myjob_models.dart';
import '../services/my_job_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class UpdateTaskSheet extends StatefulWidget {
  final WorkTask task;
  final String token;
  final bool sw;
  final VoidCallback onSaved;

  const UpdateTaskSheet({
    super.key,
    required this.task,
    required this.token,
    required this.sw,
    required this.onSaved,
  });

  @override
  State<UpdateTaskSheet> createState() => _UpdateTaskSheetState();
}

class _UpdateTaskSheetState extends State<UpdateTaskSheet> {
  late String _status;
  late double _progress;
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.task.status;
    _progress = widget.task.progress.toDouble();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.task.id == null) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final body = {
      'status': _status,
      'progress': _progress.round(),
      if (_commentCtrl.text.trim().isNotEmpty) 'comment': _commentCtrl.text.trim(),
    };
    final res = await MyJobService.postTaskUpdate(widget.token, widget.task.id!, body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      if (_status == 'done') {
        messenger.showSnackBar(
          SnackBar(content: Text(widget.sw ? 'Kazi imekamilika! 🎉' : 'Task complete! 🎉')));
      } else if (_commentCtrl.text.trim().isEmpty) {
        messenger.showSnackBar(SnackBar(
            content: Text(widget.sw
                ? 'Ongeza maelezo mara ijayo kuweka meneja wako ana habari.'
                : 'Add a comment next time to keep your manager informed.')));
      }
      Navigator.pop(context);
      widget.onSaved();
    } else {
      messenger.showSnackBar(SnackBar(
          content: Text(res.message ??
              (widget.sw ? 'Imeshindwa kuhifadhi. Jaribu tena.' : 'Failed to save update. Try again.')),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(sw ? 'Sasisha Kazi' : 'Update Task',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
        const SizedBox(height: 4),
        Text(widget.task.title,
            style: const TextStyle(fontSize: 13, color: _kSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),

        Text(sw ? 'Hali' : 'Status',
            style: const TextStyle(fontSize: 12, color: _kSecondary)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
                value: 'pending', label: Text(sw ? 'Haijaanza' : 'Not Started',
                    style: const TextStyle(fontSize: 11))),
            ButtonSegment(
                value: 'in_progress', label: Text(sw ? 'Inaendelea' : 'In Progress',
                    style: const TextStyle(fontSize: 11))),
            ButtonSegment(
                value: 'done', label: Text(sw ? 'Imekamilika' : 'Done',
                    style: const TextStyle(fontSize: 11))),
          ],
          selected: {_status},
          onSelectionChanged: (s) {
            final newStatus = s.first;
            setState(() {
              _status = newStatus;
              if (newStatus == 'done') _progress = 100;
              if (newStatus == 'in_progress' && _progress < 1) _progress = 1;
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) =>
                states.contains(WidgetState.selected) ? _kPrimary : null),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) =>
                states.contains(WidgetState.selected) ? Colors.white : _kPrimary),
          ),
        ),
        const SizedBox(height: 16),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(sw ? 'Maendeleo' : 'Progress',
              style: const TextStyle(fontSize: 12, color: _kSecondary)),
          Text('${_progress.round()}%',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: _kPrimary)),
        ]),
        Slider(
          value: _progress,
          min: 0, max: 100, divisions: 100,
          activeColor: _kPrimary,
          onChanged: (v) => setState(() => _progress = v),
        ),

        TextField(
          controller: _commentCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: sw ? 'Kuna nini kipya?' : "What's the update?",
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48)),
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(sw ? 'Hifadhi' : 'Save'),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
