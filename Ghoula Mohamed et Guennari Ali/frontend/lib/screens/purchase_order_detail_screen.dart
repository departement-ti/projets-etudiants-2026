import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/purchase_order.dart';
import '../providers/achats_provider.dart';
import '../constants/app_theme.dart';
import '../widgets/professional_dialogs.dart';
import '../services/pdf_service.dart';

class PurchaseOrderDetailScreen extends StatelessWidget {
  final PurchaseOrder order;
  final bool isEmbedded;
  const PurchaseOrderDetailScreen({super.key, required this.order, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);
    final statusColor = Color(order.statutColor);
    final content = _buildContent(context, fmt, statusColor);
    if (isEmbedded) return content;
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundCream,
      appBar: AppBar(
        title: Text(order.reference ?? '—'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exporter en PDF',
            onPressed: () async {
              final bytes = await PdfService.generatePurchaseReceipt(order);
              PdfService.downloadPdf(bytes, 'BR_${order.reference ?? "N/A"}.pdf');
            },
          ),
          if (order.peutReceptionner)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ElevatedButton.icon(
                onPressed: () => _confirmReceive(context),
                icon: const Icon(Icons.inventory_outlined, size: 18),
                label: const Text('Réceptionner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryRed,
                  foregroundColor: AppTheme.kSurfaceWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context, NumberFormat fmt, Color statusColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, color: statusColor, size: 10),
              const SizedBox(width: 8),
              Text(order.statutLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecorationMd,
          child: Column(
            children: [
              _infoRow(label: 'Fournisseur', value: order.fournisseur?.raisonSociale ?? '—'),
              _infoRow(label: 'Date commande', value: order.dateCommande),
              if (order.dateLivraisonPrevue != null)
                _infoRow(label: 'Livraison prévue', value: order.dateLivraisonPrevue!),
              if (order.notes != null && order.notes!.isNotEmpty)
                _infoRow(label: 'Notes', value: order.notes!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Lignes de commande', style: AppTheme.titleSmall.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        ...order.lignes.map((l) => _LigneCard(ligne: l, fmt: fmt)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecorationMd,
          child: Column(
            children: [
              _infoRow(label: 'Total HT', value: fmt.format(order.totalHT)),
              _infoRow(label: 'TVA (19%)', value: fmt.format(order.totalTVA)),
              const Divider(color: AppTheme.kBorderLight),
              _totalRow(label: 'Total TTC', value: fmt.format(order.totalTTC), bold: true),
            ],
          ),
        ),
        if (isEmbedded) ...[
          const SizedBox(height: 16),
          if (order.peutReceptionner)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmReceive(context),
                icon: const Icon(Icons.inventory_outlined, size: 18),
                label: const Text('Réceptionner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryRed,
                  foregroundColor: AppTheme.kSurfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final bytes = await PdfService.generatePurchaseReceipt(order);
                PdfService.downloadPdf(bytes, 'BR_${order.reference ?? "N/A"}.pdf');
              },
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Imprimer PDF'),
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

  void _confirmReceive(BuildContext context) {
    AppDialogs.showConfirm(
      context: context,
      title: 'Confirmer la réception ?',
      message: 'Réceptionner toutes les lignes de ${order.reference} ?\n\nLe stock sera incrémenté automatiquement.',
      confirmLabel: 'Réceptionner',
      icon: Icons.inventory_outlined,
      accentColor: AppTheme.kPrimaryRed,
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<AchatsProvider>().receive(order.id!, order.lignes).then((err) {
          if (context.mounted) {
            if (err == null) {
              if (!isEmbedded) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Réception enregistrée — stock mis à jour'),
                backgroundColor: AppTheme.kSuccessGreen,
              ));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err), backgroundColor: AppTheme.kErrorRed));
            }
          }
        });
      }
    });
  }
}

Widget _infoRow({required String label, required String value}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary))),
          Expanded(child: Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );

class _LigneCard extends StatelessWidget {
  final PurchaseOrderLine ligne;
  final NumberFormat fmt;
  const _LigneCard({required this.ligne, required this.fmt});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.kSurfaceWhite,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ligne.article?.designation ?? '—',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${ligne.quantiteCommandee} ${ligne.article?.uniteMesure ?? ''} × ${fmt.format(ligne.prixUnitaireHT)}',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
                Text(fmt.format(ligne.montantTTC ?? ligne.montantTTCCalc),
                    style: AppTheme.titleSmall.copyWith(color: AppTheme.kPrimaryRed)),
              ],
            ),
            if (ligne.quantiteRecue > 0)
              Text('Reçu : ${ligne.quantiteRecue}',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.kSuccessGreen)),
          ],
        ),
      );
}

Widget _totalRow({required String label, required String value, bool bold = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 16 : 13,
                  color: AppTheme.kTextPrimary)),
        ],
      ),
    );
