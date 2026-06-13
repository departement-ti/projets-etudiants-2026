import '../../core/api/api_client.dart';

class PaymentService {
  // --------------------------------------------------
  // CREATE PAYMENT
  // --------------------------------------------------
  static Future<void> create({
    required String invoiceId,
    required double amount,
    String? method,
    String? provider,
    String? providerRef,
  }) async {
    await ApiClient.post('/payments', {
      'invoiceId': invoiceId,
      'amount': amount,
      if (method != null && method.trim().isNotEmpty) 'method': method.trim(),
      if (provider != null && provider.trim().isNotEmpty)
        'provider': provider.trim(),
      if (providerRef != null && providerRef.trim().isNotEmpty)
        'providerRef': providerRef.trim(),
    });
  }

  static Future<void> pay({
    required String invoiceId,
    required double amount,
    String? method,
    String? provider,
    String? providerRef,
  }) async {
    return create(
      invoiceId: invoiceId,
      amount: amount,
      method: method,
      provider: provider,
      providerRef: providerRef,
    );
  }

  // --------------------------------------------------
  // GET PAYMENTS BY INVOICE
  // --------------------------------------------------
  static Future<List<dynamic>> findByInvoice(String invoiceId) async {
    final res = await ApiClient.get('/payments/invoice/$invoiceId');

    if (res is List) return res;
    throw Exception('Expected list of payments');
  }

  static Future<List<dynamic>> getPayments(String invoiceId) async {
    return findByInvoice(invoiceId);
  }
}
