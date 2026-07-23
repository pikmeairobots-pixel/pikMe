# PikMe — Project Context & Implementation Guide

## Overview
**PikMe** is a food recommendation mobile app built with **Expo React Native** that uses AI (Claude API) to provide personalized restaurant and menu item recommendations based on user health goals and dietary preferences.

**Status:** Phases 1-6 complete. Phase 7 (Production Prep) pending.

---

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Frontend** | Expo / React Native | SDK 56 |
| **Routing** | expo-router | ~56.2.9 |
| **State** | Zustand (ephemeral) + React Query (async) | ~5.101 / ~5.0.14 |
| **Backend** | Supabase (self-hosted) | v2.107.0 |
| **AI** | Claude API | claude-haiku-4-5-20251001 |
| **Location** | expo-location (GPS) | ~56.0.16 |
| **Maps** | react-native-maps + Google Places | 1.27.2 |
| **Styling** | React Native StyleSheet + inline styles | - |
| **Database** | PostgreSQL (Supabase) | - |
| **Auth** | Supabase Auth (JWT) | - |

---

## Project Structure

```
PikMe/
├── app/                           # File-based routing (Expo Router)
│   ├── (auth)/                    # Auth screens (sign-in, register)
│   ├── (onboarding)/              # Onboarding flow (welcome, quiz, AI profile)
│   ├── (tabs)/                    # Main app tabs (map, explore, chat, saved, profile)
│   │   ├── _layout.tsx            # Tab navigation + ErrorBoundary + boot load
│   │   ├── index.tsx              # Map tab
│   │   ├── explore.tsx            # Explore/list restaurants
│   │   ├── chat.tsx               # Chat with AI food assistant
│   │   ├── saved.tsx              # Saved restaurants & menu items
│   │   └── profile.tsx            # User profile & settings
│   ├── restaurant/[id].tsx        # Restaurant detail + menu recommendations
│   └── _layout.tsx                # Root layout (auth gate, query provider, error boundary)
│
├── src/
│   ├── api/
│   │   ├── supabase.ts            # Supabase client init
│   │   └── functions.ts           # All API calls to edge functions & RPCs
│   ├── components/
│   │   ├── restaurant/
│   │   │   └── RestaurantCard.tsx # Restaurant card (photo, heart, status)
│   │   ├── menu/
│   │   │   └── MenuItemCard.tsx   # Menu item card (score, macros, AI analysis)
│   │   ├── chat/
│   │   │   └── ChatBubble.tsx     # Chat message bubble
│   │   └── common/
│   │       ├── ErrorBoundary.tsx  # Error boundary class component
│   │       └── SkeletonCard.tsx   # Skeleton loading placeholders
│   ├── hooks/
│   │   ├── useLocation.ts         # GPS + browser geolocation
│   │   ├── useNearbyRestaurants.ts # Fetch nearby restaurants (React Query)
│   │   ├── useMenuRecommendations.ts # Fetch menu items & rank (React Query)
│   │   ├── useUserProfile.ts      # Fetch user profile (React Query)
│   │   ├── useChat.ts             # Send chat messages & manage state
│   │   └── useSaved.ts            # Manage saved restaurants/items (optimistic UI)
│   ├── store/
│   │   ├── userProfileStore.ts    # Zustand: onboarding completion state
│   │   ├── restaurantStore.ts     # Zustand: location + restaurant list (in-memory)
│   │   ├── chatStore.ts           # Zustand: chat messages (ephemeral)
│   │   └── savedStore.ts          # Zustand: saved IDs & arrays + load state
│   ├── engine/
│   │   └── recommendation.ts      # Scoring & ranking algorithm for menu items
│   ├── types/
│   │   └── index.ts               # TypeScript types (Restaurant, MenuItem, etc.)
│   └── utils/
│       └── geo.ts                 # Distance formatting (meters → miles/km)
│
├── supabase/
│   └── migrations/
│       ├── 001_initial_schema.sql # Tables: users, restaurants, menu_items, saved_*, chat, logs
│       └── 002_stored_procedures.sql # RPCs for auth, toggle_save, get_saved_items, etc.
│
├── .env.local                     # API keys (EXPO_PUBLIC_SUPABASE_URL, etc.)
├── app.config.js                  # Expo config (SDK 56, plugins, app metadata)
└── package.json                   # Dependencies
```

---

## Phases Implemented

### Phase 1 — Auth & Onboarding ✅
**Goal:** User registration, login, profile setup.

**Key Files:**
- `app/(auth)/sign-in.tsx`, `app/(auth)/register.tsx`
- `app/(onboarding)/welcome.tsx`, `app/(onboarding)/quiz.tsx`, `app/(onboarding)/ai-profile.tsx`
- `src/hooks/useUserProfile.ts`
- Supabase Auth + RPC `upsert_user_profile`

**Implementation:**
- Supabase JWT auth with email/password
- Quiz captures health goals, dietary restrictions, allergens, cuisine prefs
- `ai-onboard` edge function extracts profile from free-text description using Claude
- Profile stored in PostgreSQL with RLS policies

---

### Phase 2 — Location & Restaurant Discovery ✅
**Goal:** Get user location, find nearby restaurants, display on map & list.

**Key Files:**
- `src/hooks/useLocation.ts` (expo-location + browser geolocation)
- `src/hooks/useNearbyRestaurants.ts` (React Query)
- `app/(tabs)/index.tsx` (map), `app/(tabs)/explore.tsx` (list)
- `supabase/functions/fetch-nearby-restaurants/` (Google Places API)

**Implementation:**
- GPS location via `expo-location` (phone) or browser geolocation (web)
- Google Places Nearby Search → Supabase cache table
- Restaurants ranked by distance
- Map view using `react-native-maps`

---

### Phase 3 — Menu Fetching & Caching ✅
**Goal:** Fetch menu items for restaurants, cache in DB, use for recommendations.

**Key Files:**
- `supabase/functions/fetch-menu-items/` (Nutritionix API — kept intact)
- `supabase/functions/fetch-menu-items-ai/` (Claude API — active)
- `src/hooks/useMenuRecommendations.ts`
- RPC `upsert_menu_items`

**Implementation:**
- Claude API generates realistic menu items + nutrition for restaurants
- 30-day DB cache with `is_verified=false` flag (AI-generated)
- Deterministic SHA-256 IDs: `ai_${hex.slice(0,24)}`
- Fallback to Nutritionix for verified data (code intact but not used)

---

### Phase 4 — Recommendation Scoring & Ranking ✅
**Goal:** Rank menu items by user profile (health goals, restrictions, budget).

**Key Files:**
- `src/engine/recommendation.ts` (scoring algorithm)
- `src/components/menu/MenuItemCard.tsx` (display)

**Scoring Logic:**
- Hard filters: dietary restrictions (vegan/vegetarian/gluten-free/halal), allergens, calorie caps
- Soft scoring: calories, protein, carbs, sodium, saturated fat, cuisine match
- Goal multipliers: `weight_loss` (cal×1.5, protein×1.3), `low_carb` (carbs×2.0), `heart_healthy` (satfat×2.0, sodium×1.5), `high_protein` (protein×2.5), `low_sodium` (sodium×3.0)
- Returns top 20 with reasons (e.g., "Low sodium", "High protein") and warnings (e.g., "High calorie")

---

### Phase 5 — AI Features ✅
**Goal:** Chat assistant, item health analysis, onboarding profile extraction.

**Key Files:**
- `supabase/functions/ai-onboard/` → `Partial<UserProfile>` from free text
- `supabase/functions/ai-item-analysis/` → "Should I get this?" 2-sentence verdict
- `supabase/functions/ai-chat/` → Conversational food advice
- `src/hooks/useChat.ts`, `src/components/chat/ChatBubble.tsx`
- `app/(tabs)/chat.tsx` (UI with typing indicator)

**Implementation:**
- All use `claude-haiku-4-5-20251001`
- System prompts include user goals, restrictions, allergens, nearby restaurants
- Chat stored in DB with RLS (user can only see their own)
- Non-streaming for simplicity (full response returned)
- Analysis cached via RPC `set_item_analysis` (shared across users)

---

### Phase 6 — Polish & UX ✅
**Goal:** Save functionality, heart buttons, skeleton loaders, error boundaries.

**Key Files:**
- `src/store/savedStore.ts` (Zustand: saved IDs + arrays)
- `src/hooks/useSaved.ts` (optimistic toggle + revert)
- `src/components/restaurant/RestaurantCard.tsx` (Google Places photos, heart, status pills)
- `src/components/menu/MenuItemCard.tsx` (score badge, macro breakdown, AI button, analysis panel)
- `src/components/common/ErrorBoundary.tsx` (class component error catcher)
- `src/components/common/SkeletonCard.tsx` (pulsing loaders)
- `app/(tabs)/saved.tsx` (saved restaurants & items tabs)
- `supabase/functions/fetch-nearby-restaurants/` (fixed: flatten restaurant location before DB upsert)

**Implementation Details:**

**Save Flow:**
1. User taps heart ❤️ on restaurant/menu item card
2. `useSaved().toggleRestaurant(placeId, restaurant)` called
3. Optimistic UI update: heart changes immediately
4. `toggleSavedRestaurant(placeId, restaurant)` called async
5. If restaurant missing from DB, upsert it first (safety net)
6. RPC `toggle_saved_restaurant` toggles save in DB
7. On error: revert heart + show error
8. Haptics feedback: `Haptics.impactAsync(Light)`

**Bootstrap Load:**
- `_layout.tsx` calls `getSavedItems()` on app boot
- Populates `useSavedStore` globally
- Hearts show correct state on Explore/restaurant tabs without delay

**UI Redesign (Uber-like):**
- Restaurant cards: 170px photo, float heart button, status pill on image, rating pill
- Menu cards: score badge (square), large calories left, macros row right, AI button inverts to black when open
- Explore: time-aware greeting, "Near you" badge, dark active chips, section header with count
- Restaurant detail: 260px hero image with back/heart buttons, info card overlaps photo
- Tab bar: white background, emoji icons, green dot for active state

---

### Phase 7 — Production Prep ⏳ Pending

**Tasks:**
1. **EAS Build** — configure `eas.json` for iOS/Android builds
2. **RLS Audit** — verify row-level security (users can't read other users' data)
3. **Performance** — add `getItemLayout` to FlatLists, memoize cards, image caching
4. **Accessibility** — add `accessibilityLabel` to icon-only buttons
5. **Error Surfaces** — toast/snackbar for failed saves (currently silent)
6. **App Icon & Splash** — replace Expo defaults before App Store submission

---

## Environment Setup

### `.env.local` Required Keys

```env
EXPO_PUBLIC_SUPABASE_URL=http://srv1747781.hstgr.cloud:8000
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
EXPO_PUBLIC_GOOGLE_MAPS_API_KEY=AIzaSyD...
```

### Supabase Docker Setup

Self-hosted at `http://srv1747781.hstgr.cloud:8000` (VPS).

**Edge Function Secrets** (NOT in `.env.local` — server-side only):
- `ANTHROPIC_API_KEY` — Claude API key
- `GOOGLE_PLACES_KEY` — Google Places API key
- `NUTRITIONIX_APP_ID`, `NUTRITIONIX_KEY` — Nutritionix API (backup)

---

## Running the App

### Local Development

```bash
# Install deps
npm install --legacy-peer-deps

# Start dev server
$env:NODE_OPTIONS = "--openssl-legacy-provider"  # Windows PowerShell
npx expo start --clear

# Press 'w' for web (localhost:19006)
# Press 's' to switch to Expo Go (scan QR code on phone)
```

### Web Version (Deployment)

```bash
# Export for web
npx expo export --platform web

# Outputs: dist/ folder (static files)

# Deploy to Vercel/Netlify:
vercel
# or
netlify deploy --prod --dir=dist
```

### Testing on Phone

**Via Expo Go:**
- Requires Expo Go app on phone (supports SDK 54)
- Press `s` in terminal to switch from dev client to Expo Go
- Scan QR code with iPhone camera or Safari deep link

**Via EAS Dev Build:**
- Circumvents SDK version limits
- ```bash
  eas build --platform ios --profile preview
  ```
- Works with any SDK version

---

## Known Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| "Edge Function returned non-2xx" | Real error hidden by Supabase client | Extract error body: `(error as any).context?.json?.()` |
| "ANTHROPIC_API_KEY not configured" | Secret not in edge-runtime env | Add to `docker/.env`, restart: `docker compose restart supabase-edge-runtime` |
| Restaurant save fails (FK constraint) | Restaurant not in cache table | Upsert restaurant before toggle in `toggleSavedRestaurant()` |
| Menu item save fails | Same as above | Upsert menu item in `toggleSavedMenuItem()` |
| Hearts show 🤍 on app boot | Saved state only loads on Saved tab mount | Boot load in `_layout.tsx`: call `getSavedItems()` + `useSavedStore.setAll()` |
| Unsave removes card from list | Array not filtered | `toggleRestaurantId()` / `toggleMenuItemId()` also filter arrays |
| "Cannot find module react-native-worklets/plugin" | SDK version mismatch (SDK 54 + SDK 56 packages) | Upgrade/downgrade all packages to same SDK version |
| "No usable data found" (QR scan) | QR too small on terminal | Scan from `http://localhost:8081` in browser instead |
| "Project is incompatible with Expo Go" | Phone Expo Go < app SDK version | Use EAS dev build or press `s` to switch modes |
| Blank web page at localhost | SDK mismatch breaking build | Ensure all packages match SDK version in `package.json` |

---

## Key Decisions & Trade-offs

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **Zustand over Redux** | Simpler, smaller bundle, perfect for ephemeral state | Less tooling, smaller community |
| **React Query for async** | Automatic caching, retry logic, background refetch | One more library (but worth it) |
| **Non-streaming chat** | Simpler UX, easier to implement, typing indicator provides perceived responsiveness | Slower feel than true streaming |
| **Claude over GPT-4** | User has Claude credits, cheaper, works well for our tasks | Less powerful for complex analysis |
| **Self-hosted Supabase** | Full control, no vendor lock-in, can run anywhere | Requires Docker/VPS knowledge |
| **RLS over JWT checks** | Database-level security (correct layer), works offline-first | More complex to debug |
| **30-day cache for AI items** | Balance between freshness and API cost | Stale data if restaurants change menu |
| **Deterministic AI item IDs** | Same restaurant+item always gets same ID (no duplicates) | Changing restaurant name breaks ID |
| **Optimistic UI for saves** | Instant feedback, no loading state needed | Must revert if API fails |

---

## Testing Checklist (Phase 6 Verification)

- [ ] **Auth**: Sign up → complete quiz → redirected to tabs
- [ ] **Location**: Location permission granted → nearby restaurants load
- [ ] **Explore Tab**: Restaurants display with photos, hearts, status, search/filter works
- [ ] **Heart Toggle**: Tap heart → optimistic update → syncs to DB
- [ ] **Unsave**: Saved tab → heart → item disappears from list
- [ ] **Menu Recommendations**: Click restaurant → top 20 items ranked by score
- [ ] **AI Analysis**: "Should I get this?" → 2-sec analysis → cached on second tap
- [ ] **Chat**: Type question → "Analysing..." → response from Claude
- [ ] **Saved Tab**: View saved restaurants/items, pull-to-refresh loads from DB
- [ ] **Error Boundary**: Intentionally cause error → shows fallback, "Try again" resets

---

## Next Steps for Phase 7

1. **EAS Build Setup**: Generate iOS bundle ID, run `eas build --platform ios --profile preview`
2. **Performance Audit**: Profile with Expo DevTools, add `getItemLayout` to lists, memoize expensive renders
3. **RLS Verification**: Test that user A cannot query user B's saves/chat via Supabase client
4. **Accessibility**: Add `accessibilityLabel` to all icon buttons (hearts, send, etc.)
5. **Error Toast**: Add Snackbar for "Save failed" messages
6. **App Icon**: Use asset from `assets/icon.png` (custom, not Expo default)
7. **Splash Screen**: Create branded splash with `expo-splash-screen`

---

## Useful Commands

```bash
# Start development
npx expo start --clear

# Web only
npx expo start --web

# Switch to Expo Go (in terminal)
# Press 's'

# Export for web deployment
npx expo export --platform web

# EAS build
eas build --platform ios --profile preview

# Check Supabase edge function logs
docker compose logs supabase-edge-runtime | tail -20

# Restart Supabase after env changes
docker compose restart supabase-edge-runtime

# Verify env vars in edge runtime
docker exec supabase-edge-runtime env | grep ANTHROPIC
```

---

## Architecture Diagram

```
Phone/Browser (Expo App)
  └─ Zustand Stores (ephemeral state)
      ├─ userProfileStore (onboarding done?)
      ├─ restaurantStore (location + list)
      ├─ chatStore (messages)
      └─ savedStore (IDs + arrays)
  
  └─ React Query (async data + caching)
      ├─ useNearbyRestaurants → fetch-nearby-restaurants (Google Places)
      ├─ useMenuRecommendations → fetch-menu-items-ai (Claude)
      ├─ useUserProfile → get_user_profile RPC
      └─ useChat → ai-chat edge function

  └─ Supabase Client (auth + data)
      ├─ Auth: JWT session
      ├─ RPCs: toggle_save, get_saved_items, get_user_profile, etc.
      └─ Edge Functions: ai-onboard, ai-item-analysis, ai-chat, fetch-menu-items-ai

Supabase Backend (PostgreSQL + Edge Runtime)
  ├─ Tables: auth.users, user_profiles, restaurants, menu_items, saved_*, chat_messages
  ├─ RLS Policies: users can only access their own data
  └─ Edge Functions (Deno): call Claude API, Google Places API, business logic

Third-party APIs
  ├─ Claude API (claude-haiku-4-5-20251001)
  ├─ Google Places API
  ├─ Nutritionix API (backup, not active)
  └─ Expo Services (push notifications, updates)
```

---

## Migration to New Folder Checklist

When moving to `PikMe-v2/`:

1. **Copy files:**
   - [ ] `app/` folder (all screens & routing)
   - [ ] `src/` folder (components, hooks, stores, api, types, utils)
   - [ ] `supabase/` folder (migrations, edge functions)
   - [ ] `.env.local` (API keys)
   - [ ] `app.config.js` (Expo config)
   - [ ] `CONTEXT.md` (this file)

2. **Install deps:**
   ```bash
   npm install --legacy-peer-deps
   ```

3. **Verify:**
   - [ ] All packages at same SDK version (56 recommended)
   - [ ] `.env.local` has all required keys
   - [ ] Supabase migrations applied to your backend
   - [ ] Edge functions deployed to Supabase

4. **Test:**
   ```bash
   npx expo start --clear
   # Press 'w' for web, verify it loads
   ```

---

## Credits & Timeline

- **Duration:** 6 phases (Phases 1-6 complete in ~2 weeks of development)
- **Key Technologies:** Expo 56, Supabase, Claude API, React Query, Zustand
- **AI Assistance:** Claude Code (code generation, debugging, architecture)
- **Testing:** Manual testing on web + Expo Go, real location & Google Places
- **Deployment:** Ready for web (Vercel/Netlify) or mobile (EAS Build → App Store/Play Store)

---

Last Updated: June 14, 2026
