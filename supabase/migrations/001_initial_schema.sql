-- Smart Support AI - Multi-tenant schema
-- Run this in Supabase SQL Editor

-- Companies (tenants)
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  logo_url TEXT,
  primary_color TEXT DEFAULT '#6366F1',
  welcome_message TEXT DEFAULT 'Hello! How can I help you today?',
  support_email TEXT,
  support_whatsapp TEXT,
  subscription_plan TEXT DEFAULT 'free' CHECK (subscription_plan IN ('free', 'pro', 'enterprise')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- App users (linked to Supabase Auth via id)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'agent' CHECK (role IN ('admin', 'agent')),
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(company_id, email)
);

-- Chat sessions
CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_identifier TEXT NOT NULL,
  start_time TIMESTAMPTZ DEFAULT now(),
  end_time TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_chat_sessions_company ON public.chat_sessions(company_id);
CREATE INDEX idx_chat_sessions_user ON public.chat_sessions(user_identifier);

-- Messages
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  sender TEXT NOT NULL CHECK (sender IN ('bot', 'user')),
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_messages_session ON public.messages(session_id);

-- Intents (training data per company)
CREATE TABLE IF NOT EXISTS public.intents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  intent_name TEXT NOT NULL,
  training_phrases JSONB NOT NULL DEFAULT '[]'::jsonb,
  response_text TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_intents_company ON public.intents(company_id);

-- Unknown questions (for learning)
CREATE TABLE IF NOT EXISTS public.unknown_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  frequency INT DEFAULT 1,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_unknown_questions_company ON public.unknown_questions(company_id);
CREATE INDEX idx_unknown_questions_status ON public.unknown_questions(status);

-- Ratings
CREATE TABLE IF NOT EXISTS public.ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  feedback TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_ratings_session ON public.ratings(session_id);

-- Enable RLS on all tables
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unknown_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

-- RLS: users can only see their company's data
CREATE POLICY "Users read own company" ON public.companies
  FOR SELECT USING (
    id IN (SELECT company_id FROM public.users WHERE id = auth.uid())
  );

CREATE POLICY "Admins update own company" ON public.companies
  FOR ALL USING (
    id IN (SELECT company_id FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users read own profile" ON public.users
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users insert own profile" ON public.users
  FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY "Users read company sessions" ON public.chat_sessions
  FOR SELECT USING (
    company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid())
  );

CREATE POLICY "Users manage company sessions" ON public.chat_sessions
  FOR ALL USING (
    company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid())
  );

CREATE POLICY "Users read company messages" ON public.messages
  FOR SELECT USING (
    session_id IN (
      SELECT id FROM public.chat_sessions
      WHERE company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid())
    )
  );

CREATE POLICY "Users insert messages" ON public.messages
  FOR INSERT WITH CHECK (
    session_id IN (
      SELECT id FROM public.chat_sessions
      WHERE company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid())
    )
  );

CREATE POLICY "Users read company intents" ON public.intents
  FOR SELECT USING (
    company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid())
  );

CREATE POLICY "Admins manage intents" ON public.intents
  FOR ALL USING (
    company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users read unknown questions" ON public.unknown_questions
  FOR SELECT USING (
    company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid())
  );

CREATE POLICY "Admins manage unknown questions" ON public.unknown_questions
  FOR ALL USING (
    company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users read company ratings" ON public.ratings
  FOR SELECT USING (
    session_id IN (
      SELECT id FROM public.chat_sessions
      WHERE company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid())
    )
  );

CREATE POLICY "Users insert ratings" ON public.ratings
  FOR INSERT WITH CHECK (
    session_id IN (
      SELECT id FROM public.chat_sessions
      WHERE company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid())
    )
  );

-- Service role can do everything (for Edge Functions / server)
-- Anonymous/anon key: allow chat for end-users by company_id (handled in app/Edge Function)

-- Function: insert or increment unknown question (by matching normalized text)
CREATE OR REPLACE FUNCTION public.upsert_unknown_question(
  p_company_id UUID,
  p_question TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  normalized TEXT := lower(trim(p_question));
  existing_id UUID;
BEGIN
  SELECT id INTO existing_id FROM public.unknown_questions
  WHERE company_id = p_company_id AND lower(trim(question)) = normalized
  LIMIT 1;
  IF existing_id IS NOT NULL THEN
    UPDATE public.unknown_questions SET frequency = frequency + 1 WHERE id = existing_id;
  ELSE
    INSERT INTO public.unknown_questions (company_id, question, frequency)
    VALUES (p_company_id, p_question, 1);
  END IF;
END;
$$;
