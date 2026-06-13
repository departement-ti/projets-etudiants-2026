import '../../core/api/api_client.dart';

class InvoiceService {
  // --------------------------------------------------
  // ADMIN / OWNER / AGENT invoices
  // --------------------------------------------------
  static Future<List<dynamic>> getAll() async {
    final res = await ApiClient.get('/invoices');

    if (res is List) return res;
    throw Exception('Expected list of invoices');
  }

  static Future<List<dynamic>> getInvoices() async {
    return getAll();
  }

  // --------------------------------------------------
  // TENANT invoices
  // --------------------------------------------------
  static Future<List<dynamic>> getMine() async {
    final res = await ApiClient.get('/invoices/me');

    if (res is List) return res;
    throw Exception('Expected list of tenant invoices');
  }

  static Future<List<dynamic>> getMyInvoices() async {
    return getMine();
  }

  // --------------------------------------------------
  // SINGLE invoice
  // --------------------------------------------------
  static Future<Map<String, dynamic>> getOne(String invoiceId) async {
    final res = await ApiClient.get('/invoices/$invoiceId');

    if (res is Map<String, dynamic>) return res;
    throw Exception('Expected invoice object');
  }

  static Future<Map<String, dynamic>> getInvoice(String invoiceId) async {
    return getOne(invoiceId);
  }

  // --------------------------------------------------
  // CREATE invoice manually
  // --------------------------------------------------
  static Future<void> create({
    required String leaseId,
    required double amount,
    required String dueDate,
  }) async {
    await ApiClient.post('/invoices', {
      'leaseId': leaseId,
      'amount': amount,
      'dueDate': dueDate,
    });
  }

  static Future<void> createInvoice({
    required String leaseId,
    required double amount,
    required String dueDate,
  }) async {
    return create(leaseId: leaseId, amount: amount, dueDate: dueDate);
  }
}
