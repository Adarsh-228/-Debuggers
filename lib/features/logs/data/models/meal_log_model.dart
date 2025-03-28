import 'package:equatable/equatable.dart';

class MealLogModel extends Equatable {
  final String id;
  final DateTime timestamp;
  final MealType type;
  final List<FoodItem> items;

  const MealLogModel({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory MealLogModel.fromJson(Map<String, dynamic> json) => MealLogModel(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        type: MealType.values.byName(json['type']),
        items: (json['items'] as List)
            .map((item) => FoodItem.fromJson(item))
            .toList(),
      );

  @override
  List<Object?> get props => [id, timestamp, type, items];
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
