import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';
import '../models/stock_movement.dart';
import '../providers/stock_provider.dart';
import '../providers/article_provider.dart';
import '../constants/app_theme.dart';
import '../services/pdf_service.dart';

class StockDetailScreen extends StatefulWidget {
  final Article article;
  final bool isEmbedded;
  const StockDetailScreen({super.key, required this.article, this.isEmbedded = false});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadHistorique(widget.article.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();
    final historique = stockProvider.historiqueOf(widget.article.id!);
    final article = widget.article;
    final priceFmt = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);
    final content = _buildContent(context, stockProvider, historique, article, priceFmt);
    if (widget.isEmbedded) return content;
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundCream,
      appBar: AppBar(
        title: Text(article.reference),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exporter en PDF',
            onPressed: () async {
              final bytes = await PdfService.generateStockReport(article, historique);
              PdfService.downloadPdf(bytes, 'STOCK_${article.reference}.pdf');
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Ajustement manuel',
            onPressed: () => _showAdjustDialog(context),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context, StockProvider stockProvider, List<StockMovement> historique, Article article, NumberFormat priceFmt) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: article.enAlerte ? AppTheme.kCtaGradient : AppTheme.kPrimaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.designation,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${article.type} · ${article.uniteMesure ?? ''}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatCol(label: 'Stock actuel', value: article.stockActuel.toStringAsFixed(2)),
                  _StatCol(label: 'Seuil minimum', value: article.stockMinimum.toStringAsFixed(2)),
                  _StatCol(label: 'Prix unitaire', value: priceFmt.format(article.prixUnitaire)),
                ],
              ),
              if (article.enAlerte) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('Stock inférieur au seuil minimum — réapprovisionner',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Historique des mouvements', style: AppTheme.titleSmall.copyWith(fontSize: 14)),
            if (stockProvider.isLoading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 10),
        if (historique.isEmpty && !stockProvider.isLoading)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.kSurfaceWhite, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text('Aucun mouvement enregistré',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.kTextSecondary)),
            ),
          ),
        ...historique.map((m) => _MovementCard(movement: m)),
        if (widget.isEmbedded) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAdjustDialog(context),
              icon: const Icon(Icons.tune_outlined, size: 18),
              label: const Text('Ajustement manuel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kWarningAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final bytes = await PdfService.generateStockReport(article, historique);
                PdfService.downloadPdf(bytes, 'STOCK_${article.reference}.pdf');
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

  void _showAdjustDialog(BuildContext context) {
    final qteCtrl = TextEditingController();
    final motifCtrl = TextEditingController();
    String type = 'IN';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 32 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.kBorderLight, borderRadius: BorderRadius.circular(2)),
                margin: const EdgeInsets.only(bottom: 20),
              ),
              Text('Ajustement de stock', style: AppTheme.headlineSmall.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text(widget.article.designation,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text('Stock actuel : ${widget.article.stockActuel}',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TypeBtn(
                      label: 'Entrée',
                      icon: Icons.add_circle_outline,
                      color: AppTheme.kSuccessGreen,
                      selected: type == 'IN',
                      onTap: () => setDlgState(() => type = 'IN'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeBtn(
                      label: 'Sortie',
                      icon: Icons.remove_circle_outline,
                      color: AppTheme.kErrorRed,
                      selected: type == 'OUT',
                      onTap: () => setDlgState(() => type = 'OUT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qteCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  filled: true,
                  fillColor: AppTheme.kInputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motifCtrl,
                decoration: InputDecoration(
                  labelText: 'Motif',
                  hintText: 'Inventaire, correction, perte…',
                  filled: true,
                  fillColor: AppTheme.kInputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: type == 'IN' ? AppTheme.kSuccessGreen : AppTheme.kErrorRed,
                  foregroundColor: AppTheme.kSurfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final qte = double.tryParse(qteCtrl.text) ?? 0;
                  if (qte <= 0) return;
                  Navigator.pop(ctx);
                  final err = await context.read<StockProvider>().adjust(
                        articleId: widget.article.id!,
                        quantite: qte,
                        type: type,
                        motif: motifCtrl.text.trim().isEmpty ? 'Ajustement manuel' : motifCtrl.text.trim(),
                      );
                  if (context.mounted) {
                    context.read<ArticleProvider>().load();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(err ?? 'Stock ajusté avec succès'),
                      backgroundColor: err == null ? AppTheme.kSuccessGreen : AppTheme.kErrorRed,
                    ));
                  }
                },
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      );
}

class _MovementCard extends StatelessWidget {
  final StockMovement movement;
  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isEntree;
    final color = isIn ? AppTheme.kSuccessGreen : AppTheme.kErrorRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppTheme.kSurfaceWhite, borderRadius: BorderRadius.circular(10), boxShadow: AppTheme.shadowSm),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isIn ? '+${movement.quantite}' : '-${movement.quantite}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                      Text(movement.dateFormatted,
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(movement.sourceLabel, style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
                  if (movement.referenceDocument != null && movement.referenceDocument != 'ADJ')
                    Text(movement.referenceDocument!,
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
                  if (movement.motif != null)
                    Text(movement.motif!, style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
                  if (movement.stockApres != null) ...[
                    const SizedBox(height: 2),
                    Text('Stock après : ${movement.stockApres!.toStringAsFixed(2)}',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : AppTheme.kInputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? color : AppTheme.kBorderLight, width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? color : AppTheme.kTextSecondary, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: selected ? color : AppTheme.kTextSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13)),
            ],
          ),
        ),
      );
}
