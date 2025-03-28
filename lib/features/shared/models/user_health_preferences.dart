class UserHealthPreferences {
  final String? dietType; // veg, non-veg, vegan
  final List<String> allergies;
  final List<String> healthGoals; // weight loss, muscle gain, etc.
  final Map<String, dynamic>? restrictions; // any dietary restrictions
  final int? targetCalories;

  UserHealthPreferences({
    this.dietType,
    this.allergies = const [],
    this.healthGoals = const [],
    this.restrictions,
    this.targetCalories,
  });

  Map<String, dynamic> toJson() => {
        'dietType': dietType,
        'allergies': allergies,
        'healthGoals': healthGoals,
        'restrictions': restrictions,
        'targetCalories': targetCalories,
      };

  factory UserHealthPreferences.fromJson(Map<String, dynamic> json) {
    return UserHealthPreferences(
      dietType: json['dietType'],
      allergies: List<String>.from(json['allergies'] ?? []),
      healthGoals: List<String>.from(json['healthGoals'] ?? []),
      restrictions: json['restrictions'],
      targetCalories: json['targetCalories'],
    );
  }

  String toPrompt() {
    return '''
User Health Profile:
- Diet Type: $dietType
- Allergies: ${allergies.join(', ')}
- Health Goals: ${healthGoals.join(', ')}
- Daily Target Calories: ${targetCalories ?? 'Not specified'}
${restrictions != null ? '- Additional Restrictions: $restrictions' : ''}

Please consider these preferences when providing nutrition advice.
''';
  }
}
