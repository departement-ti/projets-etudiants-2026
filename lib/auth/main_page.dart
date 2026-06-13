import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mymeds_app/auth/auth_page.dart';
import 'package:mymeds_app/services/biometric_auth_service.dart';
import 'package:mymeds_app/services/session_timeout_service.dart';

import 'package:mymeds_app/screens/dashboard_patient.dart';
import 'package:mymeds_app/screens/dashboard_assistant.dart';
import 'package:mymeds_app/screens/dashboard_doctor.dart';
import 'package:mymeds_app/screens/email_verify.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  final SessionTimeoutService _sessionService = SessionTimeoutService();

  @override
  void initState() {
    super.initState();
    _sessionService.start(() {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _sessionService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null && user.isAnonymous) {
              return _buildDashboardByBiometricId();
            }

            if (user != null && user.email != null && user.emailVerified) {
              return _buildDashboardByRole();
            } else if (user != null && user.email != null) {
              return const EmailVerificationScreen();
            }
          }
          return const AuthPage();
        },
      ),
    );
  }

  Widget _buildDashboardByBiometricId() {
    return FutureBuilder<String?>(
      future: _biometricService.getUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userId = snapshot.data;
        if (userId == null) {
          return const AuthPage();
        }

        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('Users').doc(userId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final role = data['role'] as String? ?? 'personneAge';

              switch (role) {
                case 'assistant':
                case 'membreFamille':
                  return const DashboardAssistant();
                case 'doctor':
                  return const DashboardDoctor();
                case 'personneAge':
                default:
                  return const DashboardPatient();
              }
            }

            return const DashboardPatient();
          },
        );
      },
    );
  }

  Widget _buildDashboardByRole() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      return const DashboardPatient();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('Users').doc(user.email).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final role = data['role'] as String? ?? 'personneAge';

          switch (role) {
            case 'assistant':
            case 'membreFamille':
              return const DashboardAssistant();
            case 'doctor':
              return const DashboardDoctor();
            case 'personneAge':
            default:
              return const DashboardPatient();
          }
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
