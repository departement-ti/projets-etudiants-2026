import 'package:flutter/material.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/tenant/tenant_dashboard_page.dart';
import 'features/tickets/ticket_list_page.dart';
import 'features/agent/agent_dashboard_page.dart';
import 'features/assistant/assistant_dashboard_page.dart';
import 'features/users/user_management_page.dart';
import 'features/tenants/tenants_page.dart';

void main() {
  runApp(const SmartTenantApp());
}

class SmartTenantApp extends StatelessWidget {
  const SmartTenantApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6750A4);

    return MaterialApp(
      title: 'SmartTenant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F5FF),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFFF8F5FF),
          foregroundColor: Color(0xFF1D1B20),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Colors.black.withOpacity(0.04)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 2,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/dashboard': (_) => const DashboardPage(),
        '/tenant-dashboard': (_) => const TenantDashboardPage(),
        '/tickets': (_) => const TicketListPage(),
        '/agent-dashboard': (_) => const AgentDashboardPage(),
        '/assistant-dashboard': (_) => const AssistantDashboardPage(),
        '/user-management': (_) => const UserManagementPage(),
        '/tenants': (_) => const TenantsPage(),
      },
    );
  }
}
