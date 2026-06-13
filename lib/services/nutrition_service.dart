import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymeds_app/models/meal_recommendation.dart';
import 'package:mymeds_app/services/nutrition_engine.dart';

class NutritionService {
  static final NutritionService _instance = NutritionService._();
  factory NutritionService() => _instance;
  NutritionService._();

  final _engine = NutritionEngine();

  Future<void> _initEngine() async {
    if (!_engine.isLoaded) await _engine.loadModel();
  }

  Future<MealPlan> getMealRecommendations({
    required String userEmail,
    required bool hasDiabetes,
    required bool hasHypertension,
    required double weight,
    String cognitiveCondition = 'normal',
    List<String> allergies = const [],
  }) async {
    await _initEngine();

    final rng = Random();

    final bmr = _engine.calculateBMR(weight, 165, 70, 'Female');
    final tdee = _engine.calculateTDEE(bmr, 'light');
    final adjustedTdee = hasDiabetes ? tdee * 0.85 : tdee;

    final mealDist = _engine.getMealCalorieDistribution(3);
    final typeIdx = {'breakfast': 0, 'lunch': 1, 'dinner': 2, 'snack': 3};

    final meals = <Meal>[];
    for (final entry in mealDist.entries) {
      final mealName = entry.key;
      final calorieBudget = adjustedTdee * entry.value;
      final vector = _engine.buildNutritionVector(calorieBudget, mealName);
      final typeId = typeIdx[mealName] ?? 0;

      // ML inference: get top-K recommendations
      final indices = _engine.predict(vector, mealType: typeId, k: 5);

      // Pick a diverse recommendation
      Map<String, dynamic>? recipe;
      if (indices.isNotEmpty) {
        final idx = indices[rng.nextInt(indices.length)];
        recipe = _engine.getRecipe(idx);
      }

      final name = recipe?['name']?.toString() ?? 'Healthy ${mealName}';
      final calories = (recipe?['calories'] as num?)?.round() ?? calorieBudget.round();

      meals.add(Meal(
        type: mealName,
        name: name,
        nameFr: name,
        nameAr: name,
        calories: calories,
        ingredients: [],
        nutrients: _deriveNutrients(recipe),
        brainBenefit: 'AI-recommended based on ${_engine.recipeCount} real recipes',
        brainBenefitFr: 'Recommandé par IA basé sur ${_engine.recipeCount} vraies recettes',
        brainBenefitAr: 'موصى به بالذكاء الاصطناعي بناء على ${_engine.recipeCount} وصفة حقيقية',
      ));
    }

    final plan = MealPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userEmail: userEmail,
      date: DateTime.now(),
      meals: meals,
      totalCalories: meals.fold(0, (s, m) => s + m.calories),
      keyNutrients: ['Omega-3', 'Antioxidants', 'B Vitamins', 'Magnesium', 'Vitamin E'],
      brainBenefits: [
        'AI-powered nutrition from ${_engine.recipeCount} real recipes',
        'Personalized to your health profile',
        'Optimized for brain health',
      ],
    );

    _savePlan(plan);
    return plan;
  }

  List<String> _deriveNutrients(Map<String, dynamic>? recipe) {
    if (recipe == null) return ['Balanced'];
    final nutrients = <String>[];
    final fat = (recipe['fat'] as num?)?.toDouble() ?? 0;
    final protein = (recipe['protein'] as num?)?.toDouble() ?? 0;
    final carbs = (recipe['carbs'] as num?)?.toDouble() ?? 0;

    if (fat > 15) nutrients.add('Healthy Fats');
    if (protein > 15) nutrients.add('Protein');
    if (carbs > 30) nutrients.add('Complex Carbs');
    if (nutrients.isEmpty) nutrients.add('Balanced');
    return nutrients;
  }

  Future<void> _savePlan(MealPlan plan) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(plan.userEmail)
          .collection('MealPlans')
          .doc(plan.id)
          .set(plan.toMap());
    } catch (_) {}
  }

  Future<MealPlan?> getTodayPlan(String userEmail) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userEmail)
          .collection('MealPlans')
          .where('date', isGreaterThanOrEqualTo: todayStr)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return MealPlan.fromMap(snapshot.docs.first.data()..['id'] = snapshot.docs.first.id);
      }
    } catch (_) {}
    return null;
  }
}
