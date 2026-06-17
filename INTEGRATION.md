# Smart Support AI – Integration Guide

## 1. Web widget

Add this snippet before `</body>` on your website. Replace `YOUR_COMPANY_ID` with your company UUID from the dashboard.

```html
<script
  src="https://your-cdn.com/smart-support-widget.js"
  data-company-id="YOUR_COMPANY_ID"
  async
></script>
```

The widget will show a chat bubble and load your company’s chatbot (intents, welcome message, branding).

---

## 2. Flutter SDK component

In your Flutter app, add the dependency and embed the chat widget:

```yaml
dependencies:
  smart_support_ai: ^1.0.0
```

```dart
import 'package:smart_support_ai/smart_support_ai.dart';

// In your screen:
SmartSupportChatWidget(
  companyId: 'YOUR_COMPANY_ID',
  supabaseUrl: 'https://your-project.supabase.co',
  supabaseAnonKey: 'your-anon-key',
)
```

Or use the full SDK and pass your Supabase client for auth and multi-tenant use.

---

## 3. REST endpoint

For custom UIs (mobile, web, API clients), call the chat API:

**Endpoint:** `POST /v1/chat`

**Headers:**
- `Content-Type: application/json`
- `Authorization: Bearer <anon_or_user_jwt>` (if required)

**Body:**
```json
{
  "company_id": "uuid-of-your-company",
  "session_id": "optional-existing-session-uuid",
  "message": "user message text"
}
```

**Response:**
```json
{
  "reply": "bot response text",
  "session_id": "uuid",
  "handoff_required": false
}
```

Implement this via a Supabase Edge Function or your backend that reads `intents` and `unknown_questions` for the given `company_id` and returns the reply (and sets `handoff_required` after N failures).

---

## Multi-tenant and branding

- Each company has isolated data: intents, sessions, messages, unknown questions, ratings.
- Load company theme (e.g. `primary_color`) and apply it to the widget/UI.
- Human handoff: use company `support_email` and `support_whatsapp` when the bot triggers handoff.
