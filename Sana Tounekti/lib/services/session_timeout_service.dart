import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Service de gestion du timeout de session
/// Déconnecte l'utilisateur après 60 minutes d'inactivité
class SessionTimeoutService {
  static final SessionTimeoutService _instance = SessionTimeoutService._();
  factory SessionTimeoutService() => _instance;
  SessionTimeoutService._();

  static const Duration _timeout = Duration(minutes: 60);
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();
  bool _isActive = false;
  VoidCallback? _onTimeout;

  /// Démarre le monitoring d'inactivité
  void start(VoidCallback onTimeout) {
    _isActive = true;
    _onTimeout = onTimeout;
    _lastActivity = DateTime.now();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isActive) return;
      final idleTime = DateTime.now().difference(_lastActivity);
      if (idleTime >= _timeout) {
        _triggerTimeout();
      }
    });

    print('⏱️ Session timeout started (60min)');
  }

  /// À appeler à chaque interaction utilisateur
  void userActivity() {
    if (!_isActive) return;
    _lastActivity = DateTime.now();
  }

  void _triggerTimeout() {
    print('⏰ Session expired - logging out');
    _timer?.cancel();
    _isActive = false;
    FirebaseAuth.instance.signOut();
    _onTimeout?.call();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
  }

  void dispose() => stop();
}

/// Wrapper qui écoute les interactions utilisateur pour détecter l'inactivité
class SessionTimeoutWrapper extends StatefulWidget {
  final Widget child;
  const SessionTimeoutWrapper({super.key, required this.child});

  @override
  State<SessionTimeoutWrapper> createState() => _SessionTimeoutWrapperState();
}

class _SessionTimeoutWrapperState extends State<SessionTimeoutWrapper> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SessionTimeoutService().userActivity(),
      child: widget.child,
    );
  }
}
