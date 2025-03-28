import 'package:healthcompanion/features/logs/data/models/meal_log_model.dart';

class MealSuggestions {
  static const Map<MealType, List<String>> indianMeals = {
    MealType.breakfast: [
      'Idli Sambar',
      'Poha',
      'Upma',
      'Paratha with Curd',
      'Dosa',
      'Aloo Paratha',
      'Uttapam',
      'Vada Sambar',
      'Besan Chilla',
      'Masala Dosa',
    ],
    MealType.lunch: [
      'Dal Chawal',
      'Roti Sabzi',
      'Rajma Chawal',
      'Chole Bhature',
      'Biryani',
      'Thali (Dal, Roti, Sabzi, Rice)',
      'Kadhi Chawal',
      'Pulao',
      'Dal Makhani with Naan',
      'Paneer Butter Masala with Roti',
    ],
    MealType.snacks: [
      'Samosa',
      'Pakora',
      'Bhel Puri',
      'Pani Puri',
      'Dhokla',
      'Vada Pav',
      'Pav Bhaji',
      'Aloo Tikki',
      'Dahi Puri',
      'Chaat',
    ],
    MealType.dinner: [
      'Dal Roti',
      'Sabzi Roti',
      'Pulao',
      'Khichdi',
      'Palak Paneer with Roti',
      'Mixed Veg Curry with Roti',
      'Dal Fry with Rice',
      'Jeera Rice with Dal',
      'Vegetable Biryani',
      'Roti with Curry',
    ],
  };

  static List<String> getSuggestions(MealType type) {
    return indianMeals[type] ?? [];
  }
}
