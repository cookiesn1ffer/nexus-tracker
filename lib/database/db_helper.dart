import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nexus.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final directory = await getApplicationSupportDirectory();
    final dbPath = join(directory.path, fileName);
    final factory = databaseFactoryIo;
    final db = await factory.openDatabase(dbPath);
    await _createDB(db);
    return db;
  }

  Future<void> _createDB(Database db) async {
    // Ensure default user exists
    final userStore = intMapStoreFactory.store('users');
    final existing = await userStore.findFirst(db,
        finder: Finder(filter: Filter.equals('id', 1)));
    if (existing == null) {
      await userStore.add(db, {
        'id': 1,
        'username': 'local',
        'password_hash': '',
        'is_admin': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Ensure default XP exists
    final xpStore = intMapStoreFactory.store('user_xp');
    final existingXP = await xpStore.findFirst(db,
        finder: Finder(filter: Filter.equals('user_id', 1)));
    if (existingXP == null) {
      await xpStore.add(db, {
        'user_id': 1,
        'total_xp': 0,
        'level': 1,
      });
    }
  }

  // ========== RULES ==========
  Future<List<Rule>> getAllRules() async {
    final db = await database;
    final store = intMapStoreFactory.store('rules');
    final records = await store.find(db,
        finder: Finder(sortOrders: [SortOrder('created_at', false)]));
    return records.map((r) {
      final map = Map<String, dynamic>.from(r.value);
      map['id'] = r.key;
      return Rule.fromMap(map);
    }).toList();
  }

  Future<int> insertRule(Rule rule) async {
    final db = await database;
    final store = intMapStoreFactory.store('rules');
    return await store.add(db, {
      'title': rule.title,
      'description': rule.description,
      'frequency': rule.frequency,
      'difficulty': rule.difficulty,
      'created_by': rule.createdBy,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteRule(int id) async {
    final db = await database;
    final store = intMapStoreFactory.store('rules');
    // Delete associated checklist logs first
    final logStore = intMapStoreFactory.store('checklist_logs');
    await logStore.delete(db,
        finder: Finder(filter: Filter.equals('rule_id', id)));
    await store.delete(db, finder: Finder(filter: Filter.equals(Field.key, id)));
  }

  // ========== CHECKLISTS ==========
  Future<List<ChecklistLog>> getChecklistsForDate(String date) async {
    final db = await database;
    final store = intMapStoreFactory.store('checklist_logs');
    final records = await store.find(db,
        finder: Finder(filter: Filter.equals('completed_date', date)));
    return records.map((r) {
      final map = Map<String, dynamic>.from(r.value);
      map['id'] = r.key;
      return ChecklistLog.fromMap(map);
    }).toList();
  }

  Future<Map<String, dynamic>> toggleChecklist(int ruleId, String date) async {
    final db = await database;
    final store = intMapStoreFactory.store('checklist_logs');
    final existing = await store.findFirst(db,
        finder: Finder(filter: Filter.and([
          Filter.equals('user_id', 1),
          Filter.equals('rule_id', ruleId),
          Filter.equals('completed_date', date),
        ])));

    if (existing != null) {
      await store.delete(db,
          finder: Finder(filter: Filter.equals(Field.key, existing.key)));
      await _awardXP(-25);
      return {'checked': false, 'ruleId': ruleId};
    } else {
      await store.add(db, {
        'user_id': 1,
        'rule_id': ruleId,
        'completed_date': date,
        'completed_at': DateTime.now().toIso8601String(),
      });
      final xpResult = await _awardXP(25);
      return {'checked': true, 'ruleId': ruleId, 'xpResult': xpResult};
    }
  }

  // ========== WRITEUPS ==========
  Future<List<Writeup>> getAllWriteups() async {
    final db = await database;
    final store = intMapStoreFactory.store('writeups');
    final records = await store.find(db,
        finder: Finder(sortOrders: [SortOrder('created_at', false)]));

    final writeups = <Writeup>[];
    for (final r in records) {
      final map = Map<String, dynamic>.from(r.value);
      map['id'] = r.key;
      map['username'] = 'local';
      writeups.add(Writeup.fromMap(map));
    }
    return writeups;
  }

  Future<int> insertWriteup(String title, String content, String? tags) async {
    final db = await database;
    final store = intMapStoreFactory.store('writeups');
    return await store.add(db, {
      'user_id': 1,
      'title': title,
      'content': content,
      'tags': tags,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteWriteup(int id) async {
    final db = await database;
    final store = intMapStoreFactory.store('writeups');
    await store.delete(db, finder: Finder(filter: Filter.equals(Field.key, id)));
  }

  // ========== STATS ==========
  Future<List<FeedItem>> getFeed() async {
    final db = await database;
    final logStore = intMapStoreFactory.store('checklist_logs');
    final writeupStore = intMapStoreFactory.store('writeups');

    final logs = await logStore.find(db,
        finder: Finder(sortOrders: [SortOrder('completed_at', false)], limit: 25));
    final writeups = await writeupStore.find(db,
        finder: Finder(sortOrders: [SortOrder('created_at', false)], limit: 25));

    final allItems = <FeedItem>[];

    for (final r in logs) {
      final ruleId = r.value['rule_id'] as int;
      final ruleStore = intMapStoreFactory.store('rules');
      final rule = await ruleStore.findFirst(db,
          finder: Finder(filter: Filter.equals(Field.key, ruleId)));
      allItems.add(FeedItem(
        type: 'checklist',
        id: r.key,
        userId: r.value['user_id'] as int,
        username: 'local',
        itemTitle: rule?.value['title'] as String? ?? 'Unknown',
        timestamp: DateTime.parse(r.value['completed_at'] as String),
      ));
    }

    for (final r in writeups) {
      allItems.add(FeedItem(
        type: 'writeup',
        id: r.key,
        userId: r.value['user_id'] as int,
        username: 'local',
        itemTitle: r.value['title'] as String,
        timestamp: DateTime.parse(r.value['created_at'] as String),
      ));
    }

    allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allItems.take(50).toList();
  }

  Future<Map<String, dynamic>> getStats(String today) async {
    final db = await database;
    final store = intMapStoreFactory.store('checklist_logs');
    final records = await store.find(db,
        finder: Finder(sortOrders: [SortOrder('completed_date', true)]));

    final dates = records
        .map((r) => r.value['completed_date'] as String)
        .toSet()
        .toList();
    dates.sort();

    final streaks = _calculateStreaks(dates, today);

    return {
      'completedCount': records.length,
      'currentStreak': streaks['currentStreak'],
      'maxStreak': streaks['maxStreak'],
      'completedDates': dates,
    };
  }

  Map<String, int> _calculateStreaks(List<String> dates, String todayStr) {
    if (dates.isEmpty) return {'currentStreak': 0, 'maxStreak': 0};

    final dateSet = dates.toSet();
    final today = DateTime.parse(todayStr);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    int currentStreak = 0;
    if (dateSet.contains(todayStr) || dateSet.contains(yesterdayStr)) {
      var check = dateSet.contains(todayStr) ? today : yesterday;
      while (true) {
        final checkStr =
            '${check.year}-${check.month.toString().padLeft(2, '0')}-${check.day.toString().padLeft(2, '0')}';
        if (!dateSet.contains(checkStr)) break;
        currentStreak++;
        check = check.subtract(const Duration(days: 1));
      }
    }

    int maxStreak = 0;
    int currStreak = 0;
    for (int i = 0; i < dates.length; i++) {
      if (i == 0) {
        currStreak = 1;
      } else {
        final prev = DateTime.parse(dates[i - 1]);
        final curr = DateTime.parse(dates[i]);
        final diff = curr.difference(prev).inDays;
        if (diff == 1) {
          currStreak++;
        } else {
          currStreak = 1;
        }
      }
      if (currStreak > maxStreak) maxStreak = currStreak;
    }

    return {'currentStreak': currentStreak, 'maxStreak': maxStreak};
  }

  // ========== GAMIFICATION ==========
  Future<GamificationData> getGamification() async {
    final db = await database;
    final xpStore = intMapStoreFactory.store('user_xp');
    final record = await xpStore.findFirst(db,
        finder: Finder(filter: Filter.equals('user_id', 1)));

    final totalXP = (record?.value['total_xp'] ?? 0) as int;
    final level = (record?.value['level'] ?? 1) as int;

    final achStore = intMapStoreFactory.store('achievements');
    final achRecords = await achStore.find(db,
        finder: Finder(filter: Filter.equals('user_id', 1)));
    final achievements = achRecords.map((r) {
      final map = Map<String, dynamic>.from(r.value);
      map['id'] = r.key;
      return Achievement.fromMap(map);
    }).toList();

    final nextLevelXP = level * 100;
    final currentLevelBase = (level - 1) * 100;
    final progress = totalXP >= nextLevelXP
        ? 1.0
        : (totalXP - currentLevelBase) / 100;

    return GamificationData(
      totalXP: totalXP,
      level: level,
      rankTitle: _getRankTitle(level),
      nextLevelXP: nextLevelXP,
      progressToNext: progress,
      achievements: achievements,
    );
  }

  Future<Map<String, dynamic>> _awardXP(int amount) async {
    final db = await database;
    final xpStore = intMapStoreFactory.store('user_xp');
    final record = await xpStore.findFirst(db,
        finder: Finder(filter: Filter.equals('user_id', 1)));

    int totalXP = (record?.value['total_xp'] ?? 0) as int;
    int level = (record?.value['level'] ?? 1) as int;

    totalXP += amount;
    final oldLevel = level;
    while (totalXP >= level * 100) {
      level++;
    }

    if (record != null) {
      await xpStore.update(db, {
        'total_xp': totalXP,
        'level': level,
      }, finder: Finder(filter: Filter.equals(Field.key, record.key)));
    }

    // Check achievements
    if (totalXP >= 100 && !(await _hasAchievement('first_100')))
      await _unlockAchievement('first_100', 'Century', '100');
    if (totalXP >= 500 && !(await _hasAchievement('first_500')))
      await _unlockAchievement('first_500', 'High Roller', 'dice');
    if (level >= 5 && !(await _hasAchievement('level_5')))
      await _unlockAchievement('level_5', 'Veteran', 'medal');

    return {
      'leveledUp': level > oldLevel,
      'newLevel': level,
      'totalXP': totalXP,
    };
  }

  Future<bool> _hasAchievement(String badgeId) async {
    final db = await database;
    final store = intMapStoreFactory.store('achievements');
    final result = await store.findFirst(db,
        finder: Finder(filter: Filter.and([
          Filter.equals('user_id', 1),
          Filter.equals('badge_id', badgeId),
        ])));
    return result != null;
  }

  Future<void> _unlockAchievement(String badgeId, String name, String icon) async {
    final db = await database;
    final store = intMapStoreFactory.store('achievements');
    await store.add(db, {
      'user_id': 1,
      'badge_id': badgeId,
      'badge_name': name,
      'badge_icon': icon,
      'unlocked_at': DateTime.now().toIso8601String(),
    });
  }

  String _getRankTitle(int level) {
    if (level < 3) return 'Novice';
    if (level < 6) return 'Apprentice';
    if (level < 10) return 'Journeyman';
    if (level < 15) return 'Expert';
    if (level < 20) return 'Master';
    return 'Legend';
  }

  Future<void> resetAllData() async {
    final db = await database;
    await intMapStoreFactory.store('rules').delete(db);
    await intMapStoreFactory.store('checklist_logs').delete(db);
    await intMapStoreFactory.store('writeups').delete(db);
    await intMapStoreFactory.store('user_xp').delete(db);
    await intMapStoreFactory.store('achievements').delete(db);
    // Do NOT delete users store — just reset XP
    final xpStore = intMapStoreFactory.store('user_xp');
    await xpStore.add(db, {
      'user_id': 1,
      'total_xp': 0,
      'level': 1,
    });
  }
}
