import 'package:flutter/material.dart';
import '../models/sales_order.dart';
import '../services/client_order_service.dart';

class ClientOrderProvider extends ChangeNotifier {
  final ClientOrderService clientOrderService;

  ClientOrderProvider({required this.clientOrderService});

  List<SalesOrder> _orders = [];
  bool _isLoading = false;
  String? _error;
  bool _isSubmitting = false;

  List<SalesOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSubmitting => _isSubmitting;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await clientOrderService.fetchMyOrders();
    } catch (e) {
      _error = 'Impossible de charger vos commandes';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createOrder(Map<String, dynamic> data) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await clientOrderService.createOrder(data);
      await load();
      return null;
    } catch (e) {
      return 'Erreur lors de la création de la commande';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> cancelOrder(int id) async {
    try {
      await clientOrderService.cancelOrder(id);
      await load();
      return null;
    } catch (e) {
      return 'Impossible d\'annuler la commande';
    }
  }
}
