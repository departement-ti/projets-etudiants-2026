import 'dart:convert';

import 'package:flutter/material.dart';

class AppError {
  static const Color softBg = Color(0xFFF8F5FF);

  static String clean(Object error) {
    var message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.startsWith('API Error')) {
      final jsonStart = message.indexOf('{');

      if (jsonStart != -1) {
        final jsonText = message.substring(jsonStart);

        try {
          final decoded = jsonDecode(jsonText);

          if (decoded is Map && decoded['message'] != null) {
            final value = decoded['message'];

            if (value is List) {
              return value.map((item) => item.toString()).join('\n');
            }

            return value.toString();
          }
        } catch (_) {
          return message;
        }
      }
    }

    if (message.startsWith('{')) {
      try {
        final decoded = jsonDecode(message);

        if (decoded is Map && decoded['message'] != null) {
          final value = decoded['message'];

          if (value is List) {
            return value.map((item) => item.toString()).join('\n');
          }

          return value.toString();
        }
      } catch (_) {
        return message;
      }
    }

    return message;
  }

  static Future<void> show(
    BuildContext context,
    Object error, {
    String title = 'Something went wrong',
    String? message,
    IconData icon = Icons.error_outline,
    Color color = Colors.red,
  }) async {
    final cleanMessage = message ?? clean(error);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 22),
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(icon, color: color, size: 34),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cleanMessage.isEmpty ? 'Please try again.' : cleanMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.45,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Got it'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void snack(BuildContext context, Object error, {String? message}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? clean(error))));
  }
}
