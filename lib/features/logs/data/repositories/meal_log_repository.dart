import 'dart:convert';

import 'package:healthcompanion/features/logs/data/models/meal_log_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealLogRepository {
  static const _kMealLogsKey = 'meal_logs';
  final SharedPreferences _prefs;

  MealLogRepository(this._prefs);

  Future<void> saveMealLogs(List<MealLogModel> logs) async {
    final jsonLogs = logs.map((log) => log.toJson()).toList();
    await _prefs.setString(_kMealLogsKey, jsonEncode(jsonLogs));
  }

  Future<List<MealLogModel>> getMealLogs() async {
    final jsonString = _prefs.getString(_kMealLogsKey);
    if (jsonString == null) return [];

    final jsonLogs = jsonDecode(jsonString) as List;
    return jsonLogs.map((json) => MealLogModel.fromJson(json)).toList();
  }

  Future<void> clearLogs() async {
    await _prefs.remove(_kMealLogsKey);
  }
}
