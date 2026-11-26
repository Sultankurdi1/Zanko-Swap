import 'package:flutter/material.dart';

import '../data/verification_repository.dart';
import '../localization/app_strings.dart';

/// Small blue check shown next to the name of a verified student.
/// Shows nothing while loading or when the user is not verified.
class VerifiedBadge extends StatefulWidget {
  const VerifiedBadge({super.key, required this.userId, this.size = 18});

  final String userId;
  final double size;

  @override
  State<VerifiedBadge> createState() => _VerifiedBadgeState();
}

class _VerifiedBadgeState extends State<VerifiedBadge> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = VerificationRepository().isVerified(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return Tooltip(
          message: s.isKurdish
              ? 'قوتابی پشتڕاستکراو'
              : s.isArabic
              ? 'طالب موثّق'
              : 'Verified student',
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Icon(
              Icons.verified_rounded,
              size: widget.size,
              color: const Color(0xFF38BDF8),
            ),
          ),
        );
      },
    );
  }
}
