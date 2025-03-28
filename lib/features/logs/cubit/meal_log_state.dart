import 'package:equatable/equatable.dart';
import 'package:healthcompanion/features/logs/data/models/meal_log_model.dart';

class MealLogState extends Equatable {
  final List<FoodItem> breakfast;
  final List<FoodItem> lunch;
  final List<FoodItem> snacks;
  final List<FoodItem> dinner;
  final List<MealLogModel> history;

  const MealLogState({
    this.breakfast = const [],
    this.lunch = const [],
    this.snacks = const [],
    this.dinner = const [],
    this.history = const [],
  });

  factory MealLogState.initial() => const MealLogState(
        breakfast: [],
        lunch: [],
        snacks: [],
        dinner: [],
        history: [],
      );

  bool get hasMinimumMeals => lunch.isNotEmpty && dinner.isNotEmpty;

  MealLogState copyWith({
    List<FoodItem>? breakfast,
    List<FoodItem>? lunch,
    List<FoodItem>? snacks,
    List<FoodItem>? dinner,
    List<MealLogModel>? history,
  }) {
    return MealLogState(
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      snacks: snacks ?? this.snacks,
      dinner: dinner ?? this.dinner,
      history: history ?? this.history,
    );
  }

  @override
  List<Object> get props => [breakfast, lunch, snacks, dinner, history];
}
