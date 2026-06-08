import 'package:flutter/material.dart';
import '../models/fournisseur.dart';
import '../constants/app_theme.dart';

class FournisseurDetailScreen extends StatelessWidget {
  final Fournisseur fournisseur;
  final bool isEmbedded;
  const FournisseurDetailScreen({super.key, required this.fournisseur, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (isEmbedded) return content;
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundCream,
      appBar: AppBar(title: Text(fournisseur.raisonSociale)),
      body: content,
    );
  }

  Widget _buildContent() {
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
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fournisseur.raisonSociale,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    if (fournisseur.matriculeFiscal != null)
                      Text('MF: ${fournisseur.matriculeFiscal}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.kSurfaceWhite,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            boxShadow: AppTheme.shadowSm,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Coordonnées', style: AppTheme.titleSmall.copyWith(fontSize: 14)),
              const SizedBox(height: 12),
              _contactRow(Icons.phone_outlined, fournisseur.telephone ?? '—'),
              _contactRow(Icons.email_outlined, fournisseur.email ?? '—'),
              _contactRow(Icons.location_on_outlined, fournisseur.adresse ?? '—'),
              _contactRow(Icons.location_city_outlined, fournisseur.ville ?? '—'),
              if (fournisseur.pays != null)
                _contactRow(Icons.public_outlined, fournisseur.pays!),
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
              Text('Informations', style: AppTheme.titleSmall.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              _item('Raison sociale', fournisseur.raisonSociale),
              _item('Matricule fiscal', fournisseur.matriculeFiscal ?? '—'),
              _item('Téléphone', fournisseur.telephone ?? '—'),
              _item('Email', fournisseur.email ?? '—'),
              _item('Adresse', fournisseur.adresse ?? '—'),
              _item('Ville', fournisseur.ville ?? '—'),
              _item('Pays', fournisseur.pays ?? 'Tunisie'),
              _item('Catégorie', fournisseur.categorieProduit ?? '—'),
              _item('Mode de paiement', fournisseur.modePaiement ?? '—'),
              _item('Actif', fournisseur.actif ? 'Oui' : 'Non'),
            ],
          ),
        ),
        if (isEmbedded) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Modifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kPrimaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

Widget _contactRow(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.kTextSecondary),
          const SizedBox(width: 10),
          Text(text, style: AppTheme.bodyMedium),
        ],
      ),
    );

Widget _item(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary))),
          Expanded(child: Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
