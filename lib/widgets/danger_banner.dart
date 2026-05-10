import 'package:flutter/material.dart';

import '../core/zmayy_colors.dart';

/// High-contrast ephemeral warning surface used around account deletion / destructive flows.
///
/// Provides a looping opacity pulse subtly inspired by **`AnimatePresence`** emphasis on web.
class DangerAttentionBanner extends StatefulWidget {
  const DangerAttentionBanner({super.key, required this.child});

  final Widget child;

  @override
  State<DangerAttentionBanner> createState() => _DangerAttentionBannerState();
}

class _DangerAttentionBannerState extends State<DangerAttentionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x1AEF4444),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ZmayyColors.danger.withAlpha(120)),
          boxShadow: [
            BoxShadow(
              color: ZmayyColors.danger.withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: DefaultTextStyle(
            style: const TextStyle(color: ZmayyColors.primaryText, height: 1.35, fontSize: 12),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
