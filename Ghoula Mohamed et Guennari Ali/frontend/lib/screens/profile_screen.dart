import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';
import '../widgets/client_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _firstNameCtrl.text = auth.user ?? '';
      _lastNameCtrl.text = '';
      _emailCtrl.text = auth.user ?? '';
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClientScaffold(
      currentRoute: '/mon-profil',
      body: AppTheme.glassBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSectionTitle('Informations personnelles'),
                const SizedBox(height: 12),
                _buildReadOnlyField(
                  controller: _firstNameCtrl,
                  label: 'Prénom',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _buildReadOnlyField(
                  controller: _lastNameCtrl,
                  label: 'Nom',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _buildReadOnlyField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Coordonnées'),
                const SizedBox(height: 12),
                _buildEditableField(
                  controller: _telephoneCtrl,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _buildEditableField(
                  controller: _adresseCtrl,
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                _buildEditableField(
                  controller: _villeCtrl,
                  label: 'Ville',
                  icon: Icons.location_city_outlined,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                        backgroundColor: AppTheme.kPrimaryRed,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Sauvegarder'),
                  style: AppTheme.primaryButton,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecorationMd,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.kPrimaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (_firstNameCtrl.text.isNotEmpty
                        ? _firstNameCtrl.text[0].toUpperCase()
                        : '?'),
                style: AppTheme.displaySmall.copyWith(
                  color: AppTheme.kWhite,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _firstNameCtrl.text.isNotEmpty
                ? '${_firstNameCtrl.text}${_lastNameCtrl.text.isNotEmpty ? ' ${_lastNameCtrl.text}' : ''}'
                : 'Mon profil',
            style: AppTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.titleSmall.copyWith(fontSize: 14));
  }

  Widget _buildReadOnlyField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppTheme.kInputFill.withValues(alpha: 0.5),
      ),
      style: AppTheme.bodyMedium.copyWith(color: AppTheme.kTextPrimary),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      style: AppTheme.bodyMedium,
    );
  }
}
