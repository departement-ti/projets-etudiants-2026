import '../models/suggestion.dart';
import '../models/dashboard_kpi.dart';
import '../models/article.dart';
import '../models/sales_order.dart';
import '../models/purchase_order.dart';
import '../models/production_order.dart';
import 'suggestion_service.dart';

class AiSuggestionService {
  AiSuggestionService._();

  static const String apiEndpoint = '/api/suggestions/ai';

  static Future<List<Suggestion>> fetchSuggestions({
    required DashboardKpi kpis,
    required List<Article> articles,
    required List<SalesOrder> salesOrders,
    required List<PurchaseOrder> purchaseOrders,
    required List<ProductionOrder> productionOrders,
  }) async {
    // Future backend endpoint:
    // POST /api/suggestions/ai
    // Body: {
    //   "kpi": { "ventes": {...}, "achats": {...}, "production": {...}, "stock": {...} },
    //   "articles": [...],
    //   "salesOrders": [...],
    //   "purchaseOrders": [...],
    //   "productionOrders": [...]
    // }
    // Response: { "suggestions": [{ "id": 1, "type": "warning", "title": "...", "description": "...", "impact": "...", "priority": 1, "module": "stock" }] }

    // For now, fall back to rules-based engine
    return SuggestionService.generate(
      kpis: kpis,
      articles: articles,
      salesOrders: salesOrders,
      purchaseOrders: purchaseOrders,
      productionOrders: productionOrders,
    );
  }
}
