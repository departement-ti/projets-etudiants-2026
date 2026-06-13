import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/meal_card.dart';
import 'package:mymeds_app/models/meal_recommendation.dart';
import 'package:mymeds_app/services/nutrition_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _nutritionService = NutritionService();
  MealPlan? _plan;
  bool _loading = false;
  String _lang = 'fr';
  bool _hasDiabetes = false;
  bool _hasHypertension = false;
  double _weight = 70;
  bool _showForm = true;

  @override
  void initState() {
    super.initState();
    _loadLang();
    _loadTodayPlan();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _lang = prefs.getString('languageCode') ?? 'fr');
  }

  Future<void> _loadTodayPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    final plan = await _nutritionService.getTodayPlan(user!.email!);
    if (plan != null && mounted) {
      setState(() { _plan = plan; _showForm = false; });
    }
  }

  Future<void> _getRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    setState(() => _loading = true);
    final plan = await _nutritionService.getMealRecommendations(
      userEmail: user!.email!,
      hasDiabetes: _hasDiabetes,
      hasHypertension: _hasHypertension,
      weight: _weight,
    );
    if (mounted) {
      setState(() { _plan = plan; _showForm = false; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nutrition', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        actions: [
          if (_plan != null)
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.white),
              onPressed: () => setState(() => _showForm = true),
            ),
        ],
      ),
      body: _showForm ? _buildForm() : _buildRecommendations(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Profile', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color.fromRGBO(7, 82, 96, 1))),
          const SizedBox(height: 4),
          Text('Help us personalize your meal plan', style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildToggleCard('Diabetes', 'Do you have diabetes?', _hasDiabetes, (v) => setState(() => _hasDiabetes = v)),
          const SizedBox(height: 12),
          _buildToggleCard('Hypertension', 'High blood pressure?', _hasHypertension, (v) => setState(() => _hasHypertension = v)),
          const SizedBox(height: 20),
          Text('Weight (kg)', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: const SliderThemeData(
                        activeTrackColor: Color.fromRGBO(7, 82, 96, 1),
                        thumbColor: Color.fromRGBO(7, 82, 96, 1),
                      ),
                      child: Slider(
                        value: _weight, min: 40, max: 120, divisions: 80,
                        onChanged: (v) => setState(() => _weight = v.roundToDouble()),
                      ),
                    ),
                  ),
                  Text('${_weight.round()} kg', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _getRecommendations,
              icon: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.restaurant_menu),
              label: Text(_loading ? 'Generating...' : 'Get Meal Plan', style: GoogleFonts.poppins(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color.fromRGBO(7, 82, 96, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return RefreshIndicator(
      onRefresh: _getRecommendations,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Meal Plan', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Total: ${_plan?.totalCalories ?? 0} kcal', style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            ...(_plan?.meals.map((meal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MealCard(meal: meal, language: _lang),
            )) ?? []),
            const SizedBox(height: 16),
            if (_plan?.keyNutrients.isNotEmpty ?? false)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Key Nutrients', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _plan!.keyNutrients.map((n) => Chip(
                          label: Text(n, style: GoogleFonts.roboto(fontSize: 12)),
                          backgroundColor: const Color.fromRGBO(7, 82, 96, 1).withAlpha(20),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
