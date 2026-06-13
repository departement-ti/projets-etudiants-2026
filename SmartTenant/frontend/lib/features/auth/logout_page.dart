// lib/features/auth/logout_page.dart
/* Logout Page
   A page that allows users to log out of their account.
*/

import 'package:flutter/material.dart';
import '../../core/auth/auth_storage.dart';
import 'login_page.dart';

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await AuthStorage.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
