import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ventes_provider.dart';
import '../models/sales_order.dart';
import '../widgets/app_drawer.dart';
import '../widgets/brand_app_bar.dart';
import '../constants/app_theme.dart';
import 'sales_order_form_screen.dart';
import 'sales_order_detail_screen.dart';

class VentesScreen extends StatefulWidget {
  const VentesScreen({super.key});

  @override
  State<VentesScreen> createState() => _VentesScreenState();
}

class _VentesScreenState extends State<VentesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  SalesOrder? _selectedOrder;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VentesProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool get _isDesktop => MediaQuery.of(context).size.width > 900;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VentesProvider>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(BrandAppBar.heightFor(context) + 48),
        child: BrandAppBar(
          title: 'Commandes Ventes',
          subtitle: !provider.isLoading
              ? '${provider.orders.length} commande(s)'
              : null,
          currentRoute: '/ventes',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => context.read<VentesProvider>().load(),
            ),
          ],
          bottom: AppTheme.gradientBar(
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.kPrimaryRed,
              labelColor: AppTheme.kPrimaryRed,
              unselectedLabelColor: AppTheme.kTextSecondary,
              tabs: const [
                Tab(text: 'Toutes'),
                Tab(text: 'En attente'),
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/ventes'),
      floatingActionButton: _isDesktop && _selectedOrder != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SalesOrderFormScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle commande'),
            ),
      body: AppTheme.glassBackground(
        child: _isDesktop && _selectedOrder != null
            ? Row(
                children: [
                  SizedBox(
                    width: 380,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildAllOrders(provider),
                        _buildPendingOrders(provider),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    color: AppTheme.kBorderLight,
                  ),
                  Expanded(
                    child: SalesOrderDetailScreen(
                      order: _selectedOrder!,
                      isEmbedded: true,
                    ),
                  ),
                ],
              )
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildAllOrders(provider),
                  _buildPendingOrders(provider),
                ],
              ),
      ),
    );
  }

  Widget _buildAllOrders(VentesProvider provider) {
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
              onPressed: () => context.read<VentesProvider>().load(),
              style: AppTheme.primaryButton,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (provider.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppTheme.kBorderLight),
            const SizedBox(height: 16),
            Text('Aucune commande',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<VentesProvider>().load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.orders.length,
        itemBuilder: (ctx, i) => _OrderCard(
          order: provider.orders[i],
          isSelected: _selectedOrder?.id == provider.orders[i].id,
          onTap: _isDesktop
              ? () => setState(() => _selectedOrder = provider.orders[i])
              : () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SalesOrderDetailScreen(order: provider.orders[i]))),
        ),
      ),
    );
  }

  Widget _buildPendingOrders(VentesProvider provider) {
    final pending = provider.orders
        .where((o) => o.statut == 'EN_ATTENTE')
        .toList();

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: AppTheme.kSuccessGreen),
            const SizedBox(height: 16),
            Text('Aucune commande en attente',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<VentesProvider>().load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pending.length,
        itemBuilder: (ctx, i) => _PendingOrderCard(
          order: pending[i],
          onTap: _isDesktop
              ? null
              : () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SalesOrderDetailScreen(order: pending[i]))),
        ),
      ),
    );
  }
}

class _PendingOrderCard extends StatelessWidget {
  final SalesOrder order;
  final VoidCallback? onTap;
  const _PendingOrderCard({required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.reference ?? '—',
                      style: AppTheme.titleSmall.copyWith(fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('EN ATTENTE',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business_outlined,
                    size: 14, color: AppTheme.kTextSecondary),
                const SizedBox(width: 4),
                Text(order.client?.raisonSociale ?? '—',
                    style: AppTheme.bodySmall.copyWith(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppTheme.kTextSecondary),
                    const SizedBox(width: 4),
                    Text(order.dateCommande,
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.kTextSecondary)),
                  ],
                ),
                Text(fmt.format(order.totalTTC),
                    style: AppTheme.titleSmall.copyWith(
                        color: AppTheme.kSuccessGreen)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _reject(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.kErrorRed,
                    side: const BorderSide(color: AppTheme.kErrorRed),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _approve(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approuver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kSuccessGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final provider = context.read<VentesProvider>();
    final error = await provider.approve(order.id!);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.kErrorRed),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande approuvée'),
          backgroundColor: AppTheme.kSuccessGreen,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final provider = context.read<VentesProvider>();
    final error = await provider.reject(order.id!);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.kErrorRed),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande refusée'),
          backgroundColor: AppTheme.kSuccessGreen,
        ),
      );
    }
  }
}

class _OrderCard extends StatelessWidget {
  final SalesOrder order;
  final bool isSelected;
  final VoidCallback onTap;
  const _OrderCard({required this.order, this.isSelected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);
    final color = Color(order.statutColor);

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
                  border: Border.all(color: color, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(order.reference ?? '—',
                                  style: AppTheme.titleSmall.copyWith(fontSize: 15)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(order.statutLabel,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.business_outlined,
                                size: 14, color: AppTheme.kTextSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(order.client?.raisonSociale ?? '—',
                                  style: AppTheme.bodySmall.copyWith(fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 13, color: AppTheme.kTextSecondary),
                                const SizedBox(width: 4),
                                Text(order.dateCommande,
                                    style: AppTheme.bodySmall
                                        .copyWith(color: AppTheme.kTextSecondary)),
                              ],
                            ),
                            Text(fmt.format(order.totalTTC),
                                style: AppTheme.titleSmall.copyWith(
                                    color: AppTheme.kSuccessGreen)),
                          ],
                        ),
                        if (order.lignes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('${order.lignes.length} ligne(s)',
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.kTextSecondary)),
                        ],
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
