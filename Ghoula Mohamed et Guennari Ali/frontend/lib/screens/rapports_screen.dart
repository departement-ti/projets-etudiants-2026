import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../providers/article_provider.dart';
import '../providers/ventes_provider.dart';
import '../providers/achats_provider.dart';
import '../providers/production_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/brand_app_bar.dart';
import '../constants/app_theme.dart';
import '../services/pdf_service.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
      context.read<ArticleProvider>().load();
      context.read<VentesProvider>().load();
      context.read<AchatsProvider>().load();
      context.read<ProductionProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(BrandAppBar.heightFor(context) + 76),
        child: Column(
          children: [
            BrandAppBar(
              title: 'Rapports',
              currentRoute: '/rapports',
            ),
            AppTheme.gradientBar(
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.kPrimaryRed,
                labelColor: AppTheme.kPrimaryRed,
                unselectedLabelColor: AppTheme.kTextSecondary,
                tabs: const [
                  Tab(
                      text: 'General',
                      icon: Icon(Icons.dashboard_outlined, size: 18)),
                  Tab(
                      text: 'Ventes',
                      icon: Icon(Icons.shopping_cart_outlined, size: 18)),
                  Tab(
                      text: 'Achats',
                      icon: Icon(Icons.local_shipping_outlined, size: 18)),
                  Tab(
                      text: 'Stock',
                      icon: Icon(Icons.warehouse_outlined, size: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/rapports'),
      body: AppTheme.glassBackground(
        child: TabBarView(
          controller: _tabController,
          children: const [
            _GeneralReport(),
            _VentesReport(),
            _AchatsReport(),
            _StockReport(),
          ],
        ),
      ),
    );
  }
}

class _GeneralReport extends StatelessWidget {
  const _GeneralReport();

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final fmt =
        NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 0);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Indicateurs cles',
          style: AppTheme.titleSmall.copyWith(fontSize: 16)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _kpiBox(
                'CA Mensuel',
                fmt.format(dash.kpi?.ventes.chiffreAffairesMois ?? 0),
                Icons.trending_up,
                AppTheme.kSuccessGreen)),
        const SizedBox(width: 8),
        Expanded(
            child: _kpiBox(
                'Alertes stock',
                '${dash.kpi?.stock.articlesEnAlerte ?? 0}',
                Icons.warning_amber,
                AppTheme.kErrorRed)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
            child: _kpiBox(
                'OF en cours',
                '${dash.kpi?.production.ofEnCours ?? 0}',
                Icons.precision_manufacturing,
                AppTheme.kPrimaryOrange)),
        const SizedBox(width: 8),
        Expanded(
            child: _kpiBox(
                'Commandes en attente',
                '${dash.kpi?.ventes.commandesEnCours ?? 0}',
                Icons.receipt_long,
                AppTheme.kPrimaryRed)),
      ]),
      const SizedBox(height: 24),
      Text('Actions rapides',
          style: AppTheme.titleSmall.copyWith(fontSize: 16)),
      const SizedBox(height: 12),
      _actionCard(context, Icons.picture_as_pdf_outlined,
          'Exporter le catalogue articles', AppTheme.kPrimaryRed, () async {
        final bytes = await PdfService.generateArticleCatalog(
          context.read<ArticleProvider>().articles,
          'TOUS',
        );
        PdfService.downloadPdf(bytes, 'CATALOGUE_ARTICLES.pdf');
      }),
    ]);
  }
}

class _VentesReport extends StatelessWidget {
  const _VentesReport();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VentesProvider>();
    final fmt =
        NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 0);
    final total = provider.orders.fold<double>(0, (sum, o) => sum + o.totalTTC);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(
            child: _kpiBox('Commandes', '${provider.orders.length}',
                Icons.receipt_long, AppTheme.kPrimaryRed)),
        const SizedBox(width: 8),
        Expanded(
            child: _kpiBox('Total TTC', fmt.format(total),
                Icons.account_balance, AppTheme.kSuccessGreen)),
      ]),
      const SizedBox(height: 16),
      ...provider.orders.map((o) => AppTheme.withGlass(
            radius: 10,
            blur: 12,
            opacity: 0.6,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(o.reference ?? '—',
                  style: AppTheme.titleSmall.copyWith(fontSize: 13)),
              subtitle: Text(o.client?.raisonSociale ?? '—',
                  style: AppTheme.bodySmall),
              trailing: Text(fmt.format(o.totalTTC),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kSuccessGreen,
                      fontSize: 13)),
            ),
          )),
      const SizedBox(height: 16),
      _actionCard(context, Icons.picture_as_pdf_outlined,
          'Exporter les ventes en PDF', AppTheme.kPrimaryRed, () async {
        for (final o in provider.orders.take(5)) {
          final bytes = await PdfService.generateSalesInvoice(o);
          PdfService.downloadPdf(bytes, 'FAC_${o.reference ?? "N/A"}.pdf');
        }
      }),
    ]);
  }
}

class _AchatsReport extends StatelessWidget {
  const _AchatsReport();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchatsProvider>();
    final fmt =
        NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 0);
    final total = provider.orders.fold<double>(0, (sum, o) => sum + o.totalTTC);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(
            child: _kpiBox('Commandes', '${provider.orders.length}',
                Icons.receipt_long, AppTheme.kPrimaryOrange)),
        const SizedBox(width: 8),
        Expanded(
            child: _kpiBox('Total TTC', fmt.format(total),
                Icons.account_balance, AppTheme.kPrimaryRed)),
      ]),
      const SizedBox(height: 16),
      ...provider.orders.map((o) => AppTheme.withGlass(
            radius: 10,
            blur: 12,
            opacity: 0.6,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(o.reference ?? '—',
                  style: AppTheme.titleSmall.copyWith(fontSize: 13)),
              subtitle: Text(o.fournisseur?.raisonSociale ?? '—',
                  style: AppTheme.bodySmall),
              trailing: Text(fmt.format(o.totalTTC),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kPrimaryRed,
                      fontSize: 13)),
            ),
          )),
      const SizedBox(height: 16),
      _actionCard(context, Icons.picture_as_pdf_outlined,
          'Exporter les achats en PDF', AppTheme.kPrimaryOrange, () async {
        for (final o in provider.orders.take(5)) {
          final bytes = await PdfService.generatePurchaseReceipt(o);
          PdfService.downloadPdf(bytes, 'BR_${o.reference ?? "N/A"}.pdf');
        }
      }),
    ]);
  }
}

class _StockReport extends StatelessWidget {
  const _StockReport();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticleProvider>();
    final alertes = provider.articles.where((a) => a.enAlerte).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(
            child: _kpiBox('Articles', '${provider.articles.length}',
                Icons.inventory_2, AppTheme.kPrimaryRed)),
        const SizedBox(width: 8),
        Expanded(
            child: _kpiBox('Alertes', '${alertes.length}', Icons.warning_amber,
                AppTheme.kErrorRed)),
      ]),
      const SizedBox(height: 16),
      if (alertes.isNotEmpty) ...[
        Text('Articles en alerte',
            style: AppTheme.titleSmall.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        ...alertes.map((a) => AppTheme.withGlass(
              radius: 10,
              blur: 12,
              opacity: 0.6,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.warning_amber,
                    color: AppTheme.kErrorRed, size: 20),
                title: Text(a.designation,
                    style: AppTheme.titleSmall.copyWith(fontSize: 13)),
                subtitle: Text(
                    'Stock: ${a.stockActuel} / Min: ${a.stockMinimum} ${a.uniteMesure ?? ''}'),
                trailing: ElevatedButton(
                  onPressed: () {
                    PdfService.generateArticleCatalog([a], a.type).then((b) =>
                        PdfService.downloadPdf(
                            b, 'ARTICLE_${a.reference}.pdf'));
                  },
                  child: const Text('PDF', style: TextStyle(fontSize: 11)),
                ),
              ),
            )),
      ],
      const SizedBox(height: 16),
      _actionCard(context, Icons.picture_as_pdf_outlined,
          'Exporter le catalogue articles', AppTheme.kPrimaryRed, () async {
        final bytes =
            await PdfService.generateArticleCatalog(provider.articles, 'TOUS');
        PdfService.downloadPdf(bytes, 'CATALOGUE_ARTICLES.pdf');
      }),
    ]);
  }
}

Widget _kpiBox(String label, String value, IconData icon, Color color) =>
    AppTheme.withGlass(
      radius: 12,
      blur: 12,
      opacity: 0.6,
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kTextPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: AppTheme.kTextSecondary)),
          ],
        ),
      ),
    );

Widget _actionCard(BuildContext context, IconData icon, String label,
        Color color, VoidCallback onTap) =>
    AppTheme.withGlass(
      radius: 12,
      blur: 12,
      opacity: 0.6,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: AppTheme.titleSmall.copyWith(fontSize: 13)),
        trailing: Icon(Icons.chevron_right, color: AppTheme.kTextHint),
        onTap: onTap,
      ),
    );
