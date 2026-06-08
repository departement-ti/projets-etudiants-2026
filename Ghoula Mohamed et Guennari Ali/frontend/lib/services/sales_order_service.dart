import 'api_client.dart';
import '../models/sales_order.dart';

abstract class SalesOrderService {
  Future<List<SalesOrder>> fetchAll();
  Future<SalesOrder> create(SalesOrder order);
  Future<void> deliver(int orderId, Map<String, dynamic> bonLivraison);
  Future<void> approve(int orderId);
  Future<void> reject(int orderId);
  Future<List<SalesOrder>> fetchPending();
}

class RealSalesOrderService implements SalesOrderService {
  @override
  Future<List<SalesOrder>> fetchAll() async {
    final res = await ApiClient.instance.get('/sales-orders');
    return (res.data as List).map((e) => SalesOrder.fromJson(e)).toList();
  }

  @override
  Future<SalesOrder> create(SalesOrder order) async {
    final res = await ApiClient.instance.post('/sales-orders', data: order.toJson());
    return SalesOrder.fromJson(res.data);
  }

  @override
  Future<void> deliver(int orderId, Map<String, dynamic> bonLivraison) async {
    await ApiClient.instance.post('/sales-orders/$orderId/deliver', data: bonLivraison);
  }

  @override
  Future<void> approve(int orderId) async {
    await ApiClient.instance.put('/sales-orders/$orderId/approve');
  }

  @override
  Future<void> reject(int orderId) async {
    await ApiClient.instance.put('/sales-orders/$orderId/reject');
  }

  @override
  Future<List<SalesOrder>> fetchPending() async {
    final res = await ApiClient.instance.get('/sales-orders/pending');
    return (res.data as List).map((e) => SalesOrder.fromJson(e)).toList();
  }
}
