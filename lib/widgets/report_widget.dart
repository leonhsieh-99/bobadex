import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/state/notification_queue.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportDialog extends StatefulWidget {
  final String contentType;
  final String contentId;
  const ReportDialog({super.key, required this.contentType, required this.contentId});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final _controller = TextEditingController();
  final _reasons = ['NSFW', 'Spam', 'Abuse', 'Other'];

  bool get canSubmit => _selectedReason != null;

  Future<void> _submitReport() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    await supabase.from('reports').insert({
      'reported_by': userId,
      'content_type': widget.contentType,
      'content_id': widget.contentId,
      'reason': _selectedReason,
      'message': _controller.text.trim(),
    });
    if (mounted) Navigator.of(context).pop();
    if(mounted) context.read<NotificationQueue>().queue('Report submitted', SnackType.info);
  }

@override
Widget build(BuildContext context) {
  return AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    contentPadding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedReason,
          items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (val) => setState(() => _selectedReason = val),
          decoration: InputDecoration(labelText: 'Reason'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          decoration: InputDecoration(labelText: 'Optional message'),
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: canSubmit ? _submitReport : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ],
    ),
  );
}

}