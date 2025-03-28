import 'package:equatable/equatable.dart';
import 'package:healthcompanion/features/logs/data/models/meal_log_model.dart';

class MealLogState extends Equatable {
  final List<FoodItem> breakfast;
  final List<FoodItem> lunch;
  final List<FoodItem> snacks;
  final List<FoodItem> dinner;

  const MealLogState({
    required this.breakfast,
    required this.lunch,
    required this.snacks,
    required this.dinner,
  });

  factory MealLogState.initial() => const MealLogState(
        breakfast: [],
        lunch: [],
        snacks: [],
        dinner: [],
      );

  bool get hasMinimumMeals => lunch.isNotEmpty && dinner.isNotEmpty;

  MealLogState copyWith({
    List<FoodItem>? breakfast,
    List<FoodItem>? lunch,
    List<FoodItem>? snacks,
    List<FoodItem>? dinner,
  }) {
    return MealLogState(
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      snacks: snacks ?? this.snacks,
      dinner: dinner ?? this.dinner,
    );
  }

  @override
  List<Object?> get props => [breakfast, lunch, snacks, dinner];
}
