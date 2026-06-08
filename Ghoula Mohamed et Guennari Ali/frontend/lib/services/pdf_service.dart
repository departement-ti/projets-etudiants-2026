import 'dart:typed_data';
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/purchase_order.dart';
import '../models/sales_order.dart';
import '../models/production_order.dart';
import '../models/article.dart';
import '../models/stock_movement.dart';
import 'pdf_templates.dart';
import '../constants/app_theme.dart';

class PdfService {
  PdfService._();

  static Future<void> init() async {}

  static Future<Uint8List> generatePurchaseReceipt(PurchaseOrder order) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          PdfBrandedHeader.build(
            title: 'Bon de Réception',
            reference: 'BR-${order.reference ?? "N/A"}',
            subtitle: 'Date: ${order.dateCommande}',
          ),
          pw.SizedBox(height: 16),
          _infoBlock('Fournisseur', [
            order.fournisseur?.raisonSociale ?? '—',
            order.fournisseur?.adresse ?? '',
            order.fournisseur?.matriculeFiscal ?? '',
          ]),
          pw.SizedBox(height: 16),
          PdfLineItemTable.build(
            columns: ['Réf', 'Désignation', 'Qté', 'PU HT', 'Total HT'],
            columnWidths: [0.15, 0.35, 0.15, 0.15, 0.2],
            items: order.lignes.map((l) => PdfLineItem([
              l.article?.reference ?? '',
              l.article?.designation ?? '',
              l.quantiteCommandee.toString(),
              'TND ${l.prixUnitaireHT.toStringAsFixed(3)}',
              'TND ${(l.quantiteCommandee * l.prixUnitaireHT).toStringAsFixed(3)}',
            ])).toList(),
          ),
          pw.SizedBox(height: 8),
          PdfTotalsBox.build(
            totalHT: order.totalHT,
            totalTVA: order.totalTVA,
            totalTTC: order.totalTTC,
          ),
          pw.SizedBox(height: 24),
          PdfFooter.build(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> generateSalesInvoice(SalesOrder order) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          PdfBrandedHeader.build(
            title: 'Facture',
            reference: 'FAC-${order.reference ?? "N/A"}',
            subtitle: 'Date: ${order.dateCommande}',
          ),
          pw.SizedBox(height: 16),
          _infoBlock('Client', [
            order.client?.raisonSociale ?? '—',
            order.client?.adresse ?? '',
            order.client?.matriculeFiscal ?? '',
          ]),
          pw.SizedBox(height: 16),
          PdfLineItemTable.build(
            columns: ['Réf', 'Désignation', 'Qté', 'PU HT', 'Total HT'],
            columnWidths: [0.15, 0.35, 0.15, 0.15, 0.2],
            items: order.lignes.map((l) => PdfLineItem([
              l.article?.reference ?? '',
              l.article?.designation ?? '',
              l.quantiteCommandee.toString(),
              'TND ${l.prixUnitaireHT.toStringAsFixed(3)}',
              'TND ${(l.quantiteCommandee * l.prixUnitaireHT).toStringAsFixed(3)}',
            ])).toList(),
          ),
          pw.SizedBox(height: 8),
          PdfTotalsBox.build(
            totalHT: order.totalHT,
            totalTVA: order.totalTVA,
            totalTTC: order.totalTTC,
          ),
          pw.SizedBox(height: 24),
          PdfFooter.build(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> generateStockReport(
      Article article, List<StockMovement> movements) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          PdfBrandedHeader.build(
            title: 'Fiche de Stock',
            reference: article.reference,
            subtitle: article.designation,
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _statBox('Stock actuel', '${article.stockActuel} ${article.uniteMesure ?? ''}'),
              pw.SizedBox(width: 12),
              _statBox('Stock min', '${article.stockMinimum} ${article.uniteMesure ?? ''}'),
              pw.SizedBox(width: 12),
              _statBox('Type', article.typeLabel),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Historique des mouvements',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          PdfLineItemTable.build(
            columns: ['Date', 'Type', 'Qté', 'Motif'],
            columnWidths: [0.25, 0.15, 0.15, 0.45],
            items: movements.map((m) => PdfLineItem([
              m.dateFormatted,
              m.isEntree ? 'Entrée' : 'Sortie',
              '${m.quantite}',
              m.motif ?? '—',
            ])).toList(),
          ),
          pw.SizedBox(height: 24),
          PdfFooter.build(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> generateProductionReport(
      ProductionOrder order) async {
    final pct = order.quantitePlanifiee > 0
        ? (order.quantiteRealisee / order.quantitePlanifiee * 100).toInt()
        : 0;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          PdfBrandedHeader.build(
            title: 'Ordre de Fabrication',
            reference: order.reference ?? 'N/A',
            subtitle: 'Statut: ${order.statut}',
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _statBox('Planifié', '${order.quantitePlanifiee}'),
              pw.SizedBox(width: 12),
              _statBox('Réalisé', '${order.quantiteRealisee}'),
              pw.SizedBox(width: 12),
              _statBox('Avancement', '$pct%'),
            ],
          ),
          pw.SizedBox(height: 16),
          _infoBlock('Informations', [
            'Date planifiée: ${order.datePlanifiee}',
            if (order.dateLancement != null) 'Date lancement: ${order.dateLancement}',
            if (order.dateTerminaison != null) 'Date fin: ${order.dateTerminaison}',
            if (order.notes != null) 'Notes: ${order.notes}',
          ]),
          pw.SizedBox(height: 24),
          PdfFooter.build(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> generateArticleCatalog(
      List<Article> articles, String type) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          PdfBrandedHeader.build(
            title: 'Catalogue Articles',
            reference: type == 'TOUS' ? 'TOUS' : type,
          ),
          pw.SizedBox(height: 16),
          PdfLineItemTable.build(
            columns: ['Réf', 'Désignation', 'Type', 'Stock', 'PU'],
            columnWidths: [0.18, 0.35, 0.12, 0.12, 0.23],
            items: articles.map((a) => PdfLineItem([
              a.reference,
              a.designation,
              a.type,
              '${a.stockActuel} ${a.uniteMesure ?? ''}',
              'TND ${a.prixUnitaire.toStringAsFixed(3)}',
            ])).toList(),
          ),
          pw.SizedBox(height: 24),
          PdfFooter.build(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> generateDevis(SalesOrder order) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          PdfBrandedHeader.build(
            title: 'Devis',
            reference: 'DEV-001',
            subtitle: 'Date: ${order.dateCommande}',
          ),
          pw.SizedBox(height: 16),
          if (order.client != null)
            _infoBlock('Client', [
              order.client!.raisonSociale,
              order.client!.adresse ?? '',
              order.client!.matriculeFiscal ?? '',
            ]),
          pw.SizedBox(height: 16),
          PdfLineItemTable.build(
            columns: ['Réf', 'Désignation', 'Qté', 'PU HT', 'Total HT'],
            columnWidths: [0.15, 0.35, 0.15, 0.15, 0.2],
            items: order.lignes.map((l) => PdfLineItem([
              l.article?.reference ?? '',
              l.article?.designation ?? '',
              l.quantiteCommandee.toString(),
              'TND ${l.prixUnitaireHT.toStringAsFixed(3)}',
              'TND ${(l.quantiteCommandee * l.prixUnitaireHT).toStringAsFixed(3)}',
            ])).toList(),
          ),
          pw.SizedBox(height: 8),
          PdfTotalsBox.build(
            totalHT: order.totalHT,
            totalTVA: order.totalTVA,
            totalTTC: order.totalTTC,
          ),
          pw.SizedBox(height: 24),
          PdfFooter.build(),
        ],
      ),
    );
    return doc.save();
  }

  static void downloadPdf(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static pw.Widget _infoBlock(String title, List<String> lines) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border:
            pw.Border.all(color: PdfColor.fromInt(AppTheme.kBorderLight.value)),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(AppTheme.kTextPrimary.value))),
          pw.SizedBox(height: 4),
          ...lines.where((l) => l.isNotEmpty).map((l) => pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(l.replaceAll('null', '—'),
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
              )),
        ],
      ),
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(
              AppTheme.kPrimaryRed.withValues(alpha: 0.06).value),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ],
        ),
      ),
    );
  }
}
