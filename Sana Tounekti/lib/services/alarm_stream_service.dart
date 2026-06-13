import 'dart:async';
import 'package:alarm/alarm.dart';

/// Service global pour gérer l'écoute des alarmes
/// Évite les erreurs "Stream has already been listened to"
class AlarmStreamService {
  static final AlarmStreamService _instance = AlarmStreamService._internal();
  factory AlarmStreamService() => _instance;
  AlarmStreamService._internal();

  final _controller = StreamController<AlarmSettings>.broadcast();
  StreamSubscription<AlarmSettings>? _masterSubscription;
  bool _isInitialized = false;

  /// Écouter les alarmes via un broadcast stream
  Stream<AlarmSettings> get alarmStream {
    _ensureInitialized();
    return _controller.stream;
  }

  /// S'assure qu'on est abonné au stream
  void _ensureInitialized() {
    if (!_isInitialized) {
      _isInitialized = true;
      _masterSubscription = Alarm.ringStream.stream.listen((alarmSettings) {
        _controller.add(alarmSettings);
      });
    }
  }

  void dispose() {
    _masterSubscription?.cancel();
    _masterSubscription = null;
    _controller.close();
    _isInitialized = false;
  }
}
