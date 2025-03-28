import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthcompanion/features/logs/cubit/meal_log_state.dart';
import '../data/models/meal_log_model.dart';
import '../data/repositories/meal_log_repository.dart';

class MealLogCubit extends Cubit<MealLogState> {
  final MealLogRepository _repository;

  MealLogCubit(this._repository) : super(MealLogState.initial());

  Future<void> addMeal(MealType type, FoodItem item) async {
    final currentState = state;
    List<FoodItem> updatedItems;

    switch (type) {
      case MealType.breakfast:
        updatedItems = [...currentState.breakfast, item];
        emit(currentState.copyWith(breakfast: updatedItems));
        break;
      case MealType.lunch:
        updatedItems = [...currentState.lunch, item];
        emit(currentState.copyWith(lunch: updatedItems));
        break;
      case MealType.snacks:
        updatedItems = [...currentState.snacks, item];
        emit(currentState.copyWith(snacks: updatedItems));
        break;
      case MealType.dinner:
        updatedItems = [...currentState.dinner, item];
        emit(currentState.copyWith(dinner: updatedItems));
        break;
    }

    await _saveLogs();
  }

  Future<void> removeMeal(MealType type, int index) async {
    final currentState = state;
    List<FoodItem> updatedItems;

    switch (type) {
      case MealType.breakfast:
        updatedItems = List.from(currentState.breakfast)..removeAt(index);
        emit(currentState.copyWith(breakfast: updatedItems));
        break;
      case MealType.lunch:
        updatedItems = List.from(currentState.lunch)..removeAt(index);
        emit(currentState.copyWith(lunch: updatedItems));
        break;
      case MealType.snacks:
        updatedItems = List.from(currentState.snacks)..removeAt(index);
        emit(currentState.copyWith(snacks: updatedItems));
        break;
      case MealType.dinner:
        updatedItems = List.from(currentState.dinner)..removeAt(index);
        emit(currentState.copyWith(dinner: updatedItems));
        break;
    }

    await _saveLogs();
  }

  Future<void> _saveLogs() async {
    final log = MealLogModel(
      id: DateTime.now().toIso8601String(),
      timestamp: DateTime.now(),
      breakfast: state.breakfast,
      lunch: state.lunch,
      snacks: state.snacks,
      dinner: state.dinner,
    );

    final existingLogs = await _repository.getMealLogs();
    final today = DateTime.now();
    final existingIndex = existingLogs.indexWhere(
      (log) =>
          log.timestamp.year == today.year &&
          log.timestamp.month == today.month &&
          log.timestamp.day == today.day,
    );

    if (existingIndex != -1) {
      existingLogs[existingIndex] = log;
    } else {
      existingLogs.add(log);
    }

    await _repository.saveMealLogs(existingLogs);
  }

  Future<List<MealLogModel>> loadLogs() async {
    final logs = await _repository.getMealLogs();
    emit(state.copyWith(history: logs));
    return logs;
  }
}
