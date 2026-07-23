-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "earthdistance" CASCADE;

-- ─── User profiles ────────────────────────────────────────────────────────────
CREATE TABLE public.user_profiles (
  id                   UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name         TEXT NOT NULL,
  search_radius_meters INT NOT NULL DEFAULT 2000,
  onboarding_complete  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.user_dietary_restrictions (
  id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  value   TEXT NOT NULL
);

CREATE TABLE public.user_health_goals (
  id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  value   TEXT NOT NULL
);

CREATE TABLE public.user_allergens (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id  UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  allergen TEXT NOT NULL
);

CREATE TABLE public.user_cuisine_preferences (
  id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  value   TEXT NOT NULL
);

CREATE TABLE public.user_nutrition_targets (
  user_id             UUID PRIMARY KEY REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  daily_calories      INT,
  max_meal_calories   INT,
  max_carbs_g         INT,
  max_sodium_mg       INT,
  min_protein_g       INT,
  max_saturated_fat_g INT
);

-- ─── Restaurant cache (shared, no RLS) ───────────────────────────────────────
CREATE TABLE public.restaurants (
  place_id        TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  latitude        DOUBLE PRECISION NOT NULL,
  longitude       DOUBLE PRECISION NOT NULL,
  address         TEXT,
  city            TEXT,
  rating          NUMERIC(2,1),
  price_level     SMALLINT,
  cuisine_types   TEXT[],
  photo_reference TEXT,
  phone_number    TEXT,
  website         TEXT,
  cached_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_restaurants_location ON public.restaurants
  USING gist (ll_to_earth(latitude, longitude));

-- ─── Menu items cache (shared, no RLS) ───────────────────────────────────────
CREATE TABLE public.menu_items (
  item_id          TEXT PRIMARY KEY,
  restaurant_name      TEXT NOT NULL,
  name                 TEXT NOT NULL,
  serving_weight_grams NUMERIC,
  calories             INT,
  total_fat_g          NUMERIC,
  saturated_fat_g      NUMERIC,
  sodium_mg            INT,
  total_carbs_g        NUMERIC,
  dietary_fiber_g      NUMERIC,
  sugars_g             NUMERIC,
  protein_g            NUMERIC,
  image_url            TEXT,
  is_verified          BOOLEAN DEFAULT FALSE,
  cached_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_menu_items_restaurant_name ON public.menu_items (restaurant_name);

-- ─── GPT health analysis cache (shared) ──────────────────────────────────────
CREATE TABLE public.item_health_analysis (
  item_id  TEXT PRIMARY KEY REFERENCES public.menu_items(item_id) ON DELETE CASCADE,
  summary_text TEXT NOT NULL,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── User saved items ─────────────────────────────────────────────────────────
CREATE TABLE public.saved_restaurants (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id  UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  place_id TEXT NOT NULL REFERENCES public.restaurants(place_id),
  saved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, place_id)
);

CREATE TABLE public.saved_menu_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES public.menu_items(item_id),
  saved_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, item_id)
);

-- ─── Chat history ─────────────────────────────────────────────────────────────
CREATE TABLE public.chat_messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  role       TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content    TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_messages_user_created ON public.chat_messages (user_id, created_at DESC);

-- ─── Recommendation logs ──────────────────────────────────────────────────────
CREATE TABLE public.recommendation_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  place_id    TEXT NOT NULL,
  item_id TEXT NOT NULL,
  score       SMALLINT,
  action      TEXT CHECK (action IN ('viewed', 'saved', 'dismissed')),
  logged_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recommendation_logs_user ON public.recommendation_logs (user_id, logged_at DESC);

-- ─── Row Level Security ───────────────────────────────────────────────────────
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_dietary_restrictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_health_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_allergens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_cuisine_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_nutrition_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendation_logs ENABLE ROW LEVEL SECURITY;

-- User profile policies
CREATE POLICY "Users read own profile" ON public.user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users insert own profile" ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Child profile table policies (dietary, goals, allergens, cuisine, targets)
CREATE POLICY "Users manage own dietary" ON public.user_dietary_restrictions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own goals" ON public.user_health_goals FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own allergens" ON public.user_allergens FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own cuisine" ON public.user_cuisine_preferences FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own targets" ON public.user_nutrition_targets FOR ALL USING (auth.uid() = user_id);

-- Saved items policies
CREATE POLICY "Users manage own saved restaurants" ON public.saved_restaurants FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own saved items" ON public.saved_menu_items FOR ALL USING (auth.uid() = user_id);

-- Chat policies
CREATE POLICY "Users manage own chat" ON public.chat_messages FOR ALL USING (auth.uid() = user_id);

-- Log policies
CREATE POLICY "Users manage own logs" ON public.recommendation_logs FOR ALL USING (auth.uid() = user_id);

-- Shared caches are publicly readable (no sensitive data)
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_health_analysis ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Restaurants are public" ON public.restaurants FOR SELECT USING (TRUE);
CREATE POLICY "Menu items are public" ON public.menu_items FOR SELECT USING (TRUE);
CREATE POLICY "Item analysis is public" ON public.item_health_analysis FOR SELECT USING (TRUE);
