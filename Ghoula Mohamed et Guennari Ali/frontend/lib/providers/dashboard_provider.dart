import 'package:flutter/material.dart';
import '../models/dashboard_kpi.dart';
import '../models/suggestion.dart';
import '../models/article.dart';
import '../models/sales_order.dart';
import '../models/purchase_order.dart';
import '../models/production_order.dart';
import '../services/dashboard_service.dart';
import '../services/suggestion_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService dashboardService;

  DashboardProvider({required this.dashboardService});

  DashboardKpi? _kpi;
  List<Suggestion> _suggestions = [];
  bool _isLoading = false;
  bool _suggestionsLoading = false;
  String? _error;

  DashboardKpi? get kpi => _kpi;
  List<Suggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  bool get suggestionsLoading => _suggestionsLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _kpi = await dashboardService.fetchKpis();
    } catch (_) {
      _error = 'Impossible de charger les données. Vérifiez la connexion.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSuggestions({
    required List<Article> articles,
    required List<SalesOrder> salesOrders,
    required List<PurchaseOrder> purchaseOrders,
    required List<ProductionOrder> productionOrders,
  }) async {
    if (_kpi == null) return;
    _suggestionsLoading = true;
    notifyListeners();
    try {
      _suggestions = await SuggestionService.generate(
        kpis: _kpi!,
        articles: articles,
        salesOrders: salesOrders,
        purchaseOrders: purchaseOrders,
        productionOrders: productionOrders,
      );
    } catch (_) {
      _suggestions = [];
    } finally {
      _suggestionsLoading = false;
      notifyListeners();
    }
  }

  void markSuggestionRead(int id) {
    final idx = _suggestions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _suggestions[idx] = _suggestions[idx].copyWith(read: true);
      notifyListeners();
    }
  }
}
