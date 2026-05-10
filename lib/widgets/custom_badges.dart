import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/zmayy_colors.dart';

/// Bottom-left translucent badges analogous to `.glass flex ... bottom-28 left-6` (`MapViewInner.tsx`).
///
/// Pass **`bottomInset`** equal to scaffold bottom padding + NavigationBar clearance so FAB/badges sit
/// comfortably above persistent chrome.
class SpatialBadgeTray extends StatelessWidget {
  const SpatialBadgeTray({super.key, this.bottomInset = 112});

  /// Additional offset from viewport bottom mirroring **`bottom-28`** (~112 px) clearance + nav tuning.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Consumer<ZmayyAppState>(
      builder: (BuildContext context, ZmayyAppState app, Widget? _) {
        final strangers = '${app.badgesMaskedForGhostMode ? '—' : app.nearbyStrangersCount} pengguna di sekitar';
        final friends = '${app.badgesMaskedForGhostMode ? '—' : app.onlineFriendsCount} teman online';

        return Positioned(
          left: 24,
          bottom: bottomInset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _GlassBadge(
                iconTint: ZmayyColors.strangerInitials,
                labelColor: ZmayyColors.strangerBadgeLabel,
                iconData: Icons.group_outlined,
                label: strangers,
              ),
              const SizedBox(height: 8),
              _GlassBadge(
                iconTint: ZmayyColors.gold,
                iconData: Icons.verified_user_outlined,
                labelColor: ZmayyColors.gold,
                label: friends,
                leadingDot: app.badgesMaskedForGhostMode
                    ? null
                    : const _OnlineDotBadge(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnlineDotBadge extends StatelessWidget {
  const _OnlineDotBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZmayyColors.statusOnlineMap,
        boxShadow: [
          BoxShadow(color: ZmayyColors.statusOnlineMap.withAlpha(153), blurRadius: 10),
        ],
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({
    required this.iconData,
    required this.labelColor,
    required this.label,
    required this.iconTint,
    this.leadingDot,
  });

  final IconData iconData;
  final Color iconTint;
  final Color labelColor;
  final String label;
  final Widget? leadingDot;

  @override
  Widget build(BuildContext context) {
    final dot = leadingDot;
    final List<Widget> rowChildren = <Widget>[
      Icon(iconData, size: 17, color: iconTint),
      ?dot,
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: TextStyle(color: labelColor, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ZmayyColors.glassFill,
          border: Border.all(color: ZmayyColors.border),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 24),
              blurRadius: 45,
              color: Colors.black.withAlpha(138),
            ),
            BoxShadow(
              color: const Color(0xFFFCD535).withAlpha(20),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: rowChildren,
          ),
        ),
      ),
    );
  }
}
