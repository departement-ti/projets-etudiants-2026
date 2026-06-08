import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/fournisseurs_provider.dart';
import '../models/fournisseur.dart';
import '../constants/app_theme.dart';

class FournisseurFormScreen extends StatefulWidget {
  final Fournisseur? fournisseur;

  const FournisseurFormScreen({super.key, this.fournisseur});

  @override
  State<FournisseurFormScreen> createState() => _FournisseurFormScreenState();
}

class _FournisseurFormScreenState extends State<FournisseurFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _raisonSocialeCtrl = TextEditingController();
  final _matriculeFiscalCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool get _isEditing => widget.fournisseur != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final f = widget.fournisseur!;
      _raisonSocialeCtrl.text = f.raisonSociale;
      _matriculeFiscalCtrl.text = f.matriculeFiscal ?? '';
      _telephoneCtrl.text = f.telephone ?? '';
      _emailCtrl.text = f.email ?? '';
    }
  }

  @override
  void dispose() {
    _raisonSocialeCtrl.dispose();
    _matriculeFiscalCtrl.dispose();
    _telephoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<FournisseursProvider>();
    final data = Fournisseur(
      raisonSociale: _raisonSocialeCtrl.text.trim(),
      matriculeFiscal: _matriculeFiscalCtrl.text.trim().nullIfEmpty,
      telephone: _telephoneCtrl.text.trim().nullIfEmpty,
      email: _emailCtrl.text.trim().nullIfEmpty,
    );

    final result = _isEditing
        ? await provider.update(widget.fournisseur!.id!, data)
        : await provider.create(data);

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isEditing ? 'Fournisseur modifié avec succès' : 'Fournisseur créé avec succès'),
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
          title: Text(_isEditing ? 'Modifier fournisseur' : 'Nouveau fournisseur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(_raisonSocialeCtrl, 'Raison sociale *', Icons.business),
              const SizedBox(height: 12),
              _buildField(_matriculeFiscalCtrl, 'Matricule fiscal',
                  Icons.badge_outlined),
              const SizedBox(height: 12),
              _buildField(_telephoneCtrl, 'Téléphone', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildField(_emailCtrl, 'Email', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
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
                          _isEditing ? 'Enregistrer' : 'Créer le fournisseur',
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

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _inputDeco(label, icon),
      validator: label.contains('*')
          ? (v) => v == null || v.trim().isEmpty ? 'Champ obligatoire' : null
          : null,
    );
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
