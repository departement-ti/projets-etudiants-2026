# Smart Support AI

SaaS intelligent customer support chatbot platform with **Flutter** frontend and **Supabase** backend. Multi-tenant: each company has its own chatbot, data, users, and branding.

## Tech stack

- **Frontend:** Flutter (clean architecture), Riverpod, Material 3, go_router
- **Backend:** Supabase (PostgreSQL, Auth, RLS)
- **AI:** Intent detection, keyword/phrase matching, unknown-question learning, human handoff after N failures

## Project structure

```
lib/
  core/           # Theme, router, constants
  models/         # Company, User, Session, Message, Intent, etc.
  services/       # Supabase, Auth, ChatLogic, ChatApi, Intent, Analytics
  features/
    splash/
    auth/         # Login, Register, Company setup
    chat/         # Chat UI + providers (intent detection, handoff)
    admin/        # Dashboard, Intent management, Unknown questions
    analytics/    # Stats dashboard
    settings/     # Branding, handoff, integration code
```

## Setup

### 1. Clone and install

```bash
cd smart_support_ai
flutter pub get
```

### 2. Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. In **SQL Editor**, run the migration:
   - `supabase/migrations/001_initial_schema.sql`
3. Copy **Project URL** and **anon public** key.

### 3. Configure Flutter

Set your Supabase credentials when running:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Or in `lib/main.dart` replace the `defaultValue` for `SUPABASE_URL` and `SUPABASE_ANON_KEY` (do not commit real keys).

### 4. Run

```bash
flutter run
```

## Features

- **Auth:** Company registration, admin login, company setup
- **Chat:** Modern chat UI, typing animation, FAQ quick buttons, intent-based replies
- **AI logic:** Intent detection (exact phrase → contains phrase → keyword overlap), unknown questions saved to DB
- **Human handoff:** After 2 consecutive non-matches, show support email/WhatsApp
- **Auto learning:** Unknown questions listed in Admin → Suggested; approve to create new intents
- **Admin:** Dashboard, intent CRUD, analytics (sessions, messages, duration, ratings, pending questions)
- **Settings:** Branding (color, welcome message), handoff (email, WhatsApp), integration snippet
- **Integration:** Web widget snippet, Flutter SDK example, API endpoint doc in `integration/`

## Database (main tables)

- `companies` – name, logo_url, primary_color, welcome_message, support_email, support_whatsapp
- `users` – company_id, role (admin/agent), email
- `chat_sessions` – company_id, user_identifier
- `messages` – session_id, sender (bot/user), message
- `intents` – company_id, intent_name, training_phrases (JSONB), response_text
- `unknown_questions` – company_id, question, frequency, status (pending/approved)
- `ratings` – session_id, rating 1–5, feedback

RLS policies restrict access so users only see their company’s data.

## Integration

- **Web:** `integration/web_widget_snippet.html` – paste into your site and set URL, anon key, company ID.
- **Flutter:** `integration/flutter_sdk_example.dart` – example of embedding the chat.
- **API:** `integration/api_endpoint_example.md` – REST/Edge Function usage for external apps.

## Offline (future)

Planned: cache FAQ/intents locally, queue messages offline, sync when back online (PWA-style).

## License

MIT.
