import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/clients_provider.dart';
import '../constants/app_theme.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _raisonSocialeCtrl = TextEditingController();
  final _matriculeFiscalCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _representantNomCtrl = TextEditingController();
  final _representantTelCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _typeClient;
  final _plafondCtrl = TextEditingController();
  final _delaiCtrl = TextEditingController(text: '30');

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  final _typeOptions = ['Grossiste', 'Détaillant', 'Industrie'];

  @override
  void dispose() {
    _raisonSocialeCtrl.dispose();
    _matriculeFiscalCtrl.dispose();
    _telephoneCtrl.dispose();
    _emailCtrl.dispose();
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _representantNomCtrl.dispose();
    _representantTelCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _plafondCtrl.dispose();
    _delaiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<ClientsProvider>();
    final result = await provider.createWithUser(
      raisonSociale: _raisonSocialeCtrl.text.trim(),
      matriculeFiscal: _matriculeFiscalCtrl.text.trim().nullIfEmpty,
      telephone: _telephoneCtrl.text.trim().nullIfEmpty,
      email: _emailCtrl.text.trim().nullIfEmpty,
      adresse: _adresseCtrl.text.trim().nullIfEmpty,
      ville: _villeCtrl.text.trim().nullIfEmpty,
      typeClient: _typeClient,
      plafondCredit: double.tryParse(_plafondCtrl.text),
      delaiPaiement: int.tryParse(_delaiCtrl.text),
      representantNom: _representantNomCtrl.text.trim().nullIfEmpty,
      representantTelephone: _representantTelCtrl.text.trim().nullIfEmpty,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client créé avec succès'),
          backgroundColor: AppTheme.kSuccessGreen,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la création'),
          backgroundColor: AppTheme.kErrorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundCream,
      appBar: AppBar(title: const Text('Nouveau client')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader('Informations entreprise'),
              const SizedBox(height: 12),
              _buildField(_raisonSocialeCtrl, 'Raison sociale *', Icons.business),
              const SizedBox(height: 12),
              _buildField(_matriculeFiscalCtrl, 'Matricule fiscal', Icons.badge_outlined),
              const SizedBox(height: 12),
              _buildField(_telephoneCtrl, 'Téléphone', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildField(_emailCtrl, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildField(_adresseCtrl, 'Adresse', Icons.location_on_outlined),
              const SizedBox(height: 12),
              _buildField(_villeCtrl, 'Ville', Icons.location_city_outlined),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _typeClient,
                decoration: _inputDeco('Type client', Icons.category_outlined),
                items: _typeOptions
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _typeClient = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(_plafondCtrl, 'Plafond crédit (TND)', Icons.credit_card_outlined,
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(_delaiCtrl, 'Délai paiement (j)', Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionHeader('Contact représentant'),
              const SizedBox(height: 12),
              _buildField(_representantNomCtrl, 'Nom du représentant', Icons.person_outline),
              const SizedBox(height: 12),
              _buildField(_representantTelCtrl, 'Téléphone représentant', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              _sectionHeader('Compte utilisateur (connexion portail)'),
              const SizedBox(height: 12),
              _buildField(_firstNameCtrl, 'Prénom *', Icons.person),
              const SizedBox(height: 12),
              _buildField(_lastNameCtrl, 'Nom *', Icons.person),
              const SizedBox(height: 12),
              Text(
                'L\'email saisi ci-dessus servira d\'identifiant de connexion.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary),
              ),
              const SizedBox(height: 12),
              _buildField(_passwordCtrl, 'Mot de passe *', Icons.lock_outline,
                  obscure: true, visible: !_obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
              const SizedBox(height: 12),
              _buildField(_confirmCtrl, 'Confirmer mot de passe *', Icons.lock_outline,
                  obscure: true, visible: !_obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
                    return null;
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
                      : const Text('Créer le client',
                          style: TextStyle(
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

  Widget _sectionHeader(String text) {
    return Text(text,
        style: AppTheme.titleSmall.copyWith(
            color: AppTheme.kPrimaryRed, fontWeight: FontWeight.w700));
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType,
      bool obscure = false,
      bool visible = false,
      VoidCallback? onToggle,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure && !visible,
      keyboardType: keyboardType,
      decoration: _inputDeco(label, icon).copyWith(
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                    visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20),
                onPressed: onToggle,
              )
            : null,
      ),
      validator: validator ??
          (label.contains('*')
              ? (v) =>
                  v == null || v.trim().isEmpty ? 'Champ obligatoire' : null
              : null),
    );
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
