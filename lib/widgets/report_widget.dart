import 'package:bobadex/notification_bus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportDialog extends StatefulWidget {
  final String contentType;
  final String contentId;
  final String? reportedUserId;
  const ReportDialog({super.key, required this.contentType, required this.contentId, required this.reportedUserId});

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

    try {
      await supabase.from('reports').insert({
        'reported_by': userId,
        'content_type': widget.contentType,
        'content_id': widget.contentId,
        'reason': _selectedReason,
        'message': _controller.text.trim(),
        'reported_user_id': widget.reportedUserId
      });
      if (mounted) Navigator.of(context).pop();
      notify('Report submitted', SnackType.info);
    } catch (e) {
      debugPrint('Error: $e');
    }
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
          initialValue: _selectedReason,
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