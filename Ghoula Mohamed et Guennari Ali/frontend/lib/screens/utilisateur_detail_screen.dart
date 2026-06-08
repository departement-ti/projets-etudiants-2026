import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../constants/app_theme.dart';
import '../widgets/professional_dialogs.dart';
import 'utilisateur_form_screen.dart';

class UtilisateurDetailScreen extends StatefulWidget {
  final User user;
  final bool isEmbedded;
  const UtilisateurDetailScreen({super.key, required this.user, this.isEmbedded = false});

  @override
  State<UtilisateurDetailScreen> createState() => _UtilisateurDetailScreenState();
}

class _UtilisateurDetailScreenState extends State<UtilisateurDetailScreen> {
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _toggleEnabled() async {
    final provider = context.read<UserProvider>();
    bool success;
    if (_user.enabled) {
      success = await provider.disable(_user.id!);
    } else {
      success = await provider.enable(_user.id!);
    }
    if (success && mounted) {
      setState(() {
        _user = User(
          id: _user.id,
          username: _user.username,
          email: _user.email,
          firstName: _user.firstName,
          lastName: _user.lastName,
          enabled: !_user.enabled,
          roles: _user.roles,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_user.enabled
              ? 'Utilisateur activé avec succès'
              : 'Utilisateur désactivé avec succès'),
          backgroundColor: AppTheme.kSuccessGreen,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    final password = await AppDialogs.showInput(
      context: context,
      title: 'Réinitialiser le mot de passe',
      label: 'Nouveau mot de passe',
      hintText: 'Nouveau mot de passe',
      isPassword: true,
    );
    if (password == null || password.trim().isEmpty) return;
    if (password.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le mot de passe doit contenir au moins 6 caractères.'),
            backgroundColor: AppTheme.kErrorRed,
          ),
        );
      }
      return;
    }

    final provider = context.read<UserProvider>();
    final success = await provider.setPassword(_user.id!, password);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe réinitialisé avec succès'),
          backgroundColor: AppTheme.kSuccessGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.isEmbedded) return content;
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundCream,
      appBar: AppBar(
        title: Text(_user.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push<User>(
                context,
                MaterialPageRoute(
                  builder: (_) => UtilisateurFormScreen(user: _user),
                ),
              );
              if (result != null && mounted) {
                setState(() => _user = result);
              }
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.kPrimaryGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(_user.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_user.displayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(_user.email,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _user.enabled
                      ? AppTheme.kSuccessGreen.withValues(alpha: 0.2)
                      : AppTheme.kTextHint.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _user.enabled ? 'Actif' : 'Inactif',
                  style: TextStyle(
                      color: _user.enabled
                          ? AppTheme.kSuccessGreen
                          : AppTheme.kTextHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.kSurfaceWhite,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            boxShadow: AppTheme.shadowSm,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rôles',
                  style:
                      AppTheme.titleSmall.copyWith(fontSize: 14)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _user.roles.map((r) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _user.roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      User.roleLabelLong(r),
                      style: TextStyle(
                          color: _user.roleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecorationMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Informations',
                  style:
                      AppTheme.titleSmall.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              _item('Nom d\'utilisateur', _user.username),
              _item('Email', _user.email),
              _item('Prénom', _user.firstName ?? '—'),
              _item('Nom', _user.lastName ?? '—'),
              _item('Statut', _user.enabled ? 'Actif' : 'Inactif'),
            ],
          ),
        ),
        if (widget.isEmbedded) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetPassword,
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Réinitialiser le mot de passe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kWarningAmber.withValues(alpha: 0.15),
                foregroundColor: AppTheme.kWarningAmber,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await AppDialogs.showConfirm(
                  context: context,
                  title: _user.enabled
                      ? 'Désactiver l\'utilisateur'
                      : 'Activer l\'utilisateur',
                  message: _user.enabled
                      ? '${_user.displayName} ne pourra plus se connecter à l\'ERP.'
                      : '${_user.displayName} pourra de nouveau se connecter à l\'ERP.',
                  confirmLabel: _user.enabled ? 'Désactiver' : 'Activer',
                );
                if (confirm == true) await _toggleEnabled();
              },
              icon: Icon(
                  _user.enabled ? Icons.block_outlined : Icons.check_circle_outlined),
              label: Text(_user.enabled ? 'Désactiver le compte' : 'Activer le compte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _user.enabled
                    ? AppTheme.kErrorRed.withValues(alpha: 0.12)
                    : AppTheme.kSuccessGreen.withValues(alpha: 0.12),
                foregroundColor:
                    _user.enabled ? AppTheme.kErrorRed : AppTheme.kSuccessGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _item(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.kTextSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: AppTheme.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}
