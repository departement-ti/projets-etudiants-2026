import 'api_client.dart';
import '../models/sales_order.dart';

abstract class ClientOrderService {
  Future<List<SalesOrder>> fetchMyOrders();
  Future<SalesOrder> createOrder(Map<String, dynamic> data);
  Future<void> cancelOrder(int id);
}

class RealClientOrderService implements ClientOrderService {
  @override
  Future<List<SalesOrder>> fetchMyOrders() async {
    final res = await ApiClient.instance.get('/sales-orders/client/mine');
    return (res.data as List).map((e) => SalesOrder.fromJson(e)).toList();
  }

  @override
  Future<SalesOrder> createOrder(Map<String, dynamic> data) async {
    final res = await ApiClient.instance.post('/sales-orders/client', data: data);
    return SalesOrder.fromJson(res.data);
  }

  @override
  Future<void> cancelOrder(int id) async {
    await ApiClient.instance.put('/sales-orders/client/$id/cancel');
  }
}
