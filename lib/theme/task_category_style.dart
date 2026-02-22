import 'package:flutter/material.dart';

class TaskCategoryStyle {
  const TaskCategoryStyle._();

  static String? iconAsset(String key) {
    switch (key) {
      case 'mind':
        return 'assets/in_app_icons/human-brain.png';
      case 'body':
        return 'assets/in_app_icons/muscles.png';
      case 'growth':
        return 'assets/in_app_icons/graph.png';
      case 'calm':
        return 'assets/in_app_icons/serene.png';
      case 'health':
        return 'assets/in_app_icons/healthcare.png';
      default:
        return null;
    }
  }

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

  static Widget iconWidget(String key, {double size = 24, Color? color}) {
    final asset = iconAsset(key);
    if (asset != null) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: color != null ? BlendMode.srcIn : null,
        errorBuilder: (_, error, stackTrace) {
          return Icon(icon(key), size: size, color: color);
        },
      );
    }
    return Icon(icon(key), size: size, color: color);
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
