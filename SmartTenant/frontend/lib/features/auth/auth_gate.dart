import 'package:flutter/material.dart';

import '../../core/auth/auth_storage.dart';
import '../dashboard/dashboard_page.dart';
import '../tenant/tenant_dashboard_page.dart';
import '../agent/agent_dashboard_page.dart';
import '../assistant/assistant_dashboard_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool loading = true;
  bool loggedIn = false;
  String? role;

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {
    final isLoggedIn = await AuthStorage.isLoggedIn();
    final userRole = await AuthStorage.getUserRole();

    if (!mounted) return;

    setState(() {
      loggedIn = isLoggedIn;
      role = userRole;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!loggedIn) {
      return const LoginPage();
    }

    if (role == 'TENANT') {
      return const TenantDashboardPage();
    }

    if (role == 'AGENT') {
      return const AgentDashboardPage();
    }

    if (role == 'ASSISTANT') {
      return const AssistantDashboardPage();
    }

    return const DashboardPage();
  }
}
