import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/client_order_provider.dart';
import '../constants/app_theme.dart';
import '../models/sales_order.dart';
import '../widgets/client_scaffold.dart';

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientOrderProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientOrderProvider>();
    final orders = provider.orders.toList()
      ..sort((a, b) => b.dateCommande.compareTo(a.dateCommande));

    return ClientScaffold(
      currentRoute: '/mes-commandes',
      body: AppTheme.glassBackground(
        child: _buildBody(provider, orders),
      ),
    );
  }

  Widget _buildBody(ClientOrderProvider provider, List<SalesOrder> orders) {
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
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ClientOrderProvider>().load(),
              style: AppTheme.primaryButton,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.kBorderLight),
            const SizedBox(height: 16),
            Text('Aucune commande',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => context.go('/catalogue'),
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Commander'),
              style: AppTheme.ctaButton,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ClientOrderProvider>().load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (ctx, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final SalesOrder order;
  const _OrderCard({required this.order});

  Color _statusColor(String statut) {
    if (statut == 'EN_ATTENTE') return AppTheme.kWarningAmber;
    return Color(order.statutColor);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);
    final color = _statusColor(order.statut);

    return GestureDetector(
      onTap: () => context.go('/mes-commandes/${order.id}'),
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
                            child: Text(
                              order.statutLabel,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                              style: AppTheme.titleSmall.copyWith(color: AppTheme.kSuccessGreen)),
                        ],
                      ),
                      if (order.lignes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('${order.lignes.length} ligne(s)',
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
                      ],
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
}
