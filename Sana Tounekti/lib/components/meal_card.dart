import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/models/meal_recommendation.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final String language;
  final bool compact;

  const MealCard({
    super.key,
    required this.meal,
    this.language = 'en',
    this.compact = false,
  });

  IconData _mealIcon() {
    switch (meal.type) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'dinner':
        return Icons.nights_stay;
      case 'snack':
        return Icons.coffee;
      default:
        return Icons.restaurant;
    }
  }

  Color _mealColor() {
    switch (meal.type) {
      case 'breakfast':
        return const Color(0xFFFF9800);
      case 'lunch':
        return const Color(0xFF4CAF50);
      case 'dinner':
        return const Color(0xFF1565C0);
      case 'snack':
        return const Color(0xFF9C27B0);
      default:
        return const Color.fromRGBO(7, 82, 96, 1);
    }
  }

  String _typeLabel(BuildContext context) {
    switch (meal.type) {
      case 'breakfast':
        return translation(context).mealBreakfast;
      case 'lunch':
        return translation(context).mealLunch;
      case 'dinner':
        return translation(context).mealDinner;
      case 'snack':
        return translation(context).mealSnack;
      default:
        return meal.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    final color = _mealColor();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(_mealIcon(), color: color, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _typeLabel(context),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${meal.calories} kcal',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.getName(language),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: meal.nutrients.map((n) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(n, style: GoogleFonts.roboto(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, size: 18, color: Color.fromRGBO(7, 82, 96, 1)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            meal.getBrainBenefit(language),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: const Color.fromRGBO(7, 82, 96, 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final color = _mealColor();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(_mealIcon(), color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  _typeLabel(context),
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
                const Spacer(),
                Text('${meal.calories}', style: GoogleFonts.roboto(fontSize: 11, color: color)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              meal.getName(language),
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
