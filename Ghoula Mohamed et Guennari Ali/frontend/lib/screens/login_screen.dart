import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:rayhan_erp/constants/app_theme.dart';
import 'package:rayhan_erp/constants/app_text.dart';
import 'package:rayhan_erp/providers/auth_provider.dart';
import 'package:rayhan_erp/mock/mock_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_usernameCtrl.text, _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      final redirect =
          GoRouterState.of(context).uri.queryParameters['redirect'];
      context.go(redirect ?? '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.kPrimaryRedDark,
              AppTheme.kPrimaryRed,
              AppTheme.kPrimaryOrange,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.kSurfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(AppText.heroLoginTitle,
                        style: AppTheme.headlineSmall.copyWith(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(AppText.heroLoginSubtitle,
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.kTextSecondary)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom d\'utilisateur',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Obligatoire' : null,
                    ),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.kErrorRedLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.kErrorRed, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(auth.errorMessage!,
                                  style: const TextStyle(
                                      color: AppTheme.kErrorRed,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (MockConfig.useMock) ...[
                      const SizedBox(height: 16),
                      _buildMockUsersHint(),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _login,
                        style: AppTheme.primaryButton,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Se connecter',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: Text(AppText.forgotPasswordLink,
                              style: TextStyle(
                                  color: AppTheme.kPrimaryTeal, fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: Text(AppText.signupLink,
                              style: TextStyle(
                                  color: AppTheme.kPrimaryTeal, fontSize: 12)),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildMockUsersHint() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _showMockUsersDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.kBorderLight),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.people_outline,
                  size: 16, color: AppTheme.kPrimaryBurgundyLight),
              const SizedBox(width: 8),
              Text('Compte de démonstration',
                  style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.kTextSecondary,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.chevron_right, size: 16, color: AppTheme.kTextHint),
            ],
          ),
        ),
      ),
    );
  }

  void _showMockUsersDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        title: Row(
          children: [
            Icon(Icons.people_outline,
                size: 20, color: AppTheme.kPrimaryBurgundy),
            const SizedBox(width: 8),
            Text('Comptes de démonstration',
                style: AppTheme.titleSmall),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: MockConfig.mockUsers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final user = MockConfig.mockUsers[i];
              return ListTile(
                dense: true,
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _roleColor(user.role),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(user.username,
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(_roleShortLabel(user.role),
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.kTextSecondary)),
                trailing: Text('••••••',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.kTextHint)),
                onTap: () {
                  _usernameCtrl.text = user.username;
                  _passwordCtrl.text = user.password;
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fermer',
                style: TextStyle(color: AppTheme.kPrimaryBurgundy)),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'ROLE_PDG':
        return AppTheme.kPrimaryBurgundy;
      case 'ROLE_RESPONSABLE_VENTE':
        return AppTheme.kSecondaryTan;
      case 'ROLE_RESPONSABLE_ACHAT':
        return AppTheme.kPrimaryBurgundyLight;
      case 'ROLE_RESPONSABLE_PRODUCTION':
        return AppTheme.kWarningAmber;
      case 'ROLE_MAGASINIER':
        return AppTheme.kSuccessGreen;
      case 'ROLE_CLIENT':
        return AppTheme.kPrimaryTeal;
      default:
        return AppTheme.kTextHint;
    }
  }

  String _roleShortLabel(String role) {
    switch (role) {
      case 'ROLE_PDG':
        return 'Gérant';
      case 'ROLE_RESPONSABLE_VENTE':
        return 'Ventes';
      case 'ROLE_RESPONSABLE_ACHAT':
        return 'Achats';
      case 'ROLE_RESPONSABLE_PRODUCTION':
        return 'Production';
      case 'ROLE_MAGASINIER':
        return 'Magasin';
      case 'ROLE_CLIENT':
        return 'Client';
      default:
        return role;
    }
  }
}
