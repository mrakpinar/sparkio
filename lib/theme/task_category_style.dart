import 'package:flutter/material.dart';

class TaskCategoryStyle {
  const TaskCategoryStyle._();

  static String label(String key) {
    switch (key) {
      case 'body':
        return 'Body';
      case 'mind':
        return 'Mind';
      case 'growth':
        return 'Growth';
      case 'calm':
        return 'Calm';
      case 'health':
        return 'Health';
      default:
        return key == '--' ? '--' : 'Other';
    }
  }

  static IconData icon(String key) {
    switch (key) {
      case 'body':
        return Icons.fitness_center_rounded;
      case 'mind':
        return Icons.psychology_rounded;
      case 'growth':
        return Icons.trending_up_rounded;
      case 'calm':
        return Icons.spa_rounded;
      case 'health':
        return Icons.favorite_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color color(String key, {Color fallback = const Color(0xFF8B5CF6)}) {
    switch (key) {
      case 'mind':
        return const Color(0xFFF59E0B);
      case 'body':
        return const Color(0xFF4F7CFF);
      case 'growth':
        return const Color(0xFF7C83FF);
      case 'calm':
        return const Color(0xFF38BDF8);
      case 'health':
        return const Color(0xFF10B981);
      default:
        return fallback;
    }
  }
}
