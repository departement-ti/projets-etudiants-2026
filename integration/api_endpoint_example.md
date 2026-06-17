# API Endpoint for External Apps

Use this from your mobile app, desktop app, or any backend to send messages and get bot responses.

## Base URL
```
https://YOUR_PROJECT.supabase.co
```

## 1. Create a session (optional, for analytics)
```http
POST /rest/v1/chat_sessions
Content-Type: application/json
apikey: YOUR_ANON_KEY
Authorization: Bearer YOUR_ANON_KEY
Prefer: return=representation

{
  "company_id": "uuid-of-your-company",
  "user_identifier": "user@example.com"
}
```
Response: `{ "id": "session-uuid", ... }`

## 2. Send message and get bot response (via Edge Function recommended)
```http
POST /functions/v1/chat
Content-Type: application/json
Authorization: Bearer YOUR_ANON_KEY

{
  "company_id": "uuid",
  "session_id": "session-uuid",
  "message": "How do I reset my password?"
}
```
Response: `{ "reply": "You can reset it from Settings > Security.", "intent_matched": "password_reset" }`

## 3. Direct DB insert (if no Edge Function)
Insert user message into `messages` table, then run intent detection in your backend using the same logic as `ChatLogicService` (match training phrases), then insert bot message.

## Edge Function sketch (Supabase Deno)
Create `supabase/functions/chat/index.ts`:
- Parse body: company_id, session_id, message
- Fetch intents for company_id from `intents` table
- Run keyword/phrase matching (same as ChatLogicService)
- If no match: call `upsert_unknown_question`, return fallback message or handoff
- Insert user message and bot message into `messages`
- Return { reply, intent_matched? }
