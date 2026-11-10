import 'package:flutter/material.dart';
import '../data/rating_repository.dart';
import '../localization/app_strings.dart';

Future<void> showRateSellerDialog(
  BuildContext context, {
  required String sellerId,
  required String sellerName,
}) async {
  final s = AppStrings.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final repo = RatingRepository();
  final current = await repo.myRating(sellerId);
  if (!context.mounted) return;

  final stars = await showDialog<int>(
    context: context,
    builder: (dialogContext) {
      var selected = current ?? 0;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(s.rateSellerTitle(sellerName)),
          content: Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 32,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => selected = i),
                  icon: Icon(
                    i <= selected
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: selected == 0
                  ? null
                  : () => Navigator.pop(dialogContext, selected),
              child: Text(s.rateAction),
            ),
          ],
        ),
      );
    },
  );
  if (stars == null) return;

  try {
    await repo.rate(sellerId, stars);
    messenger.showSnackBar(SnackBar(content: Text(s.ratingSaved)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(s.ratingNeedsChat)));
  }
}
