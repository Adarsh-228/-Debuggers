import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcompanion/core/constants.dart';
import 'package:healthcompanion/features/logs/cubit/meal_log_cubit.dart';
import 'package:healthcompanion/features/logs/cubit/meal_log_state.dart';
import 'package:healthcompanion/features/logs/data/meal_suggestions.dart';
import 'package:healthcompanion/features/logs/data/models/meal_log_model.dart';
import 'package:http/http.dart' as http;

class MealLogScreen extends StatelessWidget {
  const MealLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealLogCubit, MealLogState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Meal Log',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/history'),
            tooltip: 'History',
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            elevation: 1,
            child: const Icon(Icons.history),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildMealSection(
                      'Breakfast',
                      Icons.breakfast_dining,
                      state.breakfast,
                      MealType.breakfast,
                      context,
                    ),
                    _buildMealSection(
                      'Lunch',
                      Icons.lunch_dining,
                      state.lunch,
                      MealType.lunch,
                      context,
                    ),
                    _buildMealSection(
                      'Snacks',
                      Icons.cookie,
                      state.snacks,
                      MealType.snacks,
                      context,
                    ),
                    _buildMealSection(
                      'Dinner',
                      Icons.dinner_dining,
                      state.dinner,
                      MealType.dinner,
                      context,
                    ),
                  ],
                ),
              ),
              if (state.hasMinimumMeals) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Generate Insights',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Nutritional Balance'),
                            selected: true,
                            onSelected: (_) {},
                          ),
                          ChoiceChip(
                            label: const Text('Caloric Intake'),
                            selected: true,
                            onSelected: (_) {},
                          ),
                          ChoiceChip(
                            label: const Text('Suggestions'),
                            selected: true,
                            onSelected: (_) {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _generateInsights(context),
                        icon: const Icon(Icons.analytics),
                        label: const Text('Analyze Meals'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealSection(
    String title,
    IconData icon,
    List<FoodItem> items,
    MealType type,
    BuildContext context,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddMealSheet(context, type),
            ),
          ),
          if (items.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: Key('${type.name}_${item.name}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    context.read<MealLogCubit>().removeMeal(type, index);
                  },
                  child: ListTile(
                    title: Text(
                      item.name,
                      style: GoogleFonts.poppins(),
                    ),
                    subtitle: item.quantity != null
                        ? Text(
                            item.quantity!,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No items added',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddMealSheet(BuildContext context, MealType type) {
    final suggestions = MealSuggestions.getSuggestions(type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Add ${type.name.capitalize()} Item',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    title: Text(suggestion),
                    trailing: const Icon(Icons.add),
                    onTap: () {
                      context.read<MealLogCubit>().addMeal(
                            type,
                            FoodItem(name: suggestion),
                          );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateInsights(BuildContext context) {
    final state = context.read<MealLogCubit>().state;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Meal Analysis',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder(
                  future: _getGeminiInsights(state),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    return ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildInsightSection(
                          'Nutritional Balance',
                          snapshot.data?['balance'] ?? '',
                          snapshot.data?['metrics'],
                        ),
                        _buildInsightSection(
                          'Caloric Intake',
                          snapshot.data?['calories'] ?? '',
                        ),
                        _buildInsightSection(
                          'Suggestions',
                          snapshot.data?['suggestions'] ?? '',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightSection(String title, String content, [String? metrics]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (title == 'Suggestions')
              _buildSuggestions(content)
            else
              _buildFormattedText(content),
            if (metrics != null && title == 'Nutritional Balance') ...[
              const SizedBox(height: 16),
              _buildNutritionChart(jsonDecode(metrics)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text) {
    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    final defaultStyle = GoogleFonts.poppins(
      color: Colors.black87,
      fontSize: 14,
    );

    final boldStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: Colors.black87,
      fontSize: 14,
    );

    for (final Match match in exp.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text
              .substring(lastIndex, match.start)
              .replaceAll('FontWeight.w400', ''),
          style: defaultStyle,
        ));
      }

      // Add bold text
      spans.add(TextSpan(
        text: match.group(1)?.replaceAll('FontWeight.w400', '') ?? '',
        style: boldStyle,
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex).replaceAll('FontWeight.w400', ''),
        style: defaultStyle,
      ));
    }

    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: defaultStyle,
        children: spans,
      ),
    );
  }

  Widget _buildNutritionChart(Map<String, dynamic> metrics) {
    // Standard daily values (in percentage)
    const standardValues = {
      'protein': 100.0, // 100% is the target
      'carbs': 100.0,
      'fats': 100.0,
    };

    return Column(
      children: [
        _buildProgressBar(
          'Protein',
          (metrics['protein'] ?? 0).toDouble(),
          standardValues['protein']!,
          Colors.red,
        ),
        const SizedBox(height: 8),
        _buildProgressBar(
          'Carbs',
          (metrics['carbs'] ?? 0).toDouble(),
          standardValues['carbs']!,
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildProgressBar(
          'Fats',
          (metrics['fats'] ?? 0).toDouble(),
          standardValues['fats']!,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildProgressBar(
      String label, double value, double standard, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
                width: 100, child: Text(label, style: GoogleFonts.poppins())),
            Expanded(
              child: Stack(
                children: [
                  // Standard value indicator
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(
                        (standard / 100 * 2) - 1, // Convert to -1 to 1 range
                        0,
                      ),
                      child: Container(
                        width: 2,
                        color: Colors.black54,
                        height: 16,
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value / 100,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${value.round()}%',
                style: GoogleFonts.poppins(),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        Text(
          value < standard
              ? 'Need ${(standard - value).round()}% more'
              : value > standard
                  ? '${(value - standard).round()}% excess'
                  : 'Optimal level',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: value == standard
                ? Colors.green
                : value < standard
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(String suggestions) {
    // Convert string array to actual list
    final suggestionList = suggestions
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestionList
          .map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Future<Map<String, String>> _getGeminiInsights(MealLogState state) async {
    const apiKey = Constants.apiKey;
    const url = Constants.url;

    try {
      final prompt = '''
      System: You are a nutritionist analyzing a person's daily meal log. Provide concise insights (max 2-3 lines each) in the following JSON format:
      {
        "balance": "Brief analysis with key nutrients marked in **bold**",
        "calories": "Estimated total calories: **X kcal**. Brief breakdown: breakfast(**X**), lunch(**X**), snacks(**X**), dinner(**X**)",
        "suggestions": "3 bullet points with improvements",
        "metrics": {
          "protein": X,
          "carbs": X,
          "fats": X,
          "totalCalories": X
        }
      }
      
      User's meals for today:
      Breakfast: ${_formatMeals(state.breakfast)}
      Lunch: ${_formatMeals(state.lunch)}
      Snacks: ${_formatMeals(state.snacks)}
      Dinner: ${_formatMeals(state.dinner)}
      ''';

      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final text = responseData['candidates'][0]['content']['parts'][0]
            ['text'] as String;

        final startIndex = text.indexOf('{');
        final endIndex = text.lastIndexOf('}') + 1;
        final jsonStr = text.substring(startIndex, endIndex);

        final Map<String, dynamic> insights = jsonDecode(jsonStr);

        return {
          'balance': insights['balance']?.toString() ??
              'No balance analysis available',
          'calories': insights['calories']?.toString() ??
              'No caloric analysis available',
          'suggestions':
              insights['suggestions']?.toString() ?? 'No suggestions available',
          'metrics': jsonEncode(insights['metrics'] ?? {}),
        };
      }

      throw Exception('Failed to get insights');
    } catch (e, stackTrace) {
      print('Error getting insights: $e');
      print('Stack trace: $stackTrace');
      return {
        'balance': 'Error analyzing nutritional balance',
        'calories': 'Error calculating calories',
        'suggestions': 'Unable to generate suggestions',
        'metrics': '{}',
      };
    }
  }

  String _formatMeals(List<FoodItem> items) {
    if (items.isEmpty) return 'No meals logged';
    return items
        .map((item) =>
            '${item.name}${item.quantity != null ? ' (${item.quantity})' : ''}')
        .join(', ');
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
