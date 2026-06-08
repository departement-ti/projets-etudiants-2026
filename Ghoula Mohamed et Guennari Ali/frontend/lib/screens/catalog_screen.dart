import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rayhan_erp/providers/catalog_provider.dart';
import 'package:rayhan_erp/providers/auth_provider.dart';
import 'package:rayhan_erp/models/article.dart';
import 'package:rayhan_erp/constants/app_theme.dart';
import 'package:rayhan_erp/widgets/client_scaffold.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogProvider>();
    final pfArticles = provider.articles.where((a) => a.type == 'PF').toList();

    return ClientScaffold(
      currentRoute: '/catalogue',
      body: AppTheme.glassBackground(
        child: Column(
          children: [
            _CatalogSearchBar(controller: _searchController, provider: provider),
            Expanded(child: _buildContent(provider, pfArticles)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CatalogProvider provider, List<Article> articles) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.kTextHint),
            const SizedBox(height: 12),
            Text(provider.error!,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<CatalogProvider>().load(),
              style: AppTheme.primaryButton,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: AppTheme.kBorderLight),
            const SizedBox(height: 16),
            Text('Aucun article trouvé',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<CatalogProvider>().load(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 3 : 2;
          final spacing = 10.0;
          final padding = 16.0 * 2;
          final totalSpacing = spacing * (crossAxisCount - 1);
          final itemWidth = (constraints.maxWidth - padding - totalSpacing) / crossAxisCount;
          const contentHeight = 117.0;
          final aspectRatio = itemWidth / (itemWidth + contentHeight);

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: articles.length,
            itemBuilder: (ctx, i) => _ProductCard(article: articles[i]),
          );
        },
      ),
    );
  }
}

class _CatalogSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final CatalogProvider provider;
  const _CatalogSearchBar({required this.controller, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AppTheme.gradientBar(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          controller: controller,
          onChanged: provider.setSearch,
          decoration: InputDecoration(
            hintText: 'Rechercher un produit…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      provider.setSearch('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppTheme.kInputFill,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Article article;
  const _ProductCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final priceFmt =
        NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);
    return GestureDetector(
      onTap: () {
        if (article.id != null) context.push('/catalogue/${article.id}');
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                article.assetImage != null
                    ? 'assets/images/products/${article.assetImage}'
                    : 'assets/images/products/product_poubelle.jpg',
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.designation,
                    style: AppTheme.titleSmall.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceFmt.format(article.prixUnitaire),
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kPrimaryRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (article.id == null) return;
                          final loggedIn = context
                              .read<AuthProvider>()
                              .isAuthenticated;
                          if (loggedIn) {
                            context.push(
                                '/catalogue/commander?articleId=${article.id}');
                          } else {
                            final redirect = Uri.encodeComponent(
                                '/catalogue/commander?articleId=${article.id}');
                            context.push('/login?redirect=$redirect');
                          }
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kSuccessGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Commander',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
