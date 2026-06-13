import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/api/api_client.dart';

class ReportsService {
  static String _query({DateTime? startDate, DateTime? endDate}) {
    final params = <String>[];

    if (startDate != null) {
      params.add(
        'startDate=${Uri.encodeComponent(startDate.toIso8601String())}',
      );
    }

    if (endDate != null) {
      params.add('endDate=${Uri.encodeComponent(endDate.toIso8601String())}');
    }

    if (params.isEmpty) return '';

    return '?${params.join('&')}';
  }

  static Future<Map<String, dynamic>> financialReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await ApiClient.get(
      '/reports/financial${_query(startDate: startDate, endDate: endDate)}',
    );

    if (res is Map<String, dynamic>) {
      return res;
    }

    return {};
  }

  static Future<File> downloadFinancialPdf({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Uint8List bytes = await ApiClient.getBytes(
      '/reports/financial/pdf${_query(startDate: startDate, endDate: endDate)}',
    );

    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      '${dir.path}/smarttenant-financial-report-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  static Future<void> openFinancialPdf({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final file = await downloadFinancialPdf(
      startDate: startDate,
      endDate: endDate,
    );

    await OpenFilex.open(file.path);
  }
}
