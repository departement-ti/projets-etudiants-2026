import 'api_client.dart';
import '../models/purchase_order.dart';

abstract class PurchaseOrderService {
  Future<List<PurchaseOrder>> fetchAll();
  Future<PurchaseOrder> create(PurchaseOrder order);
  Future<void> receive(int orderId, Map<String, dynamic> reception);
}

class RealPurchaseOrderService implements PurchaseOrderService {
  @override
  Future<List<PurchaseOrder>> fetchAll() async {
    final res = await ApiClient.instance.get('/purchase-orders');
    return (res.data as List).map((e) => PurchaseOrder.fromJson(e)).toList();
  }

  @override
  Future<PurchaseOrder> create(PurchaseOrder order) async {
    final res = await ApiClient.instance.post('/purchase-orders', data: order.toJson());
    return PurchaseOrder.fromJson(res.data);
  }

  @override
  Future<void> receive(int orderId, Map<String, dynamic> reception) async {
    await ApiClient.instance.post('/purchase-orders/$orderId/receive', data: reception);
  }
}
