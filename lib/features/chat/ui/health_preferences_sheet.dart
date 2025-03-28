import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcompanion/features/shared/models/user_health_preferences.dart';

class HealthPreferencesSheet extends StatefulWidget {
  final UserHealthPreferences? initialPreferences;
  final Function(UserHealthPreferences) onSave;

  const HealthPreferencesSheet({
    super.key,
    this.initialPreferences,
    required this.onSave,
  });

  @override
  State<HealthPreferencesSheet> createState() => _HealthPreferencesSheetState();
}

class _HealthPreferencesSheetState extends State<HealthPreferencesSheet> {
  late final TextEditingController _caloriesController;
  String? _selectedDietType;
  final List<String> _allergies = [];
  final List<String> _healthGoals = [];

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController(
      text: widget.initialPreferences?.targetCalories?.toString(),
    );
    _selectedDietType = widget.initialPreferences?.dietType;
    _allergies.addAll(widget.initialPreferences?.allergies ?? []);
    _healthGoals.addAll(widget.initialPreferences?.healthGoals ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Preferences',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedDietType,
            decoration: const InputDecoration(
              labelText: 'Diet Type',
              border: OutlineInputBorder(),
            ),
            items: ['Vegetarian', 'Non-Vegetarian', 'Vegan']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => _selectedDietType = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caloriesController,
            decoration: const InputDecoration(
              labelText: 'Daily Target Calories',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              'Weight Loss',
              'Muscle Gain',
              'Maintenance',
              'Better Health'
            ].map((goal) {
              final isSelected = _healthGoals.contains(goal);
              return FilterChip(
                label: Text(goal),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _healthGoals.add(goal);
                    } else {
                      _healthGoals.remove(goal);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final prefs = UserHealthPreferences(
                  dietType: _selectedDietType,
                  targetCalories: int.tryParse(_caloriesController.text),
                  healthGoals: _healthGoals,
                  allergies: _allergies,
                );
                widget.onSave(prefs);
                Navigator.pop(context);
              },
              child: const Text('Save Preferences'),
            ),
          ),
        ],
      ),
    );
  }
}
