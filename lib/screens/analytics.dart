import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      context.read<AppState>().loadAnalytics(today);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final streak = (state.stats['currentStreak'] ?? 0) as int;
        final maxStreak = (state.stats['maxStreak'] ?? 0) as int;
        final completedCount = (state.stats['completedCount'] ?? 0) as int;
        final completedDates =
            (state.stats['completedDates'] ?? <String>[]) as List<dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your consistency and progress over time.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Current Streak',
                      streak.toString(),
                      'days',
                      Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Max Streak',
                      maxStreak.toString(),
                      'days',
                      Icons.emoji_events,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Checks',
                      completedCount.toString(),
                      'completions',
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (state.gamification != null) ...[
                _buildLevelCard(state.gamification!),
                const SizedBox(height: 24),
              ],
              _buildHeatmapCard(completedDates.cast<String>()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.3), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(dynamic gamification) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Level ${gamification.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  gamification.rankTitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: gamification.progressToNext,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${gamification.totalXP} / ${gamification.nextLevelXP} XP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard(List<String> completedDates) {
    final now = DateTime.now();
    final days = List.generate(60, (i) {
      return now.subtract(Duration(days: 59 - i));
    });

    final dateSet = completedDates.toSet();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: Colors.white.withOpacity(0.4),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                '60-Day Consistency',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: days.map((day) {
              final dateStr =
                  '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final isActive = dateSet.contains(dateStr);
              return Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Less',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
