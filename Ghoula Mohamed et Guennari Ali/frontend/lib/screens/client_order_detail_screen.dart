import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/client_order_provider.dart';
import '../constants/app_theme.dart';
import '../models/sales_order.dart';
import '../widgets/client_scaffold.dart';
import '../widgets/professional_dialogs.dart';

class ClientOrderDetailScreen extends StatefulWidget {
  const ClientOrderDetailScreen({super.key});

  @override
  State<ClientOrderDetailScreen> createState() => _ClientOrderDetailScreenState();
}

class _ClientOrderDetailScreenState extends State<ClientOrderDetailScreen> {
  SalesOrder? _order;
  bool _loading = true;

  static const _statusSteps = [
    'EN_ATTENTE',
    'CONFIRMEE',
    'EN_PREPARATION',
    'PARTIELLEMENT_LIVREE',
    'COMPLETEMENT_LIVREE',
  ];

  static const Map<String, Color> _stepColors = {
    'EN_ATTENTE': Color(0xFFFFA726),
    'CONFIRMEE': Color(0xFF3B82F6),
    'EN_PREPARATION': Color(0xFFFFC107),
    'PARTIELLEMENT_LIVREE': Color(0xFF8B5CF6),
    'COMPLETEMENT_LIVREE': Color(0xFF10B981),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrder());
  }

  Future<void> _loadOrder() async {
    final provider = context.read<ClientOrderProvider>();
    final id = int.tryParse(
        GoRouterState.of(context).pathParameters['id'] ?? '');

    if (id == null) {
      setState(() => _loading = false);
      return;
    }

    _order = provider.orders.cast<SalesOrder?>().firstWhere(
          (o) => o?.id == id,
          orElse: () => null,
        );

    if (_order == null) {
      await provider.load();
      _order = provider.orders.cast<SalesOrder?>().firstWhere(
            (o) => o?.id == id,
            orElse: () => null,
          );
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientOrderProvider>();

    if (_loading || provider.isLoading) {
      return ClientScaffold(
        currentRoute: '/mes-commandes',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return ClientScaffold(
        currentRoute: '/mes-commandes',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.kBorderLight),
              const SizedBox(height: 16),
              Text('Commande introuvable',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.kTextSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/mes-commandes'),
                style: AppTheme.primaryButton,
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final fmt = NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);
    final currentStepIdx = _statusSteps.indexOf(order.statut);

    return ClientScaffold(
      currentRoute: '/mes-commandes',
      body: AppTheme.glassBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatusTimeline(
              steps: _statusSteps,
              currentStepIdx: currentStepIdx,
              stepColors: _stepColors,
            ),
            const SizedBox(height: 20),
            _infoCard([
              _infoRow(label: 'Référence', value: order.reference ?? '—'),
              _infoRow(label: 'Date commande', value: order.dateCommande),
              if (order.notes != null && order.notes!.isNotEmpty)
                _infoRow(label: 'Notes', value: order.notes!),
            ]),
            const SizedBox(height: 20),
            Text('Lignes de commande',
                style: AppTheme.titleSmall.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            ...order.lignes.map((l) => _LigneCard(ligne: l, fmt: fmt)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecorationMd,
              child: Column(
                children: [
                  _totalRow(label: 'Total HT', value: fmt.format(order.totalHT)),
                  _totalRow(label: 'TVA (19%)', value: fmt.format(order.totalTVA)),
                  const Divider(color: AppTheme.kBorderLight),
                  _totalRow(
                    label: 'Total TTC',
                    value: fmt.format(order.totalTTC),
                    bold: true,
                    color: AppTheme.kSuccessGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (order.statut == 'EN_ATTENTE')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmCancel(context),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Annuler la commande'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kErrorRed,
                      foregroundColor: AppTheme.kWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/catalogue/commander'),
                icon: const Icon(Icons.replay_outlined, size: 18),
                label: const Text('Re-commander'),
                style: AppTheme.ctaButton,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Annuler la commande ?',
      message: 'Êtes-vous sûr de vouloir annuler la commande ${_order?.reference ?? ''} ?',
      confirmLabel: 'Annuler',
      icon: Icons.cancel_outlined,
      accentColor: AppTheme.kErrorRed,
    );

    if (confirmed == true && _order?.id != null) {
      final err = await context.read<ClientOrderProvider>().cancelOrder(_order!.id!);
      if (mounted) {
        if (err == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande annulée'),
              backgroundColor: AppTheme.kSuccessGreen,
            ),
          );
          await _loadOrder();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppTheme.kErrorRed),
          );
        }
      }
    }
  }
}

class _StatusTimeline extends StatelessWidget {
  final List<String> steps;
  final int currentStepIdx;
  final Map<String, Color> stepColors;

  const _StatusTimeline({
    required this.steps,
    required this.currentStepIdx,
    required this.stepColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: AppTheme.cardDecorationMd,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) return _buildConnector(context, i ~/ 2);
          final idx = i ~/ 2;
          return _buildStep(context, idx);
        }),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int idx) {
    final statut = steps[idx];
    final isActive = idx <= currentStepIdx;
    final color = isActive ? (stepColors[statut] ?? AppTheme.kSuccessGreen) : AppTheme.kBorderLight;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isActive ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _stepLabel(statut),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppTheme.kTextPrimary : AppTheme.kTextHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(BuildContext context, int idx) {
    final isActive = idx < currentStepIdx;
    return Container(
      height: 2,
      width: 16,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.kSuccessGreen : AppTheme.kBorderLight,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  String _stepLabel(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return 'Attente';
      case 'CONFIRMEE': return 'Confirmée';
      case 'EN_PREPARATION': return 'Préparation';
      case 'PARTIELLEMENT_LIVREE': return 'Partielle';
      case 'COMPLETEMENT_LIVREE': return 'Livrée';
      default: return statut;
    }
  }
}

Widget _infoCard(List<Widget> children) => Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecorationMd,
      child: Column(children: children),
    );

Widget _infoRow({required String label, required String value}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );

class _LigneCard extends StatelessWidget {
  final SalesOrderLine ligne;
  final NumberFormat fmt;
  const _LigneCard({required this.ligne, required this.fmt});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.kSurfaceWhite,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ligne.article?.designation ?? '—',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ligne.quantiteCommandee} ${ligne.article?.uniteMesure ?? ''} × ${fmt.format(ligne.prixUnitaireHT)}',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary),
                ),
                Text(
                  fmt.format(ligne.montantTTC ?? ligne.montantTTCCalc),
                  style: AppTheme.titleSmall.copyWith(color: AppTheme.kSuccessGreen),
                ),
              ],
            ),
            if (ligne.quantiteLivree > 0)
              Text('Livré : ${ligne.quantiteLivree}',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.kSuccessGreen)),
          ],
        ),
      );
}

Widget _totalRow({
  required String label,
  required String value,
  bool bold = false,
  Color? color,
}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 13,
                color: color ?? AppTheme.kTextPrimary,
              )),
        ],
      ),
    );
