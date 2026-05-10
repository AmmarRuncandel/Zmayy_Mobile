import 'package:flutter/material.dart';

/// Design tokens from `app/globals.css` (:root `@theme`).
///
/// **Note:** the rubric cites Tailwind `slate-950` (`#020617`), but the live web theme
/// uses `--color-base: #0B0E11` for the chrome background — we mirror **`globals.css`**
/// as canonical and expose `slate950` for optional scaffolding / OS status bar tuning.
abstract final class ZmayyColors {
  /// `--color-base` — primary scaffold / body background (`#0B0E11`).
  static const base = Color(0xFF0B0E11);

  /// Tailwind Slate 950 (`#020617`), referenced externally; not currently a CSS token.
  static const slate950 = Color(0xFF020617);

  /// `--color-surface` (`#181A20`).
  static const surface = Color(0xFF181A20);

  /// `--color-gold` (`#FCD535`).
  static const gold = Color(0xFFFCD535);

  /// `--color-gold-dim` (`#D4AC1A`).
  static const goldDim = Color(0xFFD4AC1A);

  /// Accent gold used when animating FAB (`#F0A500`) — `MapViewInner.tsx`.
  static const goldHot = Color(0xFFF0A500);

  /// `--color-primary` (`#EAECEF`).
  static const primaryText = Color(0xFFEAECEF);

  /// `--color-muted` (`#848E9C`).
  static const muted = Color(0xFF848E9C);

  /// `--color-border` (`#2B2F36`).
  static const border = Color(0xFF2B2F36);

  /// `--color-overlay`: `rgba(11,14,17,0.75)`.
  static const overlay = Color(0xBF0B0E11);

  /// Glass panels — `.glass` in `globals.css`: `rgba(24,26,32,0.85)`.
  static const glassFill = Color(0xD9181A20);

  /// Attribution pill background (`MapViewInner.tsx`): `rgba(11,14,17,0.8)`.
  static const attributionPill = Color(0xCC0B0E11);

  /// Danger accents shared by chat ring + deletion UI (`#EF4444`).
  static const danger = Color(0xFFEF4444);

  /// Chat ephemeral ring mid tone (`ChatPanel.tsx`, `#F59E0B`).
  static const warningAmber = Color(0xFFF59E0B);

  /// Map “online dot” ping — `Circle` lucide styling uses `#22c55e`.
  static const statusOnlineMap = Color(0xFF22C55E);

  /// Friends list / ProfileModal online dot uses `#2ECC71`.
  static const statusOnlineUi = Color(0xFF2ECC71);

  /// Stranger marker stroke / fill from `makeFriendIcon`.
  static const strangerStroke = Color(0xFF4B5563);
  static const strangerFill = Color(0xFF111318);
  static const strangerInitials = Color(0xFF9CA3AF);

  /// Map badge neutral label for stranger counts (`#D1D5DB`).
  static const strangerBadgeLabel = Color(0xFFD1D5DB);

  /// Ghost overlay (`MapViewInner.tsx`): `rgba(11,14,17,0.35)`.
  static const ghostVeil = Color(0x590B0E11);
}
