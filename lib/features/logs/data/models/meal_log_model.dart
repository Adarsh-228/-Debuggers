import 'package:equatable/equatable.dart';

class MealLogModel extends Equatable {
  final String id;
  final DateTime timestamp;
  final List<FoodItem> breakfast;
  final List<FoodItem> lunch;
  final List<FoodItem> snacks;
  final List<FoodItem> dinner;

  const MealLogModel({
    required this.id,
    required this.timestamp,
    required this.breakfast,
    required this.lunch,
    required this.snacks,
    required this.dinner,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'breakfast': breakfast.map((item) => item.toJson()).toList(),
        'lunch': lunch.map((item) => item.toJson()).toList(),
        'snacks': snacks.map((item) => item.toJson()).toList(),
        'dinner': dinner.map((item) => item.toJson()).toList(),
      };

  factory MealLogModel.fromJson(Map<String, dynamic> json) => MealLogModel(
        id: json['id'] as String? ?? DateTime.now().toIso8601String(),
        timestamp: DateTime.parse(
            json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
        breakfast: ((json['breakfast'] as List?) ?? [])
            .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        lunch: ((json['lunch'] as List?) ?? [])
            .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        snacks: ((json['snacks'] as List?) ?? [])
            .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        dinner: ((json['dinner'] as List?) ?? [])
            .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, timestamp, breakfast, lunch, snacks, dinner];
}

enum MealType { breakfast, lunch, snacks, dinner }

class FoodItem extends Equatable {
  final String name;
  final String? quantity;

  const FoodItem({
    required this.name,
    this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        name: json['name'],
        quantity: json['quantity'],
      );

  @override
  List<Object?> get props => [name, quantity];
}
