import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tunixplore/services/auth_service.dart';
import 'package:tunixplore/services/user_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/models.dart';
import '../../widgets/common/common_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _step = 0;
  UserRole _selectedRole = UserRole.visitor;
  String _organiserKind = 'particular';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  int _selectedAvatarIndex = 5;

  // Common fields
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // Organiser-specific
  final _agencyNameCtrl = TextEditingController();
  final _agencyLicenseCtrl = TextEditingController();
  final _agencyAddressCtrl = TextEditingController();
  final _agencyWebsiteCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();

  final _steps = ['Rôle', 'Profil', 'Infos', 'Sécurité', 'Confirmation'];
  final _avatarOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passwordCtrl,
      _confirmCtrl,
      _bioCtrl,
      _cityCtrl,
      _agencyNameCtrl,
      _agencyLicenseCtrl,
      _agencyAddressCtrl,
      _agencyWebsiteCtrl,
      _specialtyCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isOrganiser => _selectedRole != UserRole.visitor;
  bool get _isAgency => _selectedRole == UserRole.organiserAgency;

  int get _strength {
    final p = _passwordCtrl.text;
    if (p.length < 6) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  Color get _strengthColor => [
    AppColors.textHint,
    AppColors.error,
    AppColors.warning,
    AppColors.success,
    AppColors.teal,
  ][_strength];
  String get _strengthLabel =>
      ['Trop court', 'Faible', 'Moyen', 'Fort', 'Très fort'][_strength];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: AppConstants.pagePadding,
                right: AppConstants.pagePadding,
                bottom: 28,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: const AssetImage('lib/assets/logo_tunixplore.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Rejoindre TuniXplore',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Étape ${_step + 1}/${_steps.length} — ${_steps[_step]}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(_steps.length, (i) {
                      final done = i < _step;
                      final active = i == _step;
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: AppConstants.animNormal,
                                height: active ? 8 : 4,
                                decoration: BoxDecoration(
                                  color: done || active
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            if (i < _steps.length - 1) const SizedBox(width: 5),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── STEP 0: Rôle ─────────────────────────────────────────────
                  if (_step == 0) ...[
                    _StepTitle(
                      step: '01',
                      title: 'Quel est votre rôle?',
                      subtitle: 'Choisissez comment utiliser TuniXplore',
                    ),
                    const SizedBox(height: 20),
                    _RoleCard(
                      emoji: '🧳',
                      title: 'Visiteur / Touriste',
                      subtitle:
                          'Découvrez événements, circuits et sites en Tunisie',
                      features: const [
                        'Participer à des visites & tours',
                        'Consulter les sites historiques',
                        'Parcours IA personnalisés',
                        'Avis et recommandations',
                      ],
                      isSelected: _selectedRole == UserRole.visitor,
                      color: AppColors.teal,
                      onTap: () =>
                          setState(() => _selectedRole = UserRole.visitor),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      emoji: '🎯',
                      title: 'Organisateur',
                      subtitle: 'Créez et gérez des événements touristiques',
                      features: const [
                        'Créer & publier des événements',
                        'Gérer les participants',
                        'Tableau de bord & statistiques',
                        'Profil organisateur vérifié',
                      ],
                      isSelected: _isOrganiser,
                      color: AppColors.accent,
                      onTap: () => setState(() {
                        _selectedRole = _organiserKind == 'agency'
                            ? UserRole.organiserAgency
                            : UserRole.organiserParticular;
                      }),
                    ),
                    if (_isOrganiser) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Type d\'organisateur',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _SubRoleChip(
                              emoji: '👤',
                              label: 'Particulier',
                              subtitle: 'Guide indépendant',
                              isSelected: _organiserKind == 'particular',
                              onTap: () => setState(() {
                                _organiserKind = 'particular';
                                _selectedRole = UserRole.organiserParticular;
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SubRoleChip(
                              emoji: '🏢',
                              label: 'Agence',
                              subtitle: 'Agence de voyage',
                              isSelected: _organiserKind == 'agency',
                              onTap: () => setState(() {
                                _organiserKind = 'agency';
                                _selectedRole = UserRole.organiserAgency;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  // ── STEP 1: Photo de profil ───────────────────────────────────
                  if (_step == 1) ...[
                    _StepTitle(
                      step: '02',
                      title: 'Votre photo de profil',
                      subtitle: 'Choisissez un avatar ou importez votre photo',
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 56,
                                backgroundColor: AppColors.surfaceVariant,
                                backgroundImage: NetworkImage(
                                  'https://i.pravatar.cc/200?img=$_selectedAvatarIndex',
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: -4,
                                child: GestureDetector(
                                  onTap: () => _showAvatarPicker(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Iconsax.camera,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => _showAvatarPicker(context),
                            child: const Text(
                              'Changer la photo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Choisir un avatar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _avatarOptions.map((idx) {
                        final sel = _selectedAvatarIndex == idx;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedAvatarIndex = idx),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(
                                  'https://i.pravatar.cc/100?img=$idx',
                                ),
                              ),
                              if (sel)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.55),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Importer depuis la galerie',
                      icon: Iconsax.gallery,
                      isOutline: true,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📷 Disponible avec Firebase Storage'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
                    ),
                  ],

                  // ── STEP 2: Informations ──────────────────────────────────────
                  if (_step == 2) ...[
                    _StepTitle(
                      step: '03',
                      title: 'Vos informations',
                      subtitle: 'Dites-nous qui vous êtes',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            hint: 'Prénom',
                            label: 'Prénom',
                            prefixIcon: Iconsax.user,
                            controller: _firstNameCtrl,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            hint: 'Nom',
                            label: 'Nom de famille',
                            prefixIcon: Iconsax.user,
                            controller: _lastNameCtrl,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                      hint: '+216 XX XXX XXX',
                      label: 'Téléphone',
                      prefixIcon: Iconsax.call,
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      hint: 'Tunis, Sfax, Sousse...',
                      label: 'Ville de résidence',
                      prefixIcon: Iconsax.location,
                      controller: _cityCtrl,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Biographie (optionnel)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _bioCtrl,
                          maxLines: 3,
                          maxLength: 150,
                          decoration: const InputDecoration(
                            hintText:
                                'Parlez un peu de vous et de vos centres d\'intérêt...',
                          ),
                        ),
                      ],
                    ),

                    // Organiser extras
                    if (_isOrganiser) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.briefcase,
                                  color: AppColors.accent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isAgency
                                      ? 'Informations Agence'
                                      : 'Informations Organisateur',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_isAgency) ...[
                              AppTextField(
                                hint: 'Nom officiel de l\'agence',
                                label: 'Nom de l\'agence',
                                prefixIcon: Iconsax.buildings,
                                controller: _agencyNameCtrl,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                hint: 'Ex: AT-2024-0001',
                                label: 'Numéro de licence',
                                prefixIcon: Iconsax.document,
                                controller: _agencyLicenseCtrl,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                hint: 'Adresse complète de l\'agence',
                                label: 'Adresse',
                                prefixIcon: Iconsax.location,
                                controller: _agencyAddressCtrl,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                hint: 'www.mon-agence.tn',
                                label: 'Site web (optionnel)',
                                prefixIcon: Iconsax.global,
                                controller: _agencyWebsiteCtrl,
                                keyboardType: TextInputType.url,
                                maxLines: 1,
                              ),
                            ] else ...[
                              AppTextField(
                                hint:
                                    'Ex: Guide historique, Désert, Gastronomie',
                                label: 'Spécialité / Domaine',
                                prefixIcon: Iconsax.star,
                                controller: _specialtyCtrl,
                                maxLines: 1,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.info.withOpacity(0.2),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Iconsax.info_circle,
                                    color: AppColors.info,
                                    size: 14,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Votre profil sera vérifié sous 24-48h avant activation complète.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // ── STEP 3: Sécurité ──────────────────────────────────────────
                  if (_step == 3) ...[
                    _StepTitle(
                      step: '04',
                      title: 'Sécurité du compte',
                      subtitle: 'Choisissez un mot de passe fort',
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      maxLines: 1,
                      hint: '••••••••',
                      label: 'Mot de passe',
                      prefixIcon: Iconsax.lock,
                      suffixIcon: _obscurePassword
                          ? Iconsax.eye_slash
                          : Iconsax.eye,
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      onSuffixTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 10),
                    if (_passwordCtrl.text.isNotEmpty) ...[
                      Row(
                        children: List.generate(
                          4,
                          (i) => Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                              height: 4,
                              decoration: BoxDecoration(
                                color: i < _strength
                                    ? _strengthColor
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _strengthLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _strengthColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Min. 8 carac., 1 majuscule, 1 chiffre',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ] else
                      const SizedBox(height: 14),
                    AppTextField(
                      maxLines: 1,
                      hint: '••••••••',
                      label: 'Confirmer le mot de passe',
                      prefixIcon: Iconsax.lock_1,
                      suffixIcon: _obscureConfirm
                          ? Iconsax.eye_slash
                          : Iconsax.eye,
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      onSuffixTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    if (_confirmCtrl.text.isNotEmpty &&
                        _confirmCtrl.text != _passwordCtrl.text) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Les mots de passe ne correspondent pas',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  // ── STEP 4: Confirmation ──────────────────────────────────────
                  if (_step == 4) ...[
                    _StepTitle(
                      step: '05',
                      title: 'Presque terminé!',
                      subtitle: 'Vérifiez vos informations',
                    ),
                    const SizedBox(height: 20),
                    // Avatar preview
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/200?img=$_selectedAvatarIndex',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(
                            icon: Iconsax.user,
                            label: 'Prénom',
                            value: _firstNameCtrl.text.isEmpty
                                ? '—'
                                : _firstNameCtrl.text,
                          ),
                          const Divider(color: AppColors.border),
                          _SummaryRow(
                            icon: Iconsax.user,
                            label: 'Nom',
                            value: _lastNameCtrl.text.isEmpty
                                ? '—'
                                : _lastNameCtrl.text,
                          ),
                          const Divider(color: AppColors.border),
                          _SummaryRow(
                            icon: Iconsax.sms,
                            label: 'Email',
                            value: _emailCtrl.text.isEmpty
                                ? '—'
                                : _emailCtrl.text,
                          ),
                          const Divider(color: AppColors.border),
                          _SummaryRow(
                            icon: Iconsax.call,
                            label: 'Téléphone',
                            value: _phoneCtrl.text.isEmpty
                                ? '—'
                                : _phoneCtrl.text,
                          ),
                          const Divider(color: AppColors.border),
                          _SummaryRow(
                            icon: Iconsax.location,
                            label: 'Ville',
                            value: _cityCtrl.text.isEmpty
                                ? '—'
                                : _cityCtrl.text,
                          ),
                          const Divider(color: AppColors.border),
                          _SummaryRow(
                            icon: _isOrganiser
                                ? Iconsax.briefcase
                                : Iconsax.user_tick,
                            label: 'Rôle',
                            value: _selectedRole == UserRole.visitor
                                ? 'Visiteur'
                                : _isAgency
                                ? 'Agence de voyage'
                                : 'Organisateur particulier',
                          ),
                          if (_isAgency && _agencyNameCtrl.text.isNotEmpty) ...[
                            const Divider(color: AppColors.border),
                            _SummaryRow(
                              icon: Iconsax.buildings,
                              label: 'Agence',
                              value: _agencyNameCtrl.text,
                            ),
                          ],
                          if (!_isAgency &&
                              _isOrganiser &&
                              _specialtyCtrl.text.isNotEmpty) ...[
                            const Divider(color: AppColors.border),
                            _SummaryRow(
                              icon: Iconsax.star,
                              label: 'Spécialité',
                              value: _specialtyCtrl.text,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: AppConstants.animFast,
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _acceptTerms
                                  ? AppColors.accent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _acceptTerms
                                    ? AppColors.accent
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: _acceptTerms
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'J\'accepte les ',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () =>
                                          context.push('/settings/terms'),
                                      child: const Text(
                                        'Conditions d\'utilisation',
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' de TuniXplore.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Nav buttons
                  Row(
                    children: [
                      if (_step > 0) ...[
                        AppButton(
                          label: 'Retour',
                          isOutline: true,
                          width: 100,
                          onTap: () => setState(() => _step--),
                        ),
                        const SizedBox(width: 12),
                      ],

                      Expanded(
                        child: AppButton(
                          label: _step < _steps.length - 1
                              ? 'Continuer'
                              : 'Créer mon compte',
                          isLoading: _isLoading,
                          onTap: (_step == _steps.length - 1 && !_acceptTerms)
                              ? null
                              : () async {
                                  // 👉 Step navigation
                                  if (_step < _steps.length - 1) {
                                    setState(() => _step++);
                                    return;
                                  }

                                  final email = _emailCtrl.text.trim();
                                  final password = _passwordCtrl.text.trim();
                                  final confirmPassword = _confirmCtrl.text
                                      .trim();

                                  // 👉 Validation
                                  if (email.isEmpty || password.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Veuillez remplir tous les champs',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (password != confirmPassword) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Les mots de passe ne correspondent pas',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  try {
                                    // 🔐 1. Create Auth user
                                    final cred = await _authService.signUp(
                                      email,
                                      password,
                                    );
                                    final uid = cred.user!.uid;

                                    // 🖼️ Avatar
                                    final avatarUrl =
                                        'https://i.pravatar.cc/200?img=$_selectedAvatarIndex';

                                    // 🗄️ 2. Save user in Firestore
                                    await _firestore
                                        .collection('users')
                                        .doc(uid)
                                        .set({
                                          'firstName': _firstNameCtrl.text
                                              .trim(),
                                          'lastName': _lastNameCtrl.text.trim(),
                                          'email': email,
                                          'phone': _phoneCtrl.text.trim(),
                                          'city': _cityCtrl.text.trim(),
                                          'bio': _bioCtrl.text.trim(),
                                          'avatarUrl': avatarUrl,

                                          'role': _selectedRole.name,

                                          'agencyName': _isAgency
                                              ? _agencyNameCtrl.text.trim()
                                              : null,
                                          'agencyLicense': _isAgency
                                              ? _agencyLicenseCtrl.text.trim()
                                              : null,
                                          'specialty':
                                              (!_isAgency && _isOrganiser)
                                              ? _specialtyCtrl.text.trim()
                                              : null,

                                          'interests': [],
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                        });

                                    // ✅ ADD THIS LINE immediately after:
                                    UserSession.instance.setRole(
                                      _selectedRole.name,
                                    );

                                    if (!mounted) return;

                                    // 🚀 Navigation
                                    if (_isOrganiser) {
                                      context.go('/organiser');
                                    } else {
                                      context.go('/home');
                                    }
                                  }
                                  // 🔴 Firebase Auth errors
                                  on FirebaseAuthException catch (e) {
                                    String message;

                                    switch (e.code) {
                                      case 'email-already-in-use':
                                        message = 'Cet email est déjà utilisé';
                                        break;
                                      case 'weak-password':
                                        message = 'Mot de passe trop faible';
                                        break;
                                      case 'invalid-email':
                                        message = 'Email invalide';
                                        break;
                                      case 'operation-not-allowed':
                                        message = 'Inscription désactivée';
                                        break;
                                      default:
                                        message =
                                            e.message ?? 'Erreur Firebase';
                                    }

                                    print(
                                      '🔥 FirebaseAuthException: ${e.code} - ${e.message}',
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  }
                                  // 🔴 Firestore / other errors
                                  catch (e) {
                                    print('🔥 General error: $e');

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Erreur lors de la sauvegarde des données',
                                        ),
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Déjà un compte? ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: 'Se connecter',
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

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
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
              'Choisir un avatar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _avatarOptions.map((idx) {
                final sel = _selectedAvatarIndex == idx;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvatarIndex = idx);
                    Navigator.pop(ctx);
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/100?img=$idx',
                        ),
                      ),
                      if (sel)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Importer depuis la galerie',
              icon: Iconsax.gallery,
              isOutline: true,
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📷 Disponible avec Firebase Storage'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────
class _StepTitle extends StatelessWidget {
  final String step, title, subtitle;
  const _StepTitle({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        ),
        child: Text(
          'Étape $step',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    ],
  );
}

class _RoleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final List<String> features;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: AppConstants.animFast,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(
                    f,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SubRoleChip extends StatelessWidget {
  final String emoji, label, subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  const _SubRoleChip({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: AppConstants.animFast,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isSelected ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
}
