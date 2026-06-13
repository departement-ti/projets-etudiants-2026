import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ShakeSOSOverlay {
  static bool _isShowing = false;

  static void show(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ShakeSOSDialog(
        onDismiss: () {
          _isShowing = false;
          Navigator.of(dialogContext).pop();
        },
      ),
    ).then((_) => _isShowing = false);
  }

  static Future<void> callEmergency() async {
    // Récupérer la position GPS
    Position? position;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final p = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 5),
        );
        position = p;
      }
    } catch (_) {}

    // Créer une alerte SOS avec position dans Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.email)
            .get();
        final userName = userDoc.data()?['name'] ?? user.email!;
        final familyEmails =
            (userDoc.data()?['linkedFamilyEmails'] as List<dynamic>?)?.cast<String>() ?? [];
        final linkedDoctorEmails =
            (userDoc.data()?['linkedDoctorEmails'] as List<dynamic>?)?.cast<String>() ?? [];

        final locText = position != null
            ? '📍 https://maps.google.com/?q=${position.latitude},${position.longitude}'
            : '📍 Position non disponible';

        final body = '🚨 SOS URGENT déclenché.\n$locText';

        // Notifier tous les contacts
        for (final email in {...familyEmails, ...linkedDoctorEmails}) {
          if (email.isEmpty) continue;
          await FirebaseFirestore.instance.collection('Notifications').add({
            'targetEmail': email,
            'title': '🚨 SOS URGENT',
            'body': body,
            'type': 'sos',
            'latitude': position?.latitude,
            'longitude': position?.longitude,
            'sentAt': DateTime.now().toIso8601String(),
            'read': false,
          });

          await FirebaseFirestore.instance.collection('Reminders').add({
            'caregiverEmail': email,
            'type': 'sos_emergency',
            'message': body,
            'patientEmail': user.email,
            'patientName': userName,
            'latitude': position?.latitude,
            'longitude': position?.longitude,
            'createdAt': DateTime.now().toIso8601String(),
            'read': false,
          });
        }

        // Créer incident SOS
        await FirebaseFirestore.instance.collection('Incidents').add({
          'type': 'SOS Urgence',
          'description': 'SOS déclenché par $userName. $locText',
          'severity': 4,
          'elderlyEmail': user.email,
          'reporterEmail': 'system',
          'date': DateTime.now().toIso8601String(),
          'resolved': false,
          'latitude': position?.latitude,
          'longitude': position?.longitude,
        });
      }
    } catch (e) {
      print('SOS alert error: $e');
    }

    // Appeler le SAMU
    const phoneNumber = '190';
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ShakeSOSDialog extends StatefulWidget {
  final VoidCallback onDismiss;
  const _ShakeSOSDialog({required this.onDismiss});

  @override
  State<_ShakeSOSDialog> createState() => _ShakeSOSDialogState();
}

class _ShakeSOSDialogState extends State<_ShakeSOSDialog>
    with SingleTickerProviderStateMixin {
  int _countdown = 5;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          timer.cancel();
          _makeCall();
        }
      });
    });
  }

  Future<void> _makeCall() async {
    widget.onDismiss();
    await ShakeSOSOverlay.callEmergency();
  }

  void _cancel() {
    _timer?.cancel();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha(100),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: const Icon(
                    Icons.sos,
                    size: 80,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              translation(context).sosTitle,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              translation(context).sosCalling,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
              ),
              child: Center(
                child: Text(
                  '$_countdown',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(translation(context).sosCancel),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _makeCall,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(translation(context).sosCallNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
