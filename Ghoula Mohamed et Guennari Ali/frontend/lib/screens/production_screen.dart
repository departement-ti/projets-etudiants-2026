import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/production_provider.dart';
import '../models/production_order.dart';
import '../widgets/app_drawer.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/professional_dialogs.dart';
import '../constants/app_theme.dart';
import 'production_detail_screen.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  String _filterStatut = 'TOUS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionProvider>().load();
    });
  }

  static const _filters = [
    ('TOUS', 'Tous'),
    ('PLANIFIE', 'Planifiés'),
    ('LANCE', 'Lancés'),
    ('TERMINE', 'Terminés'),
  ];

  List<ProductionOrder> _filtered(List<ProductionOrder> orders) {
    if (_filterStatut == 'TOUS') return orders;
    return orders.where((o) => o.statut == _filterStatut).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final filtered = _filtered(provider.orders);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(BrandAppBar.heightFor(context)),
        child: BrandAppBar(
          title: 'Production',
          subtitle: !provider.isLoading
              ? '${provider.ofPlanifies} planifié(s) · ${provider.ofEnCours} en cours'
              : null,
          currentRoute: '/production',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => context.read<ProductionProvider>().load(),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/production'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const Placeholder())),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel OF'),
      ),
      body: AppTheme.glassBackground(
        child: Column(
          children: [
            AppTheme.gradientBar(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final selected = _filterStatut == f.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f.$2),
                          selected: selected,
                          onSelected: (_) => setState(() => _filterStatut = f.$1),
                          selectedColor: AppTheme.kPrimaryBurgundyLight,
                          checkmarkColor: AppTheme.kPrimaryBurgundy,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppTheme.kPrimaryBurgundy
                                : AppTheme.kTextSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(provider, filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProductionProvider provider, List<ProductionOrder> filtered) {
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
              onPressed: () => context.read<ProductionProvider>().load(),
              style: AppTheme.primaryButton,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.precision_manufacturing_outlined,
                size: 64, color: AppTheme.kBorderLight),
            const SizedBox(height: 16),
            Text('Aucun ordre de fabrication',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ProductionProvider>().load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (ctx, i) => _OFCard(order: filtered[i]),
      ),
    );
  }
}

class _OFCard extends StatelessWidget {
  final ProductionOrder order;
  const _OFCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = Color(order.statutColor);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductionDetailScreen(order: order))),
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
                  const Icon(Icons.factory_outlined,
                      size: 14, color: AppTheme.kTextSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(order.produitFini?.designation ?? '—',
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
                      Text(order.datePlanifiee,
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.kTextSecondary)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${order.quantitePlanifiee.toStringAsFixed(0)} ${order.produitFini?.uniteMesure ?? ''}',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      if (order.quantiteRealisee > 0)
                        Text(' / réalisé: ${order.quantiteRealisee.toStringAsFixed(0)}',
                            style: AppTheme.bodySmall
                                .copyWith(color: AppTheme.kTextSecondary)),
                    ],
                  ),
                ],
              ),
              if (order.statut == 'LANCE' || order.statut == 'EN_COURS') ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: order.quantitePlanifiee > 0
                      ? (order.quantiteRealisee / order.quantitePlanifiee).clamp(0.0, 1.0)
                      : 0,
                  backgroundColor: AppTheme.kBorderLight,
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              if (order.peutLancer || order.peutTerminer) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.peutLancer)
                      _ActionBtn(
                        label: 'Lancer',
                        icon: Icons.play_arrow_rounded,
                        color: AppTheme.kSecondaryTan,
                        onTap: () => _launch(context, order),
                      ),
                    if (order.peutTerminer)
                      _ActionBtn(
                        label: 'Terminer',
                        icon: Icons.check_circle_outline,
                        color: AppTheme.kSuccessGreen,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => ProductionDetailScreen(order: order))),
                      ),
                  ],
                ),
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

  void _launch(BuildContext context, ProductionOrder order) {
    AppDialogs.showConfirm(
      context: context,
      title: "Lancer l'OF ?",
      message: 'Lancer ${order.reference} ?\n\nLes matières premières seront consommées du stock.',
      confirmLabel: 'Lancer',
      icon: Icons.play_arrow_rounded,
      accentColor: AppTheme.kSecondaryTan,
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<ProductionProvider>().launch(order.id!).then((err) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(err ?? 'OF lancé — matières premières consommées'),
              backgroundColor: err == null ? AppTheme.kSuccessGreen : AppTheme.kErrorRed,
            ));
          }
        });
      }
    });
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
        ),
      );
}
