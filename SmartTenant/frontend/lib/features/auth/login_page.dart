import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_storage.dart';
import '../dashboard/dashboard_page.dart';
import '../tenant/tenant_dashboard_page.dart';
import '../agent/agent_dashboard_page.dart';
import '../assistant/assistant_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email and password are required');
      return;
    }

    setState(() => loading = true);

    try {
      await AuthService.login(email, password);

      final role = await AuthStorage.getUserRole();

      if (!mounted) return;

      showMessage('Login successful');

      if (role == 'TENANT') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TenantDashboardPage()),
          (route) => false,
        );
      } else if (role == 'AGENT') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AgentDashboardPage()),
          (route) => false,
        );
      } else if (role == 'ASSISTANT') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AssistantDashboardPage()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showMessage(cleanError(e));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String cleanError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget logo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF6750A4).withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.apartment, size: 42, color: Color(0xFF6750A4)),
    );
  }

  Widget infoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Icon(Icons.security, color: Color(0xFF6750A4)),
            const SizedBox(height: 8),
            const Text(
              'Account access is managed by your organization.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Admins create organizations and platform users. Owners create tenant accounts from the Tenants page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget demoAccountsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: const [
            Text(
              'Demo Accounts',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Admin: admin@smarttenant.com / 123456'),
            Text('Tenant: tenant@smarttenant.com / 123456'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              logo(),

              const SizedBox(height: 24),

              const Text(
                'Welcome to SmartTenant',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Manage rent, leases, payments and maintenance in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !loading,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passCtrl,
                obscureText: obscurePassword,
                enabled: !loading,
                onSubmitted: (_) {
                  if (!loading) login();
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: loading
                        ? null
                        : () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: loading ? null : login,
                icon: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(loading ? 'Signing in...' : 'Login'),
              ),

              const SizedBox(height: 18),

              infoCard(),

              const SizedBox(height: 18),

              demoAccountsCard(),
            ],
          ),
        ),
      ),
    );
  }
}
