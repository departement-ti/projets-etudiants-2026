import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Service de détection de secousse pour déclencher l'appel SOS
class ShakeDetectorService {
  static final ShakeDetectorService _instance = ShakeDetectorService._();
  factory ShakeDetectorService() => _instance;
  ShakeDetectorService._();

  StreamSubscription<AccelerometerEvent>? _subscription;
  final List<void Function()> _listeners = [];
  bool _isActive = false;
  int _eventCount = 0;

  static const double _shakeThreshold = 12.0;
  static const int _shakeCountRequired = 3;
  static const int _shakeTimeoutMs = 1500;

  DateTime? _lastShakeTime;
  int _shakeCount = 0;

  void addListener(void Function() callback) {
    _listeners.add(callback);
    _ensureListening();
  }

  void removeListener(void Function() callback) {
    _listeners.remove(callback);
    if (_listeners.isEmpty) {
      stop();
    }
  }

  void _ensureListening() {
    if (!_isActive) {
      _isActive = true;
      try {
        _subscription = accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 100),
        ).listen(_onAccelerometerEvent);
        print('✅ ShakeDetector started - listening for 3 shakes in ${_shakeTimeoutMs}ms');
      } catch (e) {
        print('❌ ShakeDetector: Error starting accelerometer: $e');
        _isActive = false;
      }
    }
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    _eventCount++;
    // Debug: print tous les 200 events
    if (_eventCount % 200 == 0) {
      print('📳 Accel sensor active - event #$_eventCount - x:${event.x.toStringAsFixed(2)} y:${event.y.toStringAsFixed(2)} z:${event.z.toStringAsFixed(2)}');
    }

    final double magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final double acceleration = (magnitude - 9.8).abs();

    if (acceleration > _shakeThreshold) {
      print('💥 Shake detected! Accel: ${acceleration.toStringAsFixed(1)}, Count: ${_shakeCount + 1}');
      final now = DateTime.now();

      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!).inMilliseconds > _shakeTimeoutMs) {
        _shakeCount = 1;
      } else {
        _shakeCount++;
      }
      _lastShakeTime = now;

      if (_shakeCount >= _shakeCountRequired) {
        _shakeCount = 0;
        _lastShakeTime = null;
        _notifyListeners();
      }
    }
  }

  void _notifyListeners() {
    print('🚨 SOS SHAKE TRIGGERED! Notifying ${_listeners.length} listeners');
    for (final listener in List.from(_listeners)) {
      listener();
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isActive = false;
    _shakeCount = 0;
    _lastShakeTime = null;
  }

  void dispose() {
    stop();
    _listeners.clear();
  }
}
