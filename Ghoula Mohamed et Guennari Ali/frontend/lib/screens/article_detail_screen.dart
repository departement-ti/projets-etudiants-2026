import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';
import '../providers/article_provider.dart';
import '../constants/app_theme.dart';
import '../widgets/professional_dialogs.dart';
import 'article_form_screen.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundCream,
      appBar: AppBar(
        title: Text(article.reference),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ArticleFormScreen(article: article),
              ));
            },
          ),
        ],
      ),
      body: ListView(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(article.type,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Text(article.typeLabel,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(article.designation,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statCol(label: 'Stock actuel', value: '${article.stockActuel.toStringAsFixed(2)} ${article.uniteMesure ?? ''}'),
                    _statCol(label: 'Seuil min', value: '${article.stockMinimum.toStringAsFixed(2)} ${article.uniteMesure ?? ''}'),
                    _statCol(label: 'Prix unitaire', value: fmt.format(article.prixUnitaire)),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecorationMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informations', style: AppTheme.titleSmall.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                _item('Référence', article.reference),
                _item('Désignation', article.designation),
                _item('Type', '${article.type} — ${article.typeLabel}'),
                _item('Unité de mesure', article.uniteMesure ?? '—'),
                _item('Prix unitaire', fmt.format(article.prixUnitaire)),
                _item('Stock actuel', '${article.stockActuel.toStringAsFixed(2)} ${article.uniteMesure ?? ''}'),
                _item('Stock minimum', '${article.stockMinimum.toStringAsFixed(2)} ${article.uniteMesure ?? ''}'),
                _item('Actif', article.actif ? 'Oui' : 'Non'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kErrorRed,
                foregroundColor: AppTheme.kSurfaceWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    AppDialogs.showDelete(
      context: context,
      title: "Supprimer l'article ?",
      itemName: article.designation,
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<ArticleProvider>().delete(article.id!).then((ok) {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok ? 'Article archivé' : 'Erreur lors de la suppression'),
              backgroundColor: ok ? AppTheme.kSuccessGreen : AppTheme.kErrorRed,
            ));
          }
        });
      }
    });
  }
}

Widget _statCol({required String label, required String value}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
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
