import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/ui/components/boba_chip.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const reportReasons = ['Spam', 'Abuse', 'Other'];

Future<void> showReportDialog({
  required BuildContext context,
  required String contentType,
  required String contentId,
  String? reportedUserId,
  required String title,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ReportDialog(
      contentType: contentType,
      contentId: contentId,
      reportedUserId: reportedUserId,
      title: title,
    ),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.contentType,
    required this.contentId,
    required this.reportedUserId,
    required this.title,
  });

  final String contentType;
  final String contentId;
  final String? reportedUserId;
  final String title;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _note = TextEditingController();
  String? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    if (Supabase.instance.client.auth.currentSession == null) {
      notify('Sign in to report this.', SnackType.error);
      return;
    }
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.rpc(
        'submit_report',
        params: {
          'p_content_type': widget.contentType,
          'p_content_id': widget.contentId,
          'p_reason': reason,
          'p_message': _note.text.trim().isEmpty ? null : _note.text.trim(),
          'p_reported_user_id': widget.reportedUserId,
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      notify('Report sent. A person reviews it.', SnackType.info);
    } on PostgrestException catch (e) {
      debugPrint('report failed: ${e.message}');
      final signedOut = e.message.toLowerCase().contains(
        'authentication_required',
      );
      notify(
        signedOut ? 'Sign in to report this.' : 'Could not send that report.',
        SnackType.error,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: BobaSpace.x2,
              runSpacing: BobaSpace.x2,
              children: [
                for (final reason in reportReasons)
                  BobaChip(
                    label: reason,
                    selected: _reason == reason,
                    onTap: _sending
                        ? null
                        : () => setState(() => _reason = reason),
                  ),
              ],
            ),
            const SizedBox(height: BobaSpace.x4),
            TextField(
              controller: _note,
              enabled: !_sending,
              maxLength: 500,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _reason == null || _sending ? null : _submit,
          child: const Text('Report'),
        ),
      ],
    );
  }
}
