import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tunixplore/services/auth_service.dart';
import 'package:tunixplore/services/user_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _isLoading = false;
  bool _showAsOrganiser = false; // what the user selected on the toggle

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // LOGIN HANDLER
  // ─────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch real Firestore role and cache it in UserSession
      await _authService.signInAndLoadRole(email, password);

      if (!mounted) return;

      final isActuallyOrganiser = UserSession.instance.isOrganiser;

      // ── Role mismatch ──────────────────────────────────────
      // User selected "Visitor" but account is organiser, or vice versa.
      if (_showAsOrganiser != isActuallyOrganiser) {
        // Sign out immediately — we do not let them proceed under
        // the wrong role context.
        await _authService.signOut();

        if (!mounted) return;
        _showRoleMismatchSheet(
          selectedOrganiser: _showAsOrganiser,
          actualOrganiser: isActuallyOrganiser,
        );
        return;
      }

      // ── Roles match → navigate ─────────────────────────────
      if (isActuallyOrganiser) {
        context.go('/organiser');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // ROLE MISMATCH SHEET
  // ─────────────────────────────────────────────────────────

  void _showRoleMismatchSheet({
    required bool selectedOrganiser,
    required bool actualOrganiser,
  }) {
    // selectedOrganiser = what the user tapped on the toggle
    // actualOrganiser   = what Firestore says their role really is

    // The "wrong" role they tried to use
    final triedRole = selectedOrganiser ? 'organisateur' : 'visiteur';
    // The role their account actually has
    final actualRole = actualOrganiser ? 'organisateur' : 'visiteur';
    // The signup path we'll send them to
    final signupRoute = '/signup';

    final IconData icon = selectedOrganiser
        ? Iconsax.briefcase
        : Iconsax.profile_circle;
    final Color color = selectedOrganiser ? AppColors.warning : AppColors.info;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Aucun compte $triedRole trouvé',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Body
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                children: [
                  const TextSpan(text: 'Cet email est associé à un compte '),
                  TextSpan(
                    text: actualRole,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text:
                        ', pas $triedRole.\n\n'
                        'Pour utiliser l\'espace $triedRole, '
                        'créez un nouveau compte avec une '
                        'adresse email différente.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Primary CTA — create the missing account type
            AppButton(
              label: 'Créer un compte $triedRole',
              onTap: () {
                Navigator.pop(ctx);
                context.push(signupRoute);
              },
            ),
            const SizedBox(height: 10),

            // Secondary CTA — log in as their actual role instead
            AppButton(
              label: 'Me connecter comme $actualRole',
              isOutline: true,
              onTap: () async {
                Navigator.pop(ctx);
                // Switch the toggle to match the actual role, then retry
                setState(() => _showAsOrganiser = actualOrganiser);
                await _handleLogin();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found')) return 'Utilisateur non trouvé';
    if (raw.contains('wrong-password') || raw.contains('invalid-credential'))
      return 'Mot de passe incorrect';
    if (raw.contains('invalid-email')) return 'Email invalide';
    if (raw.contains('too-many-requests'))
      return 'Trop de tentatives, réessayez plus tard';
    return 'Erreur de connexion';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ─────────────────────────────────────────
            Container(
              height: 320,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: const AssetImage(
                            'lib/assets/logo_tunixplore.png',
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'TuniXplore',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Découvrez la Tunisie autrement',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Role toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RoleToggle(
                            label: '🧳 Visiteur',
                            isSelected: !_showAsOrganiser,
                            onTap: () =>
                                setState(() => _showAsOrganiser = false),
                          ),
                          const SizedBox(width: 4),
                          _RoleToggle(
                            label: '🎯 Organisateur',
                            isSelected: _showAsOrganiser,
                            onTap: () =>
                                setState(() => _showAsOrganiser = true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    _showAsOrganiser
                        ? 'Espace Organisateur 🎯'
                        : 'Bon retour! 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showAsOrganiser
                        ? 'Connectez-vous pour gérer vos événements'
                        : 'Connectez-vous pour explorer la Tunisie',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  AppTextField(
                    hint: 'votre@email.com',
                    label: 'Adresse email',
                    prefixIcon: Iconsax.sms,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    hint: '••••••••',
                    label: 'Mot de passe',
                    prefixIcon: Iconsax.lock,
                    suffixIcon: _obscure ? Iconsax.eye_slash : Iconsax.eye,
                    controller: _passCtrl,
                    obscureText: _obscure,
                    onSuffixTap: () => setState(() => _obscure = !_obscure),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _showForgotPassword(context),
                      child: const Text(
                        'Mot de passe oublié?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  AppButton(
                    label: 'Se connecter',
                    isLoading: _isLoading,
                    onTap: _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  // Facebook & Google login options (coming soon)

                  // Row(
                  //   children: [
                  //     const Expanded(child: Divider(color: AppColors.border)),
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 12),
                  //       child: Text(
                  //         'ou',
                  //         style: TextStyle(
                  //           color: AppColors.textSecondary,
                  //           fontSize: 13,
                  //         ),
                  //       ),
                  //     ),
                  //     const Expanded(child: Divider(color: AppColors.border)),
                  //   ],
                  // ),
                  // const SizedBox(height: 18),

                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: _SocialBtn(
                  //         label: 'Google',
                  //         emoji: 'G',
                  //         onTap: () => _showComingSoon(context, 'Google'),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 12),
                  //     Expanded(
                  //       child: _SocialBtn(
                  //         label: 'Facebook',
                  //         emoji: 'f',
                  //         onTap: () => _showComingSoon(context, 'Facebook'),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 26),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Pas encore de compte? ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: 'S\'inscrire',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FORGOT PASSWORD SHEET
  // ─────────────────────────────────────────────────────────

  void _showForgotPassword(BuildContext context) {
    final emailCtrl = TextEditingController();

    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> handleReset() async {
              final email = emailCtrl.text.trim();

              // Email validation
              if (email.isEmpty) {
                _showSnack('Veuillez entrer votre email');
                return;
              }

              if (!email.contains('@') || !email.contains('.')) {
                _showSnack('Adresse email invalide');
                return;
              }

              try {
                setModalState(() => isSending = true);

                await _authService.sendPasswordReset(email);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Lien envoyé ! Vérifiez votre email 📧',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                String message;

                switch (e.code) {
                  case 'user-not-found':
                    message = 'Aucun utilisateur trouvé avec cet email';
                    break;

                  case 'invalid-email':
                    message = 'Adresse email invalide';
                    break;

                  case 'too-many-requests':
                    message = 'Trop de tentatives. Réessayez plus tard';
                    break;

                  default:
                    message = e.message ?? 'Erreur lors de l’envoi';
                }

                if (mounted) {
                  _showSnack(message);
                }

                debugPrint('FirebaseAuthException: ${e.code}');
                debugPrint('Message: ${e.message}');
              } catch (e) {
                debugPrint(e.toString());

                if (mounted) {
                  _showSnack('Erreur inattendue');
                }
              } finally {
                if (ctx.mounted) {
                  setModalState(() => isSending = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Entrez votre adresse email pour recevoir un lien de réinitialisation.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  AppTextField(
                    hint: 'votre@email.com',
                    label: 'Adresse email',
                    prefixIcon: Iconsax.sms,
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    maxLines: 1,
                  ),

                  const SizedBox(height: 18),

                  AppButton(
                    label: 'Envoyer le lien',
                    isLoading: isSending,
                    onTap: isSending ? null : handleReset,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'La connexion via $provider sera disponible prochainement 🚀',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════

class _RoleToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _RoleToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.textPrimary : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String label, emoji;
  final VoidCallback onTap;
  const _SocialBtn({
    required this.label,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
