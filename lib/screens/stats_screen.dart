import 'package:flutter/material.dart';
import '../services/task_repository.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Future<_StatsData> _load() async {
    final repo = TaskRepository();
    final total = await repo.getTotalCompleted();
    final best = await repo.getBestStreak();
    final counts = await repo.getCategoryCounts();
    final favorite = _favoriteCategory(counts);
    return _StatsData(total: total, bestStreak: best, favorite: favorite);
  }

  String _favoriteCategory(Map<String, int> counts) {
    if (counts.isEmpty) return '—';
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String _label(String key) {
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
        return key == '—' ? '—' : 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
      ),
      body: FutureBuilder<_StatsData>(
        future: _load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatCard(
                  title: 'Tasks completed',
                  value: data.total.toString(),
                  color: scheme.primary,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Best streak',
                  value: '${data.bestStreak} days',
                  color: scheme.secondary,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Favorite category',
                  value: _label(data.favorite),
                  color: scheme.primaryContainer,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.insights_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsData {
  final int total;
  final int bestStreak;
  final String favorite;

  const _StatsData({
    required this.total,
    required this.bestStreak,
    required this.favorite,
  });
}
