import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy
  static const Color primaryLight = Color(0xFF3B82F6); // Royal Blue
  static const Color primaryDark = Color(0xFF172554);
  static const Color accent = Color(0xFFF59E0B); // Amber Accent

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981); // Emerald Green (Valid, Paid, Completed)
  static const Color warning = Color(0xFFF59E0B); // Amber (Pending, Tempo Active)
  static const Color danger = Color(0xFFEF4444);  // Red (Overdue, Cancelled, Conflict)
  static const Color info = Color(0xFF0EA5E9);

  // Neutral Background & Surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Territory Pin Colors
  static const Color myStorePin = Color(0xFF2563EB); // Blue: My Store
  static const Color otherStorePin = Color(0xFF94A3B8); // Slate: Other Sales' Store
}
