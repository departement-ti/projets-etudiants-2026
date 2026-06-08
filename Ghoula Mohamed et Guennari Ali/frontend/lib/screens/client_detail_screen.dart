import 'package:flutter/material.dart';
import '../models/client.dart';
import '../constants/app_theme.dart';

class ClientDetailScreen extends StatelessWidget {
  final Client client;
  final bool isEmbedded;
  const ClientDetailScreen({super.key, required this.client, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (isEmbedded) return content;
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundCream,
      appBar: AppBar(title: Text(client.raisonSociale)),
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
                child: const Icon(Icons.business, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.raisonSociale,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    if (client.matriculeFiscal != null)
                      Text('MF: ${client.matriculeFiscal}',
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
              _contactRow(Icons.phone_outlined, client.telephone ?? '—'),
              _contactRow(Icons.email_outlined, client.email ?? '—'),
              _contactRow(Icons.location_on_outlined, client.adresse ?? '—'),
              _contactRow(Icons.location_city_outlined, client.ville ?? '—'),
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
              _item('Raison sociale', client.raisonSociale),
              _item('Matricule fiscal', client.matriculeFiscal ?? '—'),
              _item('Téléphone', client.telephone ?? '—'),
              _item('Email', client.email ?? '—'),
              _item('Adresse', client.adresse ?? '—'),
              _item('Ville', client.ville ?? '—'),
              _item('Type client', client.typeClient ?? '—'),
              _item('Plafond crédit', client.plafondCredit != null ? '${client.plafondCredit!.toStringAsFixed(3)} TND' : '—'),
              _item('Délai paiement', client.delaiPaiement != null ? '${client.delaiPaiement} jours' : '—'),
              _item('Représentant', client.representantNom ?? '—'),
              _item('Tél. représentant', client.representantTelephone ?? '—'),
              _item('Actif', client.actif ? 'Oui' : 'Non'),
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
