import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/article_provider.dart';
import '../models/article.dart';
import '../widgets/app_drawer.dart';
import '../widgets/brand_app_bar.dart';
import '../constants/app_theme.dart';
import 'stock_detail_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _filter = 'TOUS';
  final _searchCtrl = TextEditingController();
  String _search = '';
  Article? _selectedArticle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArticleProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isDesktop => MediaQuery.of(context).size.width > 900;

  List<Article> _filtered(List<Article> articles) {
    return articles.where((a) {
      final matchType = _filter == 'TOUS' || a.type == _filter;
      final matchAlerte = _filter == 'ALERTE' ? a.enAlerte : true;
      final matchSearch = _search.isEmpty ||
          a.reference.toLowerCase().contains(_search.toLowerCase()) ||
          a.designation.toLowerCase().contains(_search.toLowerCase());
      return (matchType || matchAlerte) && matchSearch;
    }).toList()
      ..sort((a, b) {
        if (a.enAlerte && !b.enAlerte) return -1;
        if (!a.enAlerte && b.enAlerte) return 1;
        return a.designation.compareTo(b.designation);
      });
  }

  static const _filters = [
    ('TOUS', 'Tous'),
    ('ALERTE', 'Alertes'),
    ('MP', 'MP'),
    ('PSF', 'PSF'),
    ('PF', 'PF'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticleProvider>();
    final articles = _filtered(provider.articles);
    final alertCount = provider.articles.where((a) => a.enAlerte).length;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(BrandAppBar.heightFor(context)),
        child: BrandAppBar(
          title: 'Stock',
          subtitle: !provider.isLoading
              ? '${provider.articles.length} articles · $alertCount en alerte'
              : null,
          currentRoute: '/stock',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => context.read<ArticleProvider>().load(),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/stock'),
      body: AppTheme.glassBackground(
        child: _isDesktop && _selectedArticle != null
            ? Row(
                children: [
                  SizedBox(
                    width: 380,
                    child: _buildListPanel(provider, articles),
                  ),
                  Container(width: 1, color: AppTheme.kBorderLight),
                  Expanded(
                    child: StockDetailScreen(
                      article: _selectedArticle!,
                      isEmbedded: true,
                    ),
                  ),
                ],
              )
            : _buildListPanel(provider, articles),
      ),
    );
  }

  Widget _buildListPanel(ArticleProvider provider, List<Article> articles) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        Expanded(child: _buildList(provider, articles)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return AppTheme.gradientBar(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Rechercher un article…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _search.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() {
                      _searchCtrl.clear();
                      _search = '';
                    }),
                  )
                : null,
            filled: true,
            fillColor: AppTheme.kInputFill,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return AppTheme.gradientBar(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((f) {
              final selected = _filter == f.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f.$2),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f.$1),
                  selectedColor: f.$1 == 'ALERTE'
                      ? AppTheme.kErrorRedLight
                      : AppTheme.kPrimaryBurgundyLight,
                  checkmarkColor: f.$1 == 'ALERTE'
                      ? AppTheme.kErrorRed
                      : AppTheme.kPrimaryBurgundy,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? (f.$1 == 'ALERTE'
                            ? AppTheme.kErrorRed
                            : AppTheme.kPrimaryBurgundy)
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

  Widget _buildList(ArticleProvider provider, List<Article> articles) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
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
              onPressed: () => context.read<ArticleProvider>().load(),
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
            Icon(Icons.warehouse_outlined,
                size: 64, color: AppTheme.kBorderLight),
            const SizedBox(height: 16),
            Text('Aucun article',
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
        itemCount: articles.length,
        itemBuilder: (ctx, i) => _StockCard(
          article: articles[i],
          isSelected: _selectedArticle?.id == articles[i].id,
          onTap: _isDesktop
              ? () => setState(() => _selectedArticle = articles[i])
              : () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => StockDetailScreen(article: articles[i]))),
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final Article article;
  final bool isSelected;
  final VoidCallback onTap;
  const _StockCard({required this.article, this.isSelected = false, required this.onTap});

  static const typeColors = {
    'MP': AppTheme.kPrimaryBurgundy,
    'PSF': AppTheme.kSecondaryTan,
    'PF': AppTheme.kSuccessGreen,
  };

  @override
  Widget build(BuildContext context) {
    final typeColor = typeColors[article.type] ?? AppTheme.kTextSecondary;
    final pct = article.stockMinimum > 0
        ? (article.stockActuel / article.stockMinimum).clamp(0.0, 2.0)
        : 1.0;
    final barColor =
        article.enAlerte ? AppTheme.kErrorRed : AppTheme.kSuccessGreen;

    return GestureDetector(
      onTap: onTap,
      child: AppTheme.withGlass(
        radius: 12,
        blur: 16,
        opacity: 0.7,
        margin: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: barColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(article.type,
                                  style: TextStyle(
                                      color: typeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(article.designation,
                                  style:
                                      AppTheme.titleSmall.copyWith(fontSize: 14)),
                            ),
                            if (article.enAlerte)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.kErrorRedLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber,
                                        color: AppTheme.kErrorRed, size: 12),
                                    const SizedBox(width: 3),
                                    const Text('ALERTE',
                                        style: TextStyle(
                                            color: AppTheme.kErrorRed,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(article.reference,
                            style: AppTheme.bodySmall
                                .copyWith(color: AppTheme.kTextSecondary)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Stock : ${article.stockActuel.toStringAsFixed(2)} ${article.uniteMesure ?? ''}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: article.enAlerte
                                                ? AppTheme.kErrorRed
                                                : AppTheme.kTextPrimary),
                                      ),
                                      Text(
                                        'Min : ${article.stockMinimum.toStringAsFixed(2)}',
                                        style: AppTheme.bodySmall
                                            .copyWith(color: AppTheme.kTextSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (pct / 2).clamp(0.0, 1.0),
                                      backgroundColor: AppTheme.kBorderLight,
                                      color: barColor,
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.chevron_right, color: AppTheme.kTextHint),
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
      ),
    );
  }
}
