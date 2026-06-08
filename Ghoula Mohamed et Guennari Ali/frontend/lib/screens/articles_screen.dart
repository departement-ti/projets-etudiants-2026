import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/article_provider.dart';
import '../models/article.dart';
import '../widgets/app_drawer.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/professional_dialogs.dart';
import '../constants/app_theme.dart';
import 'article_form_screen.dart';
import 'article_detail_screen.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArticleProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticleProvider>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(BrandAppBar.heightFor(context)),
        child: BrandAppBar(
          title: 'Articles',
          currentRoute: '/articles',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => context.read<ArticleProvider>().load(),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/articles'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel article'),
      ),
      body: AppTheme.glassBackground(
        child: Column(
          children: [
            _SearchBar(controller: _searchController, provider: provider),
            _FilterChips(provider: provider),
            Expanded(child: _ArticleList(provider: provider)),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, [Article? article]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleFormScreen(article: article),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ArticleProvider provider;
  const _SearchBar({required this.controller, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AppTheme.gradientBar(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          controller: controller,
          onChanged: provider.setSearch,
          decoration: InputDecoration(
            hintText: 'Rechercher par référence ou désignation…',
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
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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

class _FilterChips extends StatelessWidget {
  final ArticleProvider provider;
  const _FilterChips({required this.provider});

  static const filters = [
    ('TOUS', 'Tous'),
    ('MP', 'Matières Premières'),
    ('PSF', 'Semi-Finis'),
    ('PF', 'Produits Finis'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppTheme.gradientBar(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((f) {
              final selected = provider.filterType == f.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f.$2),
                  selected: selected,
                  onSelected: (_) => provider.setFilter(f.$1),
                  selectedColor: AppTheme.kPrimaryBurgundyLight,
                  checkmarkColor: AppTheme.kPrimaryBurgundy,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? AppTheme.kPrimaryBurgundy
                        : AppTheme.kTextSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ArticleList extends StatelessWidget {
  final ArticleProvider provider;
  const _ArticleList({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: AppTheme.kTextHint),
            const SizedBox(height: 12),
            Text(provider.error!,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ArticleProvider>().load(),
              style: AppTheme.primaryButton,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (provider.articles.isEmpty) {
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
      onRefresh: () => context.read<ArticleProvider>().load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.articles.length,
        itemBuilder: (ctx, i) => _ArticleCard(article: provider.articles[i]),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  const _ArticleCard({required this.article});

  static const typeColors = {
    'MP': AppTheme.kPrimaryBurgundy,
    'PSF': AppTheme.kSecondaryTan,
    'PF': AppTheme.kSuccessGreen,
  };

  @override
  Widget build(BuildContext context) {
    final color = typeColors[article.type] ?? AppTheme.kTextSecondary;
    final priceFmt =
        NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
      ),
      child: AppTheme.withGlass(
      radius: 12,
      blur: 16,
      opacity: 0.7,
      margin: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(article.type,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(article.designation,
                                    style: AppTheme.titleSmall.copyWith(fontSize: 14)),
                              ),
                              if (article.enAlerte)
                                const Icon(Icons.warning_amber,
                                    color: AppTheme.kPrimaryBurgundyLight, size: 16),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Réf: ${article.reference}',
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.kTextSecondary)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Stock: ${article.stockActuel} ${article.uniteMesure ?? ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: article.enAlerte
                                      ? AppTheme.kErrorRed
                                      : AppTheme.kTextSecondary,
                                  fontWeight: article.enAlerte
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(priceFmt.format(article.prixUnitaire),
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppTheme.kTextPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.kTextSecondary),
                      onSelected: (val) => _onAction(context, val),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ])),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: AppTheme.kErrorRed),
                              SizedBox(width: 8),
                              Text('Supprimer',
                                  style: TextStyle(color: AppTheme.kErrorRed)),
                            ])),
                      ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
     );
  }

  void _onAction(BuildContext context, String action) {
    if (action == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ArticleFormScreen(article: article)),
      );
    } else if (action == 'delete') {
      _confirmDelete(context);
    }
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
