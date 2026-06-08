import '../models/dashboard_kpi.dart';
import '../models/article.dart';
import '../models/sales_order.dart';
import '../models/purchase_order.dart';
import '../models/production_order.dart';
import '../models/suggestion.dart';

class SuggestionService {
  static Future<List<Suggestion>> generate({
    required DashboardKpi kpis,
    required List<Article> articles,
    required List<SalesOrder> salesOrders,
    required List<PurchaseOrder> purchaseOrders,
    required List<ProductionOrder> productionOrders,
  }) async {
    final suggestions = <Suggestion>[];
    int id = 1;

    final alertCount = kpis.stock.articlesEnAlerte;
    if (alertCount > 0) {
      suggestions.add(Suggestion(
        id: id++,
        type: 'alert',
        title: 'Articles en alerte de stock',
        description:
            '$alertCount articles ont un stock critique. Prévoyez un réapprovisionnement.',
        impact: 'Risque de rupture client',
        read: false,
      ));
    }

    final ofEnRetard = productionOrders
        .where((o) =>
            o.statut == 'PLANIFIE' || o.statut == 'LANCE')
        .toList();
    if (ofEnRetard.isNotEmpty) {
      suggestions.add(Suggestion(
        id: id++,
        type: 'info',
        title: 'Ordres de fabrication en attente',
        description:
            '${ofEnRetard.length} OF sont en cours de production.',
        impact: 'Planification nécessaire',
        read: false,
      ));
    }

    final commandesEnPreparation = salesOrders
        .where((o) => o.statut == 'CONFIRMEE')
        .toList();
    if (commandesEnPreparation.isNotEmpty) {
      suggestions.add(Suggestion(
        id: id++,
        type: 'action',
        title: 'Commandes à préparer',
        description:
            '${commandesEnPreparation.length} commandes clients sont en attente de préparation.',
        impact: 'Livraison en retard',
        read: false,
      ));
    }

    return suggestions;
  }
}
