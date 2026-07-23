# Food Recommendation App — Implementation Plan

## Context

Greenfield mobile app (iOS + Android) that helps users find healthy meal options at nearby restaurants. The app collects a health profile (dietary restrictions, health goals, allergies, cuisine preferences) and uses device location to surface nearby restaurants, then matches menu items from those restaurants against the user's profile to produce personalized, ranked recommendations. The working directory `C:\Users\User\000000\vv\code\claude\PikMe` is currently empty.

---

## Tech Stack

| Concern | Choice | Reason |
|---|---|---|
| Framework | **Expo (React Native) + TypeScript** | Fastest cross-platform development, managed builds |
| Routing | **Expo Router** (file-based) | Clean separation of onboarding vs main app route groups |
| Database | **Supabase (PostgreSQL)** | Managed Postgres + stored procedures + auth + Edge Functions |
| DB client | **@supabase/supabase-js** | Type-safe RPC calls to stored procedures from the app |
| Local state | **Zustand** (ephemeral UI state only) | Fast in-memory state for map view, active session |
| Async/API | **React Query (@tanstack/react-query)** | Caching, loading/error states, background refetch |
| Forms | **react-hook-form + zod** | Validation for nutrition target numeric inputs |
| Maps | **react-native-maps** | Standard for Expo managed workflow |
| Restaurant data | **Google Places API** | Locations, ratings, hours, photos |
| Nutrition data | **Nutritionix API** | Per-item nutrition for 1000+ chain restaurants |
| AI / LLM | **OpenAI GPT-4o** via **Supabase Edge Functions** | All OpenAI calls proxied server-side — API key never in the app |

---

## Project Scaffold

```bash
npx create-expo-app@latest . --template blank-typescript

# Navigation + maps + location
npx expo install expo-router expo-linking react-native-safe-area-context react-native-screens
npx expo install expo-location react-native-maps

# Web support
npm install react-dom react-native-web --legacy-peer-deps

# State + storage
npm install zustand
npx expo install @react-native-async-storage/async-storage

# Data fetching
npm install axios @tanstack/react-query

# Forms + validation
npm install react-hook-form zod @hookform/resolvers

# UI + utils
npm install react-native-reanimated @gorhom/bottom-sheet --legacy-peer-deps
npx expo install expo-haptics expo-secure-store expo-constants expo-image

# Supabase
npm install @supabase/supabase-js --legacy-peer-deps
```

**`package.json` entry point:**
```json
"main": "expo-router/entry"
```

**Environment variables (`.env.local`, gitignored):**
```
EXPO_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_...   # safe to expose — RLS enforces access

# The following are set as Supabase Edge Function secrets only (never in the app):
# OPENAI_API_KEY
# NUTRITIONIX_APP_ID
# NUTRITIONIX_APP_KEY
# GOOGLE_PLACES_KEY
```

> **Security model:** Only the Supabase anon key is in the app. All sensitive API keys live in Supabase Edge Function secrets. The anon key is safe to expose because Row Level Security (RLS) on every table ensures users can only access their own data.

---

## Folder Structure

```
PikMe/
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   └── 002_stored_procedures.sql
│   └── functions/
│       ├── ai-recommend/index.ts
│       ├── ai-chat/index.ts
│       ├── ai-onboard/index.ts
│       ├── ai-item-analysis/index.ts
│       ├── fetch-nearby-restaurants/index.ts
│       └── fetch-menu-items/index.ts
│
├── app/
│   ├── _layout.tsx                   # Root: QueryClient + auth session gate
│   ├── (auth)/
│   │   └── sign-in.tsx
│   ├── (onboarding)/
│   │   ├── welcome.tsx
│   │   ├── ai-profile.tsx            # Free-text → GPT extracts health profile
│   │   ├── dietary.tsx
│   │   ├── health-goals.tsx
│   │   ├── allergies.tsx
│   │   ├── cuisine-prefs.tsx
│   │   └── location-permission.tsx
│   ├── (tabs)/
│   │   ├── _layout.tsx
│   │   ├── index.tsx                 # Map view
│   │   ├── explore.tsx               # Restaurant list
│   │   ├── chat.tsx                  # AI food assistant
│   │   ├── saved.tsx
│   │   └── profile.tsx
│   ├── restaurant/[id].tsx
│   └── modal/filter.tsx
│
├── src/
│   ├── api/
│   │   ├── supabase.ts               # Supabase client singleton
│   │   └── functions.ts              # Typed wrappers for all RPC + Edge Function calls
│   ├── components/
│   │   ├── map/
│   │   ├── restaurant/
│   │   ├── menu/
│   │   ├── chat/
│   │   └── common/
│   ├── engine/
│   │   └── recommendation.ts         # Rule-based hard filters + soft scoring
│   ├── hooks/
│   │   ├── useLocation.ts
│   │   ├── useNearbyRestaurants.ts
│   │   ├── useMenuRecommendations.ts
│   │   ├── useChat.ts
│   │   └── useUserProfile.ts
│   ├── store/
│   │   ├── userProfileStore.ts
│   │   ├── restaurantStore.ts
│   │   └── chatStore.ts
│   ├── types/
│   │   └── index.ts                  # All TypeScript interfaces
│   ├── constants/
│   │   ├── dietaryOptions.ts
│   │   ├── prompts.ts                # All GPT system prompts
│   │   └── theme.ts
│   └── utils/
│       ├── storage.ts
│       ├── geo.ts
│       └── format.ts
│
├── app.config.ts
├── .env.local                        # gitignored
└── PLAN.md                           # this file
```

---

## Core Data Models (`src/types/index.ts`)

```typescript
interface UserProfile {
  id: string;
  displayName: string;
  dietaryRestrictions: ('vegetarian'|'vegan'|'gluten_free'|'halal'|'kosher'|'none')[];
  healthGoals: ('weight_loss'|'low_carb'|'low_sodium'|'high_protein'|'diabetic_friendly'|'heart_healthy'|'balanced')[];
  cuisinePreferences: ('american'|'italian'|'mexican'|'chinese'|'japanese'|'indian'|'mediterranean'|'thai'|'korean'|'middle_eastern')[];
  allergens: string[];
  nutritionTargets: { dailyCalories?, maxMealCalories?, maxCarbs_g?, maxSodium_mg?, minProtein_g?, maxSaturatedFat_g? };
  searchRadiusMeters: number;
  onboardingComplete: boolean;
}

interface Restaurant {
  placeId: string;
  name: string;
  location: { latitude, longitude, address, city };
  distanceMeters: number;
  rating: number;
  cuisineTypes: string[];
  photoReference?: string;
  openNow: boolean;
  hasNutritionData: boolean;
}

interface MenuItem {
  itemId: string;
  restaurantName: string;
  name: string;
  nutrition: { calories, totalFat_g, saturatedFat_g, sodium_mg, totalCarbs_g, protein_g, ... };
}

interface Recommendation {
  menuItem: MenuItem;
  restaurant: Restaurant;
  score: number;       // 0–100
  reasons: string[];
  warnings: string[];
  rank: number;
}
```

---

## Database Schema

All migrations in `supabase/migrations/`. Every user-data table has Row Level Security.

### Tables
- `user_profiles` — one row per auth user, `onboarding_complete` flag
- `user_dietary_restrictions` — many per user
- `user_health_goals` — many per user
- `user_allergens` — free-text, many per user
- `user_cuisine_preferences` — many per user
- `user_nutrition_targets` — one per user
- `restaurants` — shared cache, no RLS (public read)
- `menu_items` — shared cache, no RLS (public read)
- `item_health_analysis` — GPT summary cache per item
- `saved_restaurants` — per user
- `saved_menu_items` — per user
- `chat_messages` — per user, ordered by created_at
- `recommendation_logs` — per user, for future ML

### Stored Procedures (11 total, all called via `supabase.rpc()`)

| Function | Purpose |
|---|---|
| `upsert_user_profile(...)` | Save full profile in one atomic call |
| `get_user_profile()` | Fetch full profile as JSON in one call |
| `upsert_restaurants(jsonb)` | Bulk-insert/update restaurant cache |
| `upsert_menu_items(jsonb)` | Bulk-insert/update menu item cache |
| `filter_menu_items_for_user(ids)` | Hard filter: dietary + allergens + calorie cap |
| `toggle_saved_restaurant(place_id)` | Save/unsave toggle, returns bool |
| `toggle_saved_menu_item(item_id)` | Save/unsave toggle, returns bool |
| `get_saved_items()` | All saved restaurants + items in one call |
| `append_chat_message(role, content)` | Insert message, return last 20 for GPT context |
| `log_recommendation_action(...)` | Log viewed/saved/dismissed action |
| `get_item_analysis(id)` / `set_item_analysis(id, text)` | GPT summary cache |

---

## Supabase Edge Functions (6 total)

All live in `supabase/functions/`. Called via `supabase.functions.invoke(name, { body })`.

| Function | Phase | Purpose |
|---|---|---|
| `fetch-nearby-restaurants` | 3 | Calls Google Places API → upserts restaurants |
| `fetch-menu-items` | 4 | Calls Nutritionix API → upserts menu items |
| `ai-onboard` | 5 | GPT extracts UserProfile from free text |
| `ai-recommend` | 5 | GPT ranks filtered menu items |
| `ai-item-analysis` | 5 | GPT writes 1-sentence item health summary |
| `ai-chat` | 5 | Streaming GPT food assistant |

---

## OpenAI Integration

Model: **gpt-4o** for recommendations/chat, **gpt-4o-mini** for onboarding extraction and item analysis.

All system prompts in `src/constants/prompts.ts`:
- `profileExtraction` — extract UserProfile fields from free text
- `recommendation` — rank top 15 menu items, return JSON with scores/reasons/warnings
- `itemAnalysis` — 1-sentence health summary for a menu item
- `quickDecision` — yes/no recommendation in 1–2 sentences
- `chat(profile, restaurants)` — streaming food assistant with user context

---

## Recommendation Engine (`src/engine/recommendation.ts`)

`scoreAndRankItems(profile, items) → Recommendation[]`

**Phase 1 — Hard filters:** vegan/vegetarian/gluten-free/halal keyword exclusion, allergen substring match, calorie hard cap (`maxMealCalories * 1.5`)

**Phase 2 — Soft scoring (weighted sum 0–100):**

| Dimension | Base Weight |
|---|---|
| Calories | 30 |
| Protein | 20 |
| Carbs | 15 |
| Sodium | 15 |
| Saturated fat | 10 |
| Cuisine match | 10 |

Goal multipliers: `weight_loss` → calorie ×1.5, protein ×1.3 | `low_carb` → carb ×2.0 | `heart_healthy` → fat ×2.0, sodium ×1.5 | `high_protein` → protein ×2.5 | `low_sodium` → sodium ×3.0

**Phase 3 — Reasons & warnings:** human-readable labels from thresholds

**Phase 4 — Return top 20** sorted by score descending

---

## Implementation Phases

### Phase 1 — Foundation (Days 1–3) ✅ COMPLETE
- Expo scaffold, all packages, `app.config.ts`
- Supabase project, migrations run
- `src/api/supabase.ts` + `src/api/functions.ts`
- Auth session gate in `app/_layout.tsx`
- Sign-in screen, welcome screen, tab stubs

### Phase 2 — User Profile System (Days 4–6)
- All 6 onboarding screens with real UI
- Wire to `upsert_user_profile()` on completion
- `profile.tsx` reads/edits via `get_user_profile()`
- Verify profile persists across restarts

### Phase 3 — Location + Restaurants (Days 7–9)
- `useLocation.ts` with `expo-location`
- `fetch-nearby-restaurants` Edge Function (Google Places)
- `useNearbyRestaurants.ts` → Zustand store
- `RestaurantMap.tsx`, `RestaurantCard.tsx`, `RestaurantList.tsx`
- Map + Explore tabs wired up, 200m re-fetch debounce

### Phase 4 — Menu Items + Hard Filter (Days 10–12)
- `fetch-menu-items` Edge Function (Nutritionix)
- `filter_menu_items_for_user()` stored procedure
- `src/engine/recommendation.ts` scoring
- `MenuItemCard.tsx`, `RecommendationList.tsx`
- `restaurant/[id].tsx` with full menu UI

### Phase 5 — OpenAI via Edge Functions (Days 13–16)
- All 4 AI Edge Functions deployed
- `(onboarding)/ai-profile.tsx` with GPT profile extraction
- GPT recommendations in restaurant detail screen
- "Should I get this?" quick decision button
- Streaming chat tab with `chatStore.ts` + `useChat.ts`

### Phase 6 — Polish (Days 17–18)
- `saved.tsx` tab with full save/unsave functionality
- Recommendation action logging
- Skeleton screens, error boundaries, empty states, haptic feedback
- Offline graceful degradation

### Phase 7 — Production Prep (Days 19–21)
- End-to-end testing on real devices
- All error states (offline, 429, timeout, OpenAI errors)
- EAS Build config (`eas.json`)
- Performance audit (FlatList, map throttle, React Query dedup)
- Accessibility labels on all interactive elements
- RLS audit (verify no cross-user data leaks)

---

## Critical Files

1. `supabase/migrations/001_initial_schema.sql` + `002_stored_procedures.sql` — everything depends on these
2. `src/api/supabase.ts` + `src/api/functions.ts` — shared by every hook and component
3. `src/constants/prompts.ts` — all GPT system prompts, tune here without touching Edge Function code
4. `src/types/index.ts` — all TypeScript interfaces, must match DB column names
5. `src/engine/recommendation.ts` — client-side scoring, tested independently
6. `app/_layout.tsx` — auth gate, must work for anything to render

---

## Verification Checklist

1. Register → confirmation email (or disabled) → sign in → lands on welcome screen
2. Complete onboarding → `user_profiles` row exists in Supabase with `onboarding_complete = true`
3. Kill and reopen app → goes straight to tabs (not onboarding)
4. Near restaurants (or mocked GPS) → markers appear on map
5. Tap chain restaurant → menu items load, GPT ranking runs, items show health summaries
6. "Should I get this?" → 1–2 sentence GPT response
7. Set restriction to "Vegan" → meat items excluded before GPT is called
8. Chat tab → "What's a good low-carb option near me?" → streaming response appears
9. Independent restaurant → graceful "no nutrition data" message
10. RLS check: user A cannot read user B's `user_profiles` row
