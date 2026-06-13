import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _requestFcmPermissions();
    await _setupFcmToken();
    _setupMessageHandlers();

    _isInitialized = true;
  }

  Future<void> _requestFcmPermissions() async {
    if (kIsWeb) return;
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('FCM permission: ${settings.authorizationStatus}');
  }

  Future<void> _setupFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user?.email != null) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user!.email)
              .update({'fcmToken': token});

          await FirebaseFirestore.instance
              .collection('FcmTokens')
              .doc(user.email)
              .set({
            'token': token,
            'email': user.email,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }

      _fcm.onTokenRefresh.listen((newToken) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user?.email != null) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user!.email)
              .update({'fcmToken': newToken});
        }
      });
    } catch (e) {
      print('FCM token error: $e');
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('FCM foreground: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('FCM opened app: ${message.notification?.title}');
    });

    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  }

  static Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
    print('FCM background: ${message.notification?.title}');
  }

  Future<String?> getFcmToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }

  static Future<void> sendNotificationToUser({
    required String targetEmail,
    required String title,
    required String body,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('Notifications')
          .add({
        'targetEmail': targetEmail,
        'title': title,
        'body': body,
        'sentAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> scheduleDailyGameReminder({
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('game_reminder_enabled') ?? true;

    if (!isEnabled) return;

    await prefs.setInt('game_reminder_hour', hour);
    await prefs.setInt('game_reminder_minute', minute);
    await prefs.setBool('game_reminder_set', true);
  }

  Future<void> showMotivationNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('motivation_enabled') ?? true;

    if (!isEnabled) return;

    await prefs.setBool('show_motivation', true);
    await prefs.setString(
        'motivation_timestamp', DateTime.now().toIso8601String());
  }

  Future<void> showHealthTipNotification() async {
    await SharedPreferences.getInstance().then((prefs) async {
      await prefs.setBool('show_health_tip', true);
      await prefs.setString(
          'health_tip_timestamp', DateTime.now().toIso8601String());
    });
  }

  Future<void> showChatNotification(String message) async {
    await SharedPreferences.getInstance().then((prefs) async {
      await prefs.setString('last_chat_message', message);
      await prefs.setString('chat_timestamp', DateTime.now().toIso8601String());
      await prefs.setBool('show_chat_notification', true);
    });
  }

  Future<bool> shouldShowMotivation() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('motivation_last_shown');

    if (lastShown == null) return true;

    final lastDate = DateTime.tryParse(lastShown);
    if (lastDate == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastDate);

    return difference.inHours >= 4;
  }

  Future<void> markMotivationShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'motivation_last_shown', DateTime.now().toIso8601String());
  }

  Future<bool> shouldShowHealthTip() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('health_tip_last_shown');

    if (lastShown == null) return true;

    final lastDate = DateTime.tryParse(lastShown);
    if (lastDate == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastDate);

    return difference.inHours >= 6;
  }

  Future<void> markHealthTipShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'health_tip_last_shown', DateTime.now().toIso8601String());
  }

  Future<void> cancelGameReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('game_reminder_set', false);
  }

  Future<void> cancelMotivationNotification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('motivation_enabled', false);
  }

  Future<void> cancelHealthTipNotification() async {
    await SharedPreferences.getInstance().then((prefs) async {
      await prefs.setBool('show_health_tip', false);
    });
  }

  Future<void> cancelAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('game_reminder_set', false);
    await prefs.setBool('motivation_enabled', false);
    await prefs.setBool('show_health_tip', false);
  }

  String getLocalizedGameReminder(String language) {
    if (language == 'ar') {
      return '🎮 حان وقت اللعب!';
    } else if (language == 'en') {
      return '🎮 Time to Play!';
    } else {
      return '🎮 C\'est l\'heure de jouer!';
    }
  }

  String getLocalizedGameReminderBody(String language) {
    if (language == 'ar') {
      return 'هل تريد أن تلعب لعبة ذهنية اليوم للحفاظ على صحة عقلك؟';
    } else if (language == 'en') {
      return 'Would you like to play a brain game today to keep your mind sharp?';
    } else {
      return 'Avez-vous envie de jouer à un jeu cerebral aujourd\'hui?';
    }
  }

  String getLocalizedMotivation(String language) {
    if (language == 'ar') {
      return '💙 رسالة تحفيزية';
    } else if (language == 'en') {
      return '💙 Motivational Message';
    } else {
      return '💙 Message Motivant';
    }
  }

  String getLocalizedMotivationBody(String language) {
    if (language == 'ar') {
      return 'كل يوم جديد هو فرصة للتعلم والنمو!';
    } else if (language == 'en') {
      return 'Every new day is an opportunity to learn and grow!';
    } else {
      return 'Chaque nouveau jour est une opportunité d\'apprendre et de grandir!';
    }
  }

  String getLocalizedHealthTip(String language) {
    if (language == 'ar') {
      return '💧 نصيحة صحية';
    } else if (language == 'en') {
      return '💧 Health Tip';
    } else {
      return '💧 Conseil Santé';
    }
  }

  String getLocalizedHealthTipBody(String language) {
    if (language == 'ar') {
      return 'تذكر أن تشرب 8 أكواب من الماء يومياً!';
    } else if (language == 'en') {
      return 'Remember to drink 8 glasses of water daily!';
    } else {
      return 'N\'oubliez pas de boire 8 verres d\'eau par jour!';
    }
  }

  String getLocalizedAssistantTitle(String language) {
    if (language == 'ar') {
      return 'المساعد الذكي';
    } else if (language == 'en') {
      return 'AI Assistant';
    } else {
      return 'Assistant IA';
    }
  }
}
