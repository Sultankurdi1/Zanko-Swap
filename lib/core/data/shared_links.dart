import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/listings/presentation/item_details_screen.dart';
import '../localization/app_strings.dart';
import '../models/listing.dart';

/// Links to single listings, e.g. https://zankoswap.pages.dev/?item=123.
/// Anyone can open them in a browser; the website opens that listing.
class SharedLinks {
  const SharedLinks._();

  static const siteUrl = 'https://zankoswap.pages.dev';

  static final _validId = RegExp(r'^[0-9A-Za-z-]{1,64}$');

  static String listingUrl(String id) =>
      '$siteUrl/?item=${Uri.encodeQueryComponent(id)}';

  /// Opens the phone's share sheet (Telegram, WhatsApp, ...). Where the
  /// browser has none, the link is copied instead.
  static Future<void> shareListing(BuildContext context, Listing l) async {
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final url = listingUrl(l.id);
    final text = '${l.title}\n$url';
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: l.title),
      );
      if (result.status != ShareResultStatus.unavailable) return;
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(SnackBar(content: Text(s.linkCopied)));
  }

  static bool _handled = false;

  /// On the website: if the address has ?item=..., open that listing once.
  static Future<void> openPendingListing(BuildContext context) async {
    if (_handled || !kIsWeb) return;
    _handled = true;
    final id = Uri.base.queryParameters['item'];
    if (id == null || !_validId.hasMatch(id)) return;
    final s = AppStrings.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final row = await Supabase.instance.client
          .from('listings')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        messenger.showSnackBar(SnackBar(content: Text(s.listingNotFound)));
        return;
      }
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ItemDetailsScreen(listing: Listing.fromMap(row)),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(s.listingNotFound)));
    }
  }
}
