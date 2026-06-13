import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class NutritionEngine {
  static final NutritionEngine _instance = NutritionEngine._();
  factory NutritionEngine() => _instance;
  NutritionEngine._();

  final List<List<double>> _recipeMatrix = [];
  final List<double> _scalerMean = [];
  final List<double> _scalerStd = [];
  final List<int> _recipeTypes = [];
  int _nRecipes = 0;
  int _nFeatures = 0;
  int _kDefault = 5;
  bool _loaded = false;

  // Recipe metadata from real dataset
  List<Map<String, dynamic>> _recipeMeta = [];

  bool get isLoaded => _loaded;
  int get recipeCount => _nRecipes;

  Future<void> loadModel() async {
    if (_loaded) return;

    // Load binary model
    final data = await rootBundle.load('assets/models/nutrition_model.bin');
    final buffer = data.buffer.asByteData();
    var offset = 0;

    final magic = String.fromCharCodes(
      List.generate(4, (i) => buffer.getUint8(offset++))
    );
    if (magic != 'NMND') throw Exception('Bad magic: $magic');

    final version = buffer.getUint32(offset, Endian.little); offset += 4;
    _nRecipes = buffer.getUint32(offset, Endian.little); offset += 4;
    _nFeatures = buffer.getUint32(offset, Endian.little); offset += 4;
    _kDefault = buffer.getUint32(offset, Endian.little); offset += 4;

    _scalerMean.clear();
    for (var i = 0; i < _nFeatures; i++) {
      _scalerMean.add(buffer.getFloat32(offset, Endian.little)); offset += 4;
    }

    _scalerStd.clear();
    for (var i = 0; i < _nFeatures; i++) {
      _scalerStd.add(buffer.getFloat32(offset, Endian.little)); offset += 4;
    }

    _recipeTypes.clear();
    _recipeMatrix.clear();
    for (var i = 0; i < _nRecipes; i++) {
      _recipeTypes.add(buffer.getUint32(offset, Endian.little)); offset += 4;
      final row = <double>[];
      for (var j = 0; j < _nFeatures; j++) {
        row.add(buffer.getFloat32(offset, Endian.little)); offset += 4;
      }
      _recipeMatrix.add(row);
    }

    // Load recipe metadata
    try {
      final json = await rootBundle.loadString('assets/models/nutrition_recipes.json');
      final meta = jsonDecode(json);
      _recipeMeta = (meta['recipes'] as List)
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
    } catch (_) {
      _recipeMeta = [];
    }

    _loaded = true;
  }

  /// Get recipe metadata by index
  Map<String, dynamic>? getRecipe(int index) {
    if (index < 0 || index >= _recipeMeta.length) return null;
    return _recipeMeta[index];
  }

  // BMI, BMR, TDEE (unchanged)
  double calculateBMI(double weightKg, double heightCm) =>
      weightKg / ((heightCm / 100) * (heightCm / 100));

  double calculateBMR(double weightKg, double heightCm, int age, String gender) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == 'Male' ? base + 5 : base - 161;
  }

  double calculateTDEE(double bmr, String activityLevel) {
    const m = {'sedentary':1.2,'light':1.375,'moderate':1.55,'active':1.725,'very_active':1.9};
    return bmr * (m[activityLevel] ?? 1.2);
  }

  Map<String, double> getMealCalorieDistribution(int meals) {
    switch (meals) {
      case 3: return {'breakfast':0.35,'lunch':0.40,'dinner':0.25};
      case 4: return {'breakfast':0.30,'morning_snack':0.05,'lunch':0.40,'dinner':0.25};
      case 5: return {'breakfast':0.30,'morning_snack':0.05,'lunch':0.40,'afternoon_snack':0.05,'dinner':0.20};
      default: return {'breakfast':0.35,'lunch':0.40,'dinner':0.25};
    }
  }

  List<double> buildNutritionVector(double calories, String mealType) {
    Map<String, List<double>> ranges;
    switch (mealType) {
      case 'breakfast': ranges = {'fat':[10,30],'s_fat':[0,4],'chol':[0,30],'na':[0,400],'carbs':[40,75],'fib':[4,10],'sug':[0,10],'prot':[30,100]}; break;
      case 'lunch': case 'dinner': ranges = {'fat':[20,40],'s_fat':[0,4],'chol':[0,30],'na':[0,400],'carbs':[40,75],'fib':[4,20],'sug':[0,10],'prot':[50,175]}; break;
      default: ranges = {'fat':[10,30],'s_fat':[0,4],'chol':[0,30],'na':[0,400],'carbs':[40,75],'fib':[4,10],'sug':[0,10],'prot':[30,100]};
    }
    final s = calories / 500.0;
    return [
      calories,
      _mid(ranges['fat']!)*s, _mid(ranges['s_fat']!)*s, _mid(ranges['chol']!)*s,
      _mid(ranges['na']!)*s, _mid(ranges['carbs']!)*s, _mid(ranges['fib']!)*s,
      _mid(ranges['sug']!)*s, _mid(ranges['prot']!)*s,
    ];
  }

  double _mid(List<double> r) => (r[0]+r[1])/2;

  List<double> _transform(List<double> input) =>
      List.generate(_nFeatures, (j) => (input[j]-_scalerMean[j])/_scalerStd[j]);

  double _cosDist(List<double> a, List<double> b) {
    double dot=0, nA=0, nB=0;
    for(var i=0; i<a.length; i++) { dot+=a[i]*b[i]; nA+=a[i]*a[i]; nB+=b[i]*b[i]; }
    if(nA==0||nB==0) return 1.0;
    return 1.0-(dot/(sqrt(nA)*sqrt(nB)));
  }

  List<int> predict(List<double> nutritionInput, {int? mealType, int k = 5}) {
    if(!_loaded) return [];
    final q = _transform(nutritionInput);
    final dists = <_IdxDist>[];
    for(var i=0; i<_nRecipes; i++) {
      var d = _cosDist(q, _recipeMatrix[i]);
      if(mealType!=null && _recipeTypes[i]==mealType) d -= 0.2;
      dists.add(_IdxDist(i, d));
    }
    dists.sort((a,b)=>a.d.compareTo(b.d));
    return dists.take(k<dists.length?k:dists.length).map((d)=>d.idx).toList();
  }

  int get defaultK => _kDefault;
}

class _IdxDist { final int idx; final double d; _IdxDist(this.idx, this.d); }
