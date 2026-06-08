import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rayhan_erp/providers/catalog_provider.dart';
import 'package:rayhan_erp/models/article.dart';
import 'package:rayhan_erp/constants/app_theme.dart';
import 'package:rayhan_erp/widgets/client_scaffold.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogProvider>();
    final id =
        int.parse(GoRouterState.of(context).pathParameters['id'] ?? '0');

    late final Article article;
    try {
      article = provider.allArticles.firstWhere((a) => a.id == id);
    } catch (_) {
      if (!provider.isLoading) {
        return ClientScaffold(
          currentRoute: '/catalogue',
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppTheme.kTextHint),
                const SizedBox(height: 12),
                Text('Article introuvable',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.kTextSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: AppTheme.primaryButton,
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        );
      }
      return const ClientScaffold(
        currentRoute: '/catalogue',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final priceFmt =
        NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);

    return ClientScaffold(
      currentRoute: '/catalogue',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Text('Détail produit', style: AppTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              article.assetImage != null
                  ? 'assets/images/products/${article.assetImage}'
                  : 'assets/images/products/product_poubelle.jpg',
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          Text(article.designation,
              style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Réf: ${article.reference}',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.kTextSecondary)),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.kSuccessGreenLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(article.typeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.kSuccessGreen,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecorationMd,
            child: Column(
              children: [
                _infoRow('Prix unitaire',
                    priceFmt.format(article.prixUnitaire)),
                const SizedBox(height: 8),
                _infoRow('Unité de mesure',
                    article.uniteMesure ?? '—'),
                const SizedBox(height: 8),
                _infoRow('Type', article.typeLabel),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Quantité', style: AppTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.kBorderLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_quantity',
                        style: AppTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final articleId = article.id;
                if (articleId != null) {
                  context.push(
                    '/catalogue/commander?articleId=$articleId&quantity=$_quantity',
                  );
                }
              },
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text(
                'Commander — ${priceFmt.format(article.prixUnitaire * _quantity)}',
                style: const TextStyle(fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kSuccessGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

Widget _infoRow(String label, String value) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTheme.bodyMedium
                .copyWith(color: AppTheme.kTextSecondary)),
        Text(value,
            style: AppTheme.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
      ],
    );
