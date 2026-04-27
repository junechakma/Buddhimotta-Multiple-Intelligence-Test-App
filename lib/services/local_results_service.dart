import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalResultsService {
  // MI test keys
  static const _scoresKey = 'mi_scores';
  static const _percentagesKey = 'mi_percentages';
  static const _dateKey = 'mi_last_test_date';

  // Scenario test keys
  static const _scenarioScoresKey = 'scenario_scores';
  static const _scenarioPercentagesKey = 'scenario_percentages';
  static const _scenarioDateKey = 'scenario_last_test_date';

  static Future<void> save({
    required Map<String, int> scores,
    required Map<String, double> percentages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scoresKey, json.encode(scores));
    await prefs.setString(_percentagesKey, json.encode(percentages));
    await prefs.setString(_dateKey, DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresStr = prefs.getString(_scoresKey);
    final pctStr = prefs.getString(_percentagesKey);
    if (scoresStr == null || pctStr == null) return null;
    return {
      'scores': json.decode(scoresStr) as Map<String, dynamic>,
      'percentages': json.decode(pctStr) as Map<String, dynamic>,
      'date': prefs.getString(_dateKey),
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scoresKey);
    await prefs.remove(_percentagesKey);
    await prefs.remove(_dateKey);
  }

  static Future<void> saveScenario({
    required Map<String, int> scores,
    required Map<String, double> percentages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scenarioScoresKey, json.encode(scores));
    await prefs.setString(_scenarioPercentagesKey, json.encode(percentages));
    await prefs.setString(_scenarioDateKey, DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>?> loadScenario() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresStr = prefs.getString(_scenarioScoresKey);
    final pctStr = prefs.getString(_scenarioPercentagesKey);
    if (scoresStr == null || pctStr == null) return null;
    return {
      'scores': json.decode(scoresStr) as Map<String, dynamic>,
      'percentages': json.decode(pctStr) as Map<String, dynamic>,
      'date': prefs.getString(_scenarioDateKey),
    };
  }

  static Future<void> clearScenario() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scenarioScoresKey);
    await prefs.remove(_scenarioPercentagesKey);
    await prefs.remove(_scenarioDateKey);
  }
}
