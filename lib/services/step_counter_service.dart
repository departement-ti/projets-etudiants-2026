import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de comptage de pas quotidien
class StepCounterService {
  static final StepCounterService _instance = StepCounterService._();
  factory StepCounterService() => _instance;
  StepCounterService._();

  StreamSubscription<StepCount>? _subscription;
  int _baselineSteps = 0;
  int _todaySteps = 0;
  bool _isActive = false;
  String? _userEmail;
  Timer? _saveTimer;

  int get todaySteps => _todaySteps;

  Future<void> start(String userEmail) async {
    if (_isActive) return;
    _isActive = true;
    _userEmail = userEmail;

    // Restaurer les pas sauvegardés
    _todaySteps = await _loadTodaySteps();

    try {
      _subscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (_baselineSteps == 0) {
            _baselineSteps = event.steps;
          }
          _todaySteps = event.steps - _baselineSteps;
          if (_todaySteps < 0) _todaySteps = 0;
          _debouncedSave();
        },
        onError: (error) {
          print('StepCounter error: $error');
        },
      );

      print('✅ StepCounter started for $userEmail');
    } catch (e) {
      print('❌ StepCounter failed: $e');
      _isActive = false;
    }
  }

  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 10), _saveSteps);
  }

  Future<void> _saveSteps() async {
    if (_userEmail == null) return;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps_$todayStr', _todaySteps);

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(_userEmail)
          .collection('StepCounts')
          .doc(todayStr)
          .set({
        'steps': _todaySteps,
        'date': todayStr,
      }, SetOptions(merge: true));
    } catch (e) {
      // Firestore error - les pas sont déjà en SharedPreferences
    }
  }

  Future<int> _loadTodaySteps() async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('steps_$todayStr') ?? 0;
  }

  static Future<int> getTodaySteps(String userEmail) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userEmail)
          .collection('StepCounts')
          .doc(todayStr)
          .get();
      return (doc.data()?['steps'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isActive = false;
    _saveTimer?.cancel();
    _saveSteps();
  }

  void dispose() => stop();
}
