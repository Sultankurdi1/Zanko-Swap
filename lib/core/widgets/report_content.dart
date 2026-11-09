import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/app_strings.dart';

Future<void> reportContent(
  BuildContext context, {
  required String contentType,
  required String contentId,
}) async {
  final s = AppStrings.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    messenger.showSnackBar(SnackBar(content: Text(s.signInToReport)));
    return;
  }

  final reason = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(title: Text(s.reportContentQuestion)),
          for (final item in <(String, String)>[
            ('sexual', s.reportSexual),
            ('harassment', s.reportHarassment),
            ('spam', s.reportSpam),
            ('other', s.reportOther),
          ])
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(item.$2),
              onTap: () => Navigator.pop(sheetContext, item.$1),
            ),
        ],
      ),
    ),
  );
  if (reason == null) return;

  try {
    await client.from('content_reports').insert({
      'reporter_id': user.id,
      'content_type': contentType,
      'content_id': contentId,
      'reason': reason,
    });
    messenger.showSnackBar(SnackBar(content: Text(s.reportSent)));
  } on PostgrestException catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(e.code == '23505' ? s.alreadyReported : s.genericError),
      ),
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(s.genericError)));
  }
}
