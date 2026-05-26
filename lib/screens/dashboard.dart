import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/progress_ring.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _noteTitleController = TextEditingController();
  final _noteContentController = TextEditingController();
  final _noteTagsController = TextEditingController();
  bool _noteSuccess = false;

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadDashboardData(_todayStr);
    });
  }

  @override
  void dispose() {
    _noteTitleController.dispose();
    _noteContentController.dispose();
    _noteTagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.loading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final userCompletions = state.completions.map((c) => c.ruleId).toSet();
        final completionPercentage = state.rules.isNotEmpty
            ? (userCompletions.length / state.rules.length) * 100
            : 0.0;

        final myStreak = (state.stats['currentStreak'] ?? 0) as int;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Hub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your personal accountability tracker.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (state.gamification != null) ...[
                        _buildXPCard(state.gamification!),
                        const SizedBox(width: 12),
                      ],
                      _buildStreakCard(myStreak),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main content grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isWide ? 2 : 1,
                        child: Column(
                          children: [
                            _buildTargetsCard(state, completionPercentage),
                            const SizedBox(height: 16),
                            _buildChecklistCard(state, userCompletions),
                          ],
                        ),
                      ),
                      if (isWide) ...[
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              _buildQuickWriteupCard(),
                              const SizedBox(height: 16),
                              _buildActivityFeedCard(state),
                              if (state.gamification != null &&
                                  state.gamification!.achievements.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildAchievementsCard(state.gamification!),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),

              // Mobile-only: show right panel content below
              if (MediaQuery.of(context).size.width < 900) ...[
                const SizedBox(height: 16),
                _buildQuickWriteupCard(),
                const SizedBox(height: 16),
                _buildActivityFeedCard(state),
                if (state.gamification != null &&
                    state.gamification!.achievements.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAchievementsCard(state.gamification!),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildXPCard(GamificationData gamification) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEVEL ${gamification.level}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                gamification.rankTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 80,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: gamification.progressToNext,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: streak > 0 ? Colors.white : Colors.white.withOpacity(0.2),
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STREAK',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$streak Days',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetsCard(AppState state, double percentage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Targets Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completing rules earns XP and extends your streak. Stay consistent!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ProgressRing(progress: percentage, size: 90),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(AppState state, Set<int> userCompletions) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RULE ITEMS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (state.rules.isNotEmpty &&
                  userCompletions.length == state.rules.length)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    'All Complete! +${state.rules.length * 25} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.rules.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No ground rules established yet. Go to "Ground Rules" tab to configure tasks.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final rule = state.rules[index];
                final isCompleted = userCompletions.contains(rule.id);
                return _buildRuleItem(rule, isCompleted, state);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(dynamic rule, bool isCompleted, AppState state) {
    return InkWell(
      onTap: () async {
        await state.toggleRule(rule.id, _todayStr);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.white.withOpacity(0.02)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCompleted
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: isCompleted
                  ? Colors.white
                  : Colors.white.withOpacity(0.2),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.title,
                    style: TextStyle(
                      color: isCompleted
                          ? Colors.white.withOpacity(0.5)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (rule.description != null &&
                      rule.description.isNotEmpty)
                    Text(
                      rule.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isCompleted)
              Text(
                '+25 XP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                rule.difficulty.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickWriteupCard() {
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
                Icons.menu_book_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Writeup Log',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_noteSuccess) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Text(
                'Progress logged successfully!',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildTextField(_noteTitleController, 'Title...'),
          const SizedBox(height: 8),
          _buildTextField(
            _noteContentController,
            'What progress did you make?',
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          _buildTextField(_noteTagsController, 'Tags: success, blockers...'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_noteTitleController.text.isEmpty ||
                    _noteContentController.text.isEmpty) return;
                await context.read<AppState>().addWriteup(
                  _noteTitleController.text,
                  _noteContentController.text,
                  _noteTagsController.text.isEmpty
                      ? null
                      : _noteTagsController.text,
                );
                _noteTitleController.clear();
                _noteContentController.clear();
                _noteTagsController.clear();
                setState(() {
                  _noteSuccess = true;
                });
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() => _noteSuccess = false);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Log Writeup',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildActivityFeedCard(AppState state) {
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
                Icons.history_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Activity Feed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.feed.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No recent actions logged.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.feed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = state.feed[index];
                return _buildFeedItem(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(dynamic item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            item.type == 'checklist'
                ? Icons.check_box_rounded
                : Icons.message_rounded,
            color: Colors.white.withOpacity(0.4),
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '@${item.username}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' ${item.type == 'checklist' ? 'checked off' : 'posted'} ',
                    ),
                    TextSpan(
                      text: '"${item.itemTitle}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('hh:mm a').format(item.timestamp),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsCard(GamificationData gamification) {
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
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: gamification.achievements.map((ach) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ach.badgeIcon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      ach.badgeName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
