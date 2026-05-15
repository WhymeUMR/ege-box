import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  static void tap() {
    HapticFeedback.lightImpact();
  }

  static void select() {
    HapticFeedback.selectionClick();
  }

  static void success() {
    HapticFeedback.mediumImpact();
  }
}
