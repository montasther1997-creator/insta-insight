import 'package:flutter/services.dart';

/// Unified tap feedback — light haptic + system click sound.
/// Android respects the user's "Touch sounds" system setting, so this is
/// silent for users who have UI sounds disabled. Haptic is always fired.
class TapFeedback {
  /// Standard tap (nav, buttons, list items).
  static Future<void> light() async {
    HapticFeedback.selectionClick();
    await SystemSound.play(SystemSoundType.click);
  }

  /// Slightly stronger — for primary actions (generate, submit, confirm).
  static Future<void> medium() async {
    HapticFeedback.lightImpact();
    await SystemSound.play(SystemSoundType.click);
  }
}
