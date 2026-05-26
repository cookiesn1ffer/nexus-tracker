class Rule {
  final int id;
  final String title;
  final String description;
  final String frequency;
  final String difficulty;
  final int createdBy;
  final DateTime createdAt;

  Rule({
    required this.id,
    required this.title,
    required this.description,
    required this.frequency,
    required this.difficulty,
    required this.createdBy,
    required this.createdAt,
  });

  factory Rule.fromMap(Map<String, dynamic> map) {
    return Rule(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      frequency: map['frequency'] as String,
      difficulty: map['difficulty'] as String,
      createdBy: map['created_by'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'frequency': frequency,
      'difficulty': difficulty,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ChecklistLog {
  final int id;
  final int userId;
  final int ruleId;
  final String completedDate;
  final DateTime completedAt;

  ChecklistLog({
    required this.id,
    required this.userId,
    required this.ruleId,
    required this.completedDate,
    required this.completedAt,
  });

  factory ChecklistLog.fromMap(Map<String, dynamic> map) {
    return ChecklistLog(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      ruleId: map['rule_id'] as int,
      completedDate: map['completed_date'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }
}

class Writeup {
  final int id;
  final int userId;
  final String username;
  final String title;
  final String content;
  final String? tags;
  final DateTime createdAt;

  Writeup({
    required this.id,
    required this.userId,
    required this.username,
    required this.title,
    required this.content,
    this.tags,
    required this.createdAt,
  });

  factory Writeup.fromMap(Map<String, dynamic> map) {
    return Writeup(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      username: map['username'] as String? ?? 'local',
      title: map['title'] as String,
      content: map['content'] as String,
      tags: map['tags'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class UserXP {
  final int userId;
  final int totalXP;
  final int level;

  UserXP({
    required this.userId,
    required this.totalXP,
    required this.level,
  });

  factory UserXP.fromMap(Map<String, dynamic> map) {
    return UserXP(
      userId: map['user_id'] as int,
      totalXP: map['total_xp'] as int,
      level: map['level'] as int,
    );
  }
}

class Achievement {
  final int id;
  final int userId;
  final String badgeId;
  final String badgeName;
  final String badgeIcon;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.badgeName,
    required this.badgeIcon,
    required this.unlockedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      badgeId: map['badge_id'] as String,
      badgeName: map['badge_name'] as String,
      badgeIcon: map['badge_icon'] as String,
      unlockedAt: DateTime.parse(map['unlocked_at'] as String),
    );
  }
}

class FeedItem {
  final String type;
  final int id;
  final int userId;
  final String username;
  final String itemTitle;
  final DateTime timestamp;

  FeedItem({
    required this.type,
    required this.id,
    required this.userId,
    required this.username,
    required this.itemTitle,
    required this.timestamp,
  });
}

class GamificationData {
  final int totalXP;
  final int level;
  final String rankTitle;
  final int nextLevelXP;
  final double progressToNext;
  final List<Achievement> achievements;

  GamificationData({
    required this.totalXP,
    required this.level,
    required this.rankTitle,
    required this.nextLevelXP,
    required this.progressToNext,
    required this.achievements,
  });
}
