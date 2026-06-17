-- =====================================================
-- SMART SUPPORT AI - Supabase PostgreSQL Schema
-- Multi-tenant SaaS chatbot platform
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------
-- companies: each tenant has isolated data & branding
-- -----------------------------------------------------
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  logo_url TEXT,
  primary_color TEXT DEFAULT '#6366F1',
  welcome_message TEXT DEFAULT 'Hello! How can I help you today?',
  support_email TEXT,
  support_whatsapp TEXT,
  subscription_plan TEXT DEFAULT 'free',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------
-- users: linked to Supabase Auth, role per company
-- -----------------------------------------------------
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'admin' CHECK (role IN ('admin', 'agent')),
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_company ON users(company_id);

-- -----------------------------------------------------
-- intents: company-specific training phrases & responses
-- -----------------------------------------------------
CREATE TABLE intents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  intent_name TEXT NOT NULL,
  training_phrases JSONB NOT NULL DEFAULT '[]',
  response_text TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_intents_company ON intents(company_id);

-- -----------------------------------------------------
-- chat_sessions: one per conversation
-- -----------------------------------------------------
CREATE TABLE chat_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_identifier TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  end_time TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_chat_sessions_company ON chat_sessions(company_id);
CREATE INDEX idx_chat_sessions_started ON chat_sessions(started_at);

-- -----------------------------------------------------
-- messages: messages in a session
-- -----------------------------------------------------
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
  sender TEXT NOT NULL CHECK (sender IN ('user', 'bot')),
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_messages_session ON messages(session_id);

-- -----------------------------------------------------
-- unknown_questions: auto-learning, repeated unanswered
-- -----------------------------------------------------
CREATE TABLE unknown_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  frequency INT NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_unknown_questions_company_status ON unknown_questions(company_id, status);

-- -----------------------------------------------------
-- ratings: session satisfaction
-- -----------------------------------------------------
CREATE TABLE ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  feedback TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ratings_session ON ratings(session_id);

-- -----------------------------------------------------
-- RLS (Row Level Security) - company isolation
-- -----------------------------------------------------
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE intents ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE unknown_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

-- Users can read/update their own company
CREATE POLICY "Users read own company" ON companies FOR SELECT
  USING (id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users update own company" ON companies FOR UPDATE
  USING (id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users read own row" ON users FOR ALL USING (id = auth.uid());

CREATE POLICY "Users manage intents for own company" ON intents FOR ALL
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users manage sessions for own company" ON chat_sessions FOR ALL
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users manage messages via sessions" ON messages FOR ALL
  USING (session_id IN (SELECT id FROM chat_sessions WHERE company_id IN (SELECT company_id FROM users WHERE id = auth.uid())));

CREATE POLICY "Users manage unknown_questions for own company" ON unknown_questions FOR ALL
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users manage ratings via sessions" ON ratings FOR ALL
  USING (session_id IN (SELECT id FROM chat_sessions WHERE company_id IN (SELECT company_id FROM users WHERE id = auth.uid())));

-- Allow anon/service to insert companies and users during sign-up (or use service role)
CREATE POLICY "Allow insert companies" ON companies FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow insert users" ON users FOR INSERT WITH CHECK (true);

-- -----------------------------------------------------
-- Upsert unknown question: increment frequency if exists
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION upsert_unknown_question(p_company_id UUID, p_question TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id UUID;
BEGIN
  SELECT id INTO v_id FROM unknown_questions
  WHERE company_id = p_company_id AND lower(trim(question)) = lower(trim(p_question))
  LIMIT 1;
  IF v_id IS NOT NULL THEN
    UPDATE unknown_questions SET frequency = frequency + 1, updated_at = now() WHERE id = v_id;
  ELSE
    INSERT INTO unknown_questions (company_id, question, frequency, status)
    VALUES (p_company_id, trim(p_question), 1, 'pending');
  END IF;
END;
$$;


-- -----------------------------------------------------
-- chat_sessions: add start_time alias for compatibility (optional)
-- -----------------------------------------------------
COMMENT ON TABLE chat_sessions IS 'started_at = session start; end_time = when conversation ended';
