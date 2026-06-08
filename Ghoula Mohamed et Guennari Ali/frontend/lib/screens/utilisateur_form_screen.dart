import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../constants/app_theme.dart';

class UtilisateurFormScreen extends StatefulWidget {
  final User? user;

  const UtilisateurFormScreen({super.key, this.user});

  @override
  State<UtilisateurFormScreen> createState() => _UtilisateurFormScreenState();
}

class _UtilisateurFormScreenState extends State<UtilisateurFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool get _isEditing => widget.user != null;

  final List<String> _availableRoles = [
    'ROLE_PDG',
    'ROLE_RESPONSABLE_VENTE',
    'ROLE_RESPONSABLE_ACHAT',
    'ROLE_RESPONSABLE_PRODUCTION',
    'ROLE_MAGASINIER',
  ];

  Set<String> _selectedRoles = {};

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final u = widget.user!;
      _usernameCtrl.text = u.username;
      _emailCtrl.text = u.email;
      _firstNameCtrl.text = u.firstName ?? '';
      _lastNameCtrl.text = u.lastName ?? '';
      _selectedRoles = Set.from(u.roles);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un rôle.'),
          backgroundColor: AppTheme.kErrorRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<UserProvider>();
    final data = <String, dynamic>{
      'username': _usernameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'firstName': _firstNameCtrl.text.trim().isEmpty ? null : _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim().isEmpty ? null : _lastNameCtrl.text.trim(),
      'roles': _selectedRoles.toList(),
    };

    if (!_isEditing || _passwordCtrl.text.isNotEmpty) {
      data['password'] = _passwordCtrl.text;
    }

    bool success;
    if (_isEditing) {
      final result = await provider.update(widget.user!.id!, data);
      success = result != null;
    } else {
      if (_passwordCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le mot de passe est obligatoire.'),
            backgroundColor: AppTheme.kErrorRed,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }
      final created = await provider.create(data);
      success = created != null;
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Utilisateur modifié avec succès'
              : 'Utilisateur créé avec succès'),
          backgroundColor: AppTheme.kSuccessGreen,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement'),
          backgroundColor: AppTheme.kErrorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundCream,
      appBar: AppBar(
          title: Text(
              _isEditing ? 'Modifier utilisateur' : 'Nouvel utilisateur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(_usernameCtrl, 'Nom d\'utilisateur *', Icons.person,
                  enabled: !_isEditing),
              const SizedBox(height: 12),
              _buildField(_emailCtrl, 'Email *', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildField(_firstNameCtrl, 'Prénom', Icons.badge_outlined),
              const SizedBox(height: 12),
              _buildField(_lastNameCtrl, 'Nom', Icons.badge_outlined),
              const SizedBox(height: 12),
              _buildField(
                _passwordCtrl,
                _isEditing ? 'Nouveau mot de passe (optionnel)' : 'Mot de passe *',
                Icons.lock_outlined,
                obscureText: true,
                validator: _isEditing
                    ? null
                    : (v) => v == null || v.trim().isEmpty
                        ? 'Champ obligatoire'
                        : v.length < 6
                            ? 'Min. 6 caractères'
                            : null,
              ),
              const SizedBox(height: 24),
              Text('Rôles *',
                  style: AppTheme.titleSmall.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              ..._availableRoles.map((role) {
                final isSelected = _selectedRoles.contains(role);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _roleColor(role).withValues(alpha: 0.08)
                          : AppTheme.kSurfaceWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? _roleColor(role).withValues(alpha: 0.3)
                            : AppTheme.kBorderLight,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(User.roleLabelLong(role),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? _roleColor(role) : null)),
                      value: isSelected,
                      activeColor: _roleColor(role),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedRoles.add(role);
                          } else {
                            _selectedRoles.remove(role);
                          }
                        });
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: AppTheme.primaryButton,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.kWhite))
                      : Text(
                          _isEditing
                              ? 'Enregistrer'
                              : 'Créer l\'utilisateur',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'ROLE_PDG':
        return AppTheme.kErrorRed;
      case 'ROLE_RESPONSABLE_VENTE':
        return AppTheme.kPrimaryTeal;
      case 'ROLE_RESPONSABLE_ACHAT':
        return AppTheme.kPrimaryOrange;
      case 'ROLE_RESPONSABLE_PRODUCTION':
        return AppTheme.kSecondaryGold;
      case 'ROLE_MAGASINIER':
        return AppTheme.kWarningAmber;
      default:
        return AppTheme.kTextSecondary;
    }
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, bool obscureText = false, bool? enabled, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled ?? true,
      decoration: _inputDeco(label, icon),
      validator: validator ??
          (label.contains('*')
              ? (v) => v == null || v.trim().isEmpty ? 'Champ obligatoire' : null
              : null),
    );
  }
}
