import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalResultsService {
  // ── MI test ────────────────────────────────────────────────────────────────
  static const _scoresKey = 'mi_scores';
  static const _percentagesKey = 'mi_percentages';
  static const _dateKey = 'mi_last_test_date';
  static const _answerIndicesKey = 'mi_answer_indices';
  static const _categoryTimesKey = 'mi_category_times';
  static const _questionTimesKey = 'mi_question_times';
  static const _totalTimeKey = 'mi_total_time';

  static Future<void> save({
    required Map<String, int> scores,
    required Map<String, double> percentages,
    Map<String, List<int>>? answerIndices,
    Map<String, int>? categoryTimeSeconds,
    Map<String, List<int>>? questionTimeSeconds,
    int? totalTimeSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scoresKey, json.encode(scores));
    await prefs.setString(_percentagesKey, json.encode(percentages));
    await prefs.setString(_dateKey, DateTime.now().toIso8601String());
    if (answerIndices != null) {
      await prefs.setString(_answerIndicesKey, json.encode(answerIndices));
    }
    if (categoryTimeSeconds != null) {
      await prefs.setString(_categoryTimesKey, json.encode(categoryTimeSeconds));
    }
    if (questionTimeSeconds != null) {
      await prefs.setString(_questionTimesKey, json.encode(questionTimeSeconds));
    }
    if (totalTimeSeconds != null) {
      await prefs.setInt(_totalTimeKey, totalTimeSeconds);
    }
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresStr = prefs.getString(_scoresKey);
    final pctStr = prefs.getString(_percentagesKey);
    if (scoresStr == null || pctStr == null) return null;

    final Map<String, dynamic> result = {
      'scores': json.decode(scoresStr) as Map<String, dynamic>,
      'percentages': json.decode(pctStr) as Map<String, dynamic>,
      'date': prefs.getString(_dateKey),
    };

    final aiStr = prefs.getString(_answerIndicesKey);
    if (aiStr != null) result['answerIndices'] = json.decode(aiStr);

    final ctStr = prefs.getString(_categoryTimesKey);
    if (ctStr != null) result['categoryTimeSeconds'] = json.decode(ctStr);

    final qtStr = prefs.getString(_questionTimesKey);
    if (qtStr != null) result['questionTimeSeconds'] = json.decode(qtStr);

    final tt = prefs.getInt(_totalTimeKey);
    if (tt != null) result['totalTimeSeconds'] = tt;

    return result;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scoresKey);
    await prefs.remove(_percentagesKey);
    await prefs.remove(_dateKey);
    await prefs.remove(_answerIndicesKey);
    await prefs.remove(_categoryTimesKey);
    await prefs.remove(_questionTimesKey);
    await prefs.remove(_totalTimeKey);
  }

  // ── Scenario test ──────────────────────────────────────────────────────────
  static const _scenarioScoresKey = 'scenario_scores';
  static const _scenarioPercentagesKey = 'scenario_percentages';
  static const _scenarioDateKey = 'scenario_last_test_date';
  static const _scenarioChoicesKey = 'scenario_choices';
  static const _scenarioTimesKey = 'scenario_times';
  static const _scenarioTotalTimeKey = 'scenario_total_time';

  static Future<void> saveScenario({
    required Map<String, int> scores,
    required Map<String, double> percentages,
    List<String>? choices,
    List<int>? scenarioTimesSeconds,
    int? totalTimeSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scenarioScoresKey, json.encode(scores));
    await prefs.setString(_scenarioPercentagesKey, json.encode(percentages));
    await prefs.setString(_scenarioDateKey, DateTime.now().toIso8601String());
    if (choices != null) {
      await prefs.setString(_scenarioChoicesKey, json.encode(choices));
    }
    if (scenarioTimesSeconds != null) {
      await prefs.setString(_scenarioTimesKey, json.encode(scenarioTimesSeconds));
    }
    if (totalTimeSeconds != null) {
      await prefs.setInt(_scenarioTotalTimeKey, totalTimeSeconds);
    }
  }

  static Future<Map<String, dynamic>?> loadScenario() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresStr = prefs.getString(_scenarioScoresKey);
    final pctStr = prefs.getString(_scenarioPercentagesKey);
    if (scoresStr == null || pctStr == null) return null;

    final Map<String, dynamic> result = {
      'scores': json.decode(scoresStr) as Map<String, dynamic>,
      'percentages': json.decode(pctStr) as Map<String, dynamic>,
      'date': prefs.getString(_scenarioDateKey),
    };

    final choicesStr = prefs.getString(_scenarioChoicesKey);
    if (choicesStr != null) {
      result['choices'] = json.decode(choicesStr) as List<dynamic>;
    }

    final timesStr = prefs.getString(_scenarioTimesKey);
    if (timesStr != null) {
      result['scenarioTimesSeconds'] = json.decode(timesStr) as List<dynamic>;
    }

    final tt = prefs.getInt(_scenarioTotalTimeKey);
    if (tt != null) result['totalTimeSeconds'] = tt;

    return result;
  }

  static Future<void> clearScenario() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scenarioScoresKey);
    await prefs.remove(_scenarioPercentagesKey);
    await prefs.remove(_scenarioDateKey);
    await prefs.remove(_scenarioChoicesKey);
    await prefs.remove(_scenarioTimesKey);
    await prefs.remove(_scenarioTotalTimeKey);
  }
}
