import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/dashboard_provider.dart';
import '../providers/article_provider.dart';
import '../providers/ventes_provider.dart';
import '../providers/achats_provider.dart';
import '../providers/production_provider.dart';
import '../models/dashboard_kpi.dart';
import '../models/suggestion.dart';
import '../constants/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/brand_app_bar.dart';
import '../mock/mock.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dash = context.read<DashboardProvider>();
      dash.load();
      context.read<ArticleProvider>().load();
      context.read<VentesProvider>().load();
      context.read<AchatsProvider>().load();
      context.read<ProductionProvider>().load();
    });
  }

  void _refreshAll() {
    final dash = context.read<DashboardProvider>();
    dash.load();
    context.read<ArticleProvider>().load().then((_) {
      dash.loadSuggestions(
        articles: context.read<ArticleProvider>().articles,
        salesOrders: context.read<VentesProvider>().orders,
        purchaseOrders: context.read<AchatsProvider>().orders,
        productionOrders: context.read<ProductionProvider>().orders,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final dateFmt = DateFormat('EEEE d MMMM yyyy', 'fr_FR');

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundWarm,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(BrandAppBar.heightFor(context)),
        child: BrandAppBar(
          title: 'Tableau de bord',
          subtitle: dateFmt.format(DateTime.now()),
          currentRoute: '/dashboard',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Actualiser',
              onPressed: _refreshAll,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: AppTheme.glassBackground(
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(DashboardProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_outlined,
                  size: 56, color: AppTheme.kTextHint),
              const SizedBox(height: 16),
              Text(provider.error!,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.kTextSecondary)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.read<DashboardProvider>().load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: AppTheme.primaryButton,
              ),
            ],
          ),
        ),
      );
    }
    final kpi = provider.kpi;
    if (kpi == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: () async { _refreshAll(); },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKpiRow(kpi),
            const SizedBox(height: 20),
            _buildChartsSection(kpi),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildActivityFeed(),
            const SizedBox(height: 20),
            _buildStockAlert(kpi),
            const SizedBox(height: 20),
            _buildSuggestions(provider),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(DashboardKpi kpi) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final count = 4;
        final gap = 12.0;
        final totalGap = gap * (count - 1);
        final cardWidth = (constraints.maxWidth - totalGap) / count;
        if (cardWidth < 140) {
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              SizedBox(
                width: (constraints.maxWidth - gap) / 2,
                child: _glassKpiCard(
                  title: "Chiffre d'affaires",
                  value: NumberFormat.currency(
                    locale: 'fr_TN',
                    symbol: 'TND',
                    decimalDigits: 1,
                  ).format(kpi.ventes.chiffreAffairesMois),
                  subtitle: '+${kpi.ventes.nbCommandesMois} commandes',
                  icon: Icons.trending_up_rounded,
                  accentColor: AppTheme.kPrimaryBurgundy,
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - gap) / 2,
                child: _glassKpiCard(
                  title: 'Commandes',
                  value: '${kpi.ventes.nbCommandesMois}',
                  subtitle: '${kpi.ventes.commandesEnCours} en cours',
                  icon: Icons.receipt_long_rounded,
                  accentColor: AppTheme.kSecondaryTan,
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - gap) / 2,
                child: _glassKpiCard(
                  title: 'OF en cours',
                  value: '${kpi.production.ofEnCours}',
                  subtitle: '${kpi.production.ofPlanifies} planifiés',
                  icon: Icons.precision_manufacturing_rounded,
                  accentColor: AppTheme.kPrimaryBurgundyLight,
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - gap) / 2,
                child: _glassKpiCard(
                  title: 'Alertes stock',
                  value: '${kpi.stock.articlesEnAlerte}',
                  subtitle: kpi.stock.articlesEnAlerte == 0
                      ? 'Aucune alerte'
                      : 'Articles sous seuil',
                  icon: kpi.stock.articlesEnAlerte == 0
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  accentColor: kpi.stock.articlesEnAlerte > 0
                      ? AppTheme.kErrorRed
                      : AppTheme.kSuccessGreen,
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _glassKpiCard(
                title: "Chiffre d'affaires",
                value: NumberFormat.currency(
                  locale: 'fr_TN',
                  symbol: 'TND',
                  decimalDigits: 1,
                ).format(kpi.ventes.chiffreAffairesMois),
                subtitle: '+${kpi.ventes.nbCommandesMois} commandes',
                icon: Icons.trending_up_rounded,
                accentColor: AppTheme.kPrimaryBurgundy,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _glassKpiCard(
                title: 'Commandes',
                value: '${kpi.ventes.nbCommandesMois}',
                subtitle: '${kpi.ventes.commandesEnCours} en cours',
                icon: Icons.receipt_long_rounded,
                accentColor: AppTheme.kSecondaryTan,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _glassKpiCard(
                title: 'OF en cours',
                value: '${kpi.production.ofEnCours}',
                subtitle: '${kpi.production.ofPlanifies} planifiés',
                icon: Icons.precision_manufacturing_rounded,
                accentColor: AppTheme.kPrimaryBurgundyLight,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _glassKpiCard(
                title: 'Alertes stock',
                value: '${kpi.stock.articlesEnAlerte}',
                subtitle: kpi.stock.articlesEnAlerte == 0
                    ? 'Aucune alerte'
                    : 'Articles sous seuil',
                icon: kpi.stock.articlesEnAlerte == 0
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                accentColor: kpi.stock.articlesEnAlerte > 0
                    ? AppTheme.kErrorRed
                    : AppTheme.kSuccessGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _glassKpiCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return AppTheme.withGlass(
      radius: 16,
      blur: 16,
      opacity: 0.7,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 3,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.kTextSecondary)),
                ),
                Icon(icon,
                    color: accentColor.withValues(alpha: 0.7), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: AppTheme.headlineSmall
                    .copyWith(color: AppTheme.kTextPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.kTextHint)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(DashboardKpi kpi) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Column(
          children: [
            isWide
                ? Row(
                    children: [
                      Expanded(child: _buildRevenueChart(kpi)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildOrdersChart(kpi)),
                    ],
                  )
                : Column(
                    children: [
                      _buildRevenueChart(kpi),
                      const SizedBox(height: 16),
                      _buildOrdersChart(kpi),
                    ],
                  ),
            const SizedBox(height: 16),
            isWide
                ? Row(
                    children: [
                      Expanded(child: _buildProductionChart(kpi)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStockChart(kpi)),
                    ],
                  )
                : Column(
                    children: [
                      _buildProductionChart(kpi),
                      const SizedBox(height: 16),
                      _buildStockChart(kpi),
                    ],
                  ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueChart(DashboardKpi kpi) {
    final mockData = MockConfig.useMock
        ? MockData.revenueByMonth()
        : List.filled(12, 0.0);
    return AppTheme.withGlass(
      radius: 16,
      blur: 16,
      opacity: 0.7,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimaryBurgundy,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text("Chiffre d'affaires", style: AppTheme.titleSmall),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimaryBurgundy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Annuel',
                      style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.kPrimaryBurgundy)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.kBorderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, _) {
                          final months = [
                            'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
                            'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
                          ];
                          final idx = v.toInt();
                          if (idx >= 0 && idx < months.length) {
                            return Text(months[idx],
                                style: AppTheme.bodySmall
                                    .copyWith(color: AppTheme.kTextHint));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                          mockData.length, (i) => FlSpot(i.toDouble(), mockData[i])),
                      isCurved: true,
                      color: AppTheme.kPrimaryBurgundy,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: AppTheme.kPrimaryBurgundy,
                          strokeWidth: 2,
                          strokeColor: AppTheme.kWhite,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.kPrimaryBurgundy.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersChart(DashboardKpi kpi) {
    final mockData = MockConfig.useMock
        ? MockData.ordersByDay()
        : List.filled(7, 0.0);
    return AppTheme.withGlass(
      radius: 16,
      blur: 16,
      opacity: 0.7,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.kSecondaryTan,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Commandes', style: AppTheme.titleSmall),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.kSecondaryTan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('7 jours',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.kSecondaryTan)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.kBorderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, _) {
                          final labels = [
                            'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
                          ];
                          final idx = v.toInt();
                          if (idx >= 0 && idx < labels.length) {
                            return Text(labels[idx],
                                style: AppTheme.bodySmall
                                    .copyWith(color: AppTheme.kTextHint));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    mockData.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: mockData[i],
                          color: AppTheme.kSecondaryTan,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionChart(DashboardKpi kpi) {
    final total = kpi.production.ofEnCours + kpi.production.ofPlanifies;
    final pct = total > 0 ? kpi.production.ofEnCours / total : 0.0;

    return AppTheme.withGlass(
      radius: 16,
      blur: 16,
      opacity: 0.7,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimaryBurgundyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Production', style: AppTheme.titleSmall),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimaryBurgundyLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${total} OF',
                      style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.kPrimaryBurgundyLight)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                height: 160,
                width: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            value: kpi.production.ofEnCours.toDouble(),
                            color: AppTheme.kPrimaryBurgundy,
                            radius: 40,
                            title: '',
                          ),
                          PieChartSectionData(
                            value: kpi.production.ofPlanifies.toDouble(),
                            color: AppTheme.kBorderLight,
                            radius: 40,
                            title: '',
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${(pct * 100).toInt()}%',
                            style: AppTheme.headlineSmall
                                .copyWith(color: AppTheme.kPrimaryBurgundy)),
                        Text('En cours',
                            style: AppTheme.bodySmall
                                .copyWith(color: AppTheme.kTextSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppTheme.kPrimaryBurgundy, 'En cours'),
                const SizedBox(width: 16),
                _legendDot(AppTheme.kBorderLight, 'Planifiés'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockChart(DashboardKpi kpi) {
    final details = kpi.stock.articlesEnAlerteDetails;
    final normalCount = details.isEmpty ? 10 : 10 - details.length;

    return AppTheme.withGlass(
      radius: 16,
      blur: 16,
      opacity: 0.7,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: kpi.stock.articlesEnAlerte > 0
                        ? AppTheme.kErrorRed
                        : AppTheme.kSuccessGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Stock', style: AppTheme.titleSmall),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kpi.stock.articlesEnAlerte > 0
                        ? AppTheme.kErrorRedLight
                        : AppTheme.kSuccessGreenLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${kpi.stock.articlesEnAlerte} alerte(s)',
                    style: AppTheme.bodySmall.copyWith(
                      color: kpi.stock.articlesEnAlerte > 0
                          ? AppTheme.kErrorRed
                          : AppTheme.kSuccessGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                height: 160,
                width: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 45,
                    sections: [
                      PieChartSectionData(
                        value: normalCount.toDouble(),
                        color: AppTheme.kSuccessGreen,
                        radius: 40,
                        title: '$normalCount',
                        titleStyle: const TextStyle(
                            color: AppTheme.kWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      PieChartSectionData(
                        value: kpi.stock.articlesEnAlerte.toDouble(),
                        color: AppTheme.kErrorRed,
                        radius: 40,
                        title: '${kpi.stock.articlesEnAlerte}',
                        titleStyle: const TextStyle(
                            color: AppTheme.kWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppTheme.kSuccessGreen, 'Normal'),
                const SizedBox(width: 16),
                _legendDot(AppTheme.kErrorRed, 'Alerte'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Actions rapides',
              style: AppTheme.titleSmall.copyWith(fontSize: 15)),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _actionChip(Icons.add_shopping_cart_rounded, 'Nouvelle vente'),
            _actionChip(Icons.add_box_rounded, 'Nouvel achat'),
            _actionChip(
                Icons.precision_manufacturing_rounded, 'Planifier OF'),
            _actionChip(Icons.inventory_2_rounded, 'Ajuster stock'),
          ],
        ),
      ],
    );
  }

  Widget _actionChip(IconData icon, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: AppTheme.withGlass(
          radius: 12,
          blur: 12,
          opacity: 0.65,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16, color: AppTheme.kPrimaryBurgundy),
                const SizedBox(width: 8),
                Text(label,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.kTextPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityFeed() {
    final activities = MockConfig.useMock
        ? MockData.recentActivity
        : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Activité récente',
              style: AppTheme.titleSmall.copyWith(fontSize: 15)),
        ),
        AppTheme.withGlass(
          radius: 16,
          blur: 16,
          opacity: 0.7,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: activities.map<Widget>((item) {
                final color = Color(item['color'] as int);
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item['icon'] as IconData,
                        color: color, size: 18),
                  ),
                  title: Text(item['text'] as String,
                      style: AppTheme.bodyMedium
                          .copyWith(fontSize: 13)),
                  trailing: Text(item['time'] as String,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.kTextHint)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockAlert(DashboardKpi kpi) {
    final details = kpi.stock.articlesEnAlerteDetails;
    if (details.isEmpty) return const SizedBox.shrink();

    return AppTheme.withGlass(
      radius: 16,
      blur: 16,
      opacity: 0.7,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.kErrorRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Alertes Stock',
                    style: AppTheme.titleSmall.copyWith(fontSize: 15)),
                const Spacer(),
                Text('${details.length} article(s)',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.kTextSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            ...details.map<Widget>((item) {
              final m = item as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.kErrorRedLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppTheme.kErrorRed, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['designation'] ??
                                  m['reference'] ??
                                  'Article',
                              style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.kErrorRed),
                            ),
                            Text(
                              'Stock: ${m['quantiteEnStock'] ?? 0}',
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.kErrorRed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(DashboardProvider provider) {
    return AppTheme.withGlass(
      radius: 16,
      blur: 16,
      opacity: 0.7,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimaryRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Suggestions IA', style: AppTheme.titleSmall),
                const Spacer(),
                if (provider.suggestionsLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.suggestions.isEmpty && !provider.suggestionsLoading)
              _buildSuggestionsPrompt()
            else ...[
              ...provider.suggestions.map((s) => _suggestionCard(s, provider)),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _refreshAll,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Actualiser les suggestions'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.kPrimaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.kPrimaryRed, size: 24),
            ),
            const SizedBox(height: 12),
            Text('Obtenez des suggestions basées sur vos KPIs',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 4),
            Text(
              'Analyse des ventes, achats, production et stock',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextHint),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshAll,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Générer des suggestions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kPrimaryRed,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionCard(Suggestion s, DashboardProvider provider) {
    final color = switch (s.type) {
      'warning' => AppTheme.kErrorRed,
      'success' => AppTheme.kSuccessGreen,
      _ => AppTheme.kPrimaryRed,
    };
    final icon = switch (s.type) {
      'warning' => Icons.warning_amber_rounded,
      'success' => Icons.check_circle_rounded,
      _ => Icons.lightbulb_outline_rounded,
    };
    return AppTheme.withGlass(
      radius: 12,
      blur: 12,
      opacity: 0.65,
      margin: const EdgeInsets.only(bottom: 8),
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
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (s.description.isNotEmpty)
                            Text(s.description,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary, fontSize: 11)),
                          if (s.impact.isNotEmpty)
                            Text('Impact: ${s.impact}',
                                style: AppTheme.bodySmall.copyWith(color: color, fontSize: 10)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: AppTheme.kTextHint, size: 18),
                      onSelected: (val) {
                        if (val == 'dismiss') provider.markSuggestionRead(s.id);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'dismiss', child: Row(
                          children: [Icon(Icons.close, size: 18), SizedBox(width: 8), Text('Ignorer')],
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
