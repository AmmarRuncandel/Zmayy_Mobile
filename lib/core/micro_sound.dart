import 'package:flutter/services.dart';

/// Lightweight substitutes for [`useSound.ts`] oscillator ticks — avoids native audio assets.
abstract final class MicroSounds {
  static Future<void> playSendTap() async {
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.selectionClick();
  }

  static Future<void> playToggleDoublePop() async {
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }

  /// Incoming ephemeral message cue while chat UI is foregrounded.
  static Future<void> playIncomingMessage() async {
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.mediumImpact();
  }
}
