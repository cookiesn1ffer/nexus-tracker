import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Rule> _rules = [];
  List<Rule> get rules => _rules;

  List<ChecklistLog> _completions = [];
  List<ChecklistLog> get completions => _completions;

  List<FeedItem> _feed = [];
  List<FeedItem> get feed => _feed;

  GamificationData? _gamification;
  GamificationData? get gamification => _gamification;

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  List<Writeup> _writeups = [];
  List<Writeup> get writeups => _writeups;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> loadDashboardData(String today) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _rules = await _db.getAllRules();
      _completions = await _db.getChecklistsForDate(today);
      _feed = await _db.getFeed();
      _gamification = await _db.getGamification();
      _stats = await _db.getStats(today);
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> toggleRule(int ruleId, String date) async {
    try {
      final result = await _db.toggleChecklist(ruleId, date);
      await loadDashboardData(date);
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'checked': false};
    }
  }

  Future<void> addRule(String title, String description, String frequency, String difficulty) async {
    try {
      await _db.insertRule(Rule(
        id: 0,
        title: title,
        description: description,
        frequency: frequency,
        difficulty: difficulty,
        createdBy: 1,
        createdAt: DateTime.now(),
      ));
      _rules = await _db.getAllRules();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRule(int id, String title, String description, String frequency, String difficulty) async {
    try {
      await _db.updateRule(id, title, description, frequency, difficulty);
      _rules = await _db.getAllRules();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRule(int id) async {
    try {
      await _db.deleteRule(id);
      _rules = await _db.getAllRules();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadWriteups() async {
    try {
      _writeups = await _db.getAllWriteups();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addWriteup(String title, String content, String? tags) async {
    try {
      await _db.insertWriteup(title, content, tags);
      _writeups = await _db.getAllWriteups();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateWriteup(int id, String title, String content, String? tags) async {
    try {
      await _db.updateWriteup(id, title, content, tags);
      _writeups = await _db.getAllWriteups();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteWriteup(int id) async {
    try {
      await _db.deleteWriteup(id);
      _writeups = await _db.getAllWriteups();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadAnalytics(String today) async {
    try {
      _stats = await _db.getStats(today);
      _gamification = await _db.getGamification();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> resetAllData() async {
    try {
      await _db.resetAllData();
      // Reload all screens
      final today =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      await loadDashboardData(today);
      await loadWriteups();
      await loadAnalytics(today);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
