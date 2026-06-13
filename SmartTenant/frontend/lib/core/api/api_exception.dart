import 'dart:convert';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;

  static ApiException fromResponse({
    required int statusCode,
    required String body,
  }) {
    final cleanBody = body.trim();

    if (cleanBody.isEmpty) {
      return ApiException(
        friendlyStatusMessage(statusCode),
        statusCode: statusCode,
      );
    }

    try {
      final decoded = jsonDecode(cleanBody);

      if (decoded is Map) {
        final rawMessage = decoded['message'];
        final error = decoded['error'];

        String message;

        if (rawMessage is List) {
          message = rawMessage.map((item) => item.toString()).join('\n');
        } else if (rawMessage != null) {
          message = rawMessage.toString();
        } else if (error != null) {
          message = error.toString();
        } else {
          message = friendlyStatusMessage(statusCode);
        }

        return ApiException(message, statusCode: statusCode, details: decoded);
      }

      if (decoded is List) {
        return ApiException(
          decoded.map((item) => item.toString()).join('\n'),
          statusCode: statusCode,
          details: decoded,
        );
      }
    } catch (_) {
      // Body is not JSON.
    }

    return ApiException(cleanBody, statusCode: statusCode);
  }

  static String friendlyStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check the information and try again.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested item was not found.';
      case 409:
        return 'This action conflicts with existing data.';
      case 422:
        return 'Some information is invalid. Please review and try again.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
