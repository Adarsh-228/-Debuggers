import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcompanion/features/logs/cubit/meal_log_cubit.dart';
import 'package:healthcompanion/features/logs/cubit/meal_log_state.dart';
import 'package:healthcompanion/features/logs/data/models/meal_log_model.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class MealHistory extends StatefulWidget {
  const MealHistory({super.key});

  @override
  State<MealHistory> createState() => _MealHistoryState();
}

class _MealHistoryState extends State<MealHistory> {
  @override
  void initState() {
    super.initState();
    context.read<MealLogCubit>().loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal History', style: GoogleFonts.poppins()),
      ),
      body: BlocBuilder<MealLogCubit, MealLogState>(
        builder: (context, state) {
          if (state.history.isEmpty) {
            return Center(
              child: Text(
                'No meal history yet',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          final logs = state.history.reversed.toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) => _LogCard(log: logs[index]),
          );
        },
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final MealLogModel log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          DateFormat('MMM dd, yyyy').format(log.timestamp),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          timeago.format(log.timestamp),
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
        children: [
          _buildMealSection('Breakfast', log.breakfast),
          _buildMealSection('Lunch', log.lunch),
          _buildMealSection('Snacks', log.snacks),
          _buildMealSection('Dinner', log.dinner),
        ],
      ),
    );
  }

  Widget _buildMealSection(String title, List<FoodItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ...items.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: item.quantity != null ? Text(item.quantity!) : null,
              )),
          if (items.isEmpty)
            Text('No items', style: GoogleFonts.poppins(color: Colors.grey)),
          const Divider(),
        ],
      ),
    );
  }
}
