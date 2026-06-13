class MealPlan {
  final String id;
  final String userEmail;
  final DateTime date;
  final List<Meal> meals;
  final int totalCalories;
  final List<String> keyNutrients;
  final List<String> brainBenefits;

  MealPlan({
    required this.id,
    required this.userEmail,
    required this.date,
    required this.meals,
    required this.totalCalories,
    required this.keyNutrients,
    required this.brainBenefits,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userEmail': userEmail,
        'date': date.toIso8601String(),
        'meals': meals.map((m) => m.toMap()).toList(),
        'totalCalories': totalCalories,
        'keyNutrients': keyNutrients,
        'brainBenefits': brainBenefits,
      };

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'] ?? '',
      userEmail: map['userEmail'] ?? '',
      date: DateTime.parse(map['date']),
      meals: (map['meals'] as List)
          .map((m) => Meal.fromMap(m as Map<String, dynamic>))
          .toList(),
      totalCalories: map['totalCalories'] ?? 0,
      keyNutrients: List<String>.from(map['keyNutrients'] ?? []),
      brainBenefits: List<String>.from(map['brainBenefits'] ?? []),
    );
  }
}

class Meal {
  final String type;
  final String name;
  final String nameAr;
  final String nameFr;
  final int calories;
  final List<String> ingredients;
  final List<String> nutrients;
  final String brainBenefit;
  final String brainBenefitAr;
  final String brainBenefitFr;
  final String icon;

  Meal({
    required this.type,
    required this.name,
    this.nameAr = '',
    this.nameFr = '',
    required this.calories,
    required this.ingredients,
    required this.nutrients,
    required this.brainBenefit,
    this.brainBenefitAr = '',
    this.brainBenefitFr = '',
    this.icon = 'food',
  });

  String getName(String lang) {
    if (lang == 'ar' && nameAr.isNotEmpty) return nameAr;
    if (lang == 'fr' && nameFr.isNotEmpty) return nameFr;
    return name;
  }

  String getBrainBenefit(String lang) {
    if (lang == 'ar' && brainBenefitAr.isNotEmpty) return brainBenefitAr;
    if (lang == 'fr' && brainBenefitFr.isNotEmpty) return brainBenefitFr;
    return brainBenefit;
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'name': name,
        'nameAr': nameAr,
        'nameFr': nameFr,
        'calories': calories,
        'ingredients': ingredients,
        'nutrients': nutrients,
        'brainBenefit': brainBenefit,
        'brainBenefitAr': brainBenefitAr,
        'brainBenefitFr': brainBenefitFr,
        'icon': icon,
      };

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      type: map['type'] ?? '',
      name: map['name'] ?? '',
      nameAr: map['nameAr'] ?? '',
      nameFr: map['nameFr'] ?? '',
      calories: map['calories'] ?? 0,
      ingredients: List<String>.from(map['ingredients'] ?? []),
      nutrients: List<String>.from(map['nutrients'] ?? []),
      brainBenefit: map['brainBenefit'] ?? '',
      brainBenefitAr: map['brainBenefitAr'] ?? '',
      brainBenefitFr: map['brainBenefitFr'] ?? '',
      icon: map['icon'] ?? 'food',
    );
  }
}
