# Flutter SDK integration example

1. Add dependency: `smart_support_ai: ^1.0.0` (or path to package).
2. Wrap your app with Supabase + ProviderScope and init with your keys.
3. Use `SmartSupportChatWidget` with `companyId` for embedded chat.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_support_ai/smart_support_ai.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('My App with Support')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SmartSupportChatWidget(
              companyId: 'YOUR_COMPANY_UUID',
              userIdentifier: 'user@example.com',
              primaryColor: Color(0xFF6366F1),
              welcomeMessage: 'Hello! How can we help?',
            ),
          ),
        ),
      ),
    );
  }
}
```

Minimal inline: use a WebView or embed the same chat UI (ChatScreen) with a fixed companyId; or call your backend `POST /chat` with `{ company_id, user_identifier, message }` and display the bot response.
