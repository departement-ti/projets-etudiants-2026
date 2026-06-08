import 'package:flutter/material.dart';
import '../models/purchase_order.dart';
import '../models/fournisseur.dart';
import '../services/purchase_order_service.dart';
import '../services/fournisseur_service.dart';

class AchatsProvider extends ChangeNotifier {
  final PurchaseOrderService purchaseOrderService;
  final FournisseurService fournisseurService;

  AchatsProvider({
    required this.purchaseOrderService,
    required this.fournisseurService,
  });

  List<PurchaseOrder> _orders = [];
  List<Fournisseur> _fournisseurs = [];
  bool _isLoading = false;
  String? _error;

  List<PurchaseOrder> get orders => _orders;
  List<Fournisseur> get fournisseurs => _fournisseurs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        purchaseOrderService.fetchAll(),
        fournisseurService.fetchAll(),
      ]);
      _orders = results[0] as List<PurchaseOrder>;
      _fournisseurs = results[1] as List<Fournisseur>;
    } catch (_) {
      _error = 'Impossible de charger les commandes achats.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createOrder(PurchaseOrder order) async {
    try {
      final created = await purchaseOrderService.create(order);
      _orders.insert(0, created);
      notifyListeners();
      return null;
    } catch (_) {
      return 'Erreur lors de la création de la commande';
    }
  }

  Future<String?> receive(int orderId, List<PurchaseOrderLine> lignes) async {
    try {
      final payload = {
        'dateReception': DateTime.now().toIso8601String().substring(0, 10),
        'lignes': lignes.map((l) => {
          'purchaseOrderLine': {'id': l.id},
          'article': {'id': l.article!.id},
          'quantiteRecue': l.quantiteCommandee,
        }).toList(),
      };
      await purchaseOrderService.receive(orderId, payload);
      await load();
      return null;
    } catch (_) {
      return 'Erreur lors de la réception';
    }
  }
}
