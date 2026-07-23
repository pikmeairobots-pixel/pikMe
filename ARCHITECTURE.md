# PikMe Architecture & Design Decisions

## System Overview

**PikMe** is a personalized food recommendation app built on:
- **Frontend:** Expo (React Native) + Expo Router
- **Backend:** Supabase (PostgreSQL + Edge Functions + Auth)
- **LLM:** Claude (Anthropic) or Quicksilver (DeepSeek)
- **APIs:** Google Places (nearby search), Anthropic, Optional Quicksilver
- **State:** Zustand (client) + Supabase (server)

---

## Key Architectural Decisions

### 1. **Photo URL Generation: Backend Only** ✅
**Decision:** Generate full photo URLs server-side (Edge Function), NOT client-side.

**Why:**
- Google Maps API key stays in Supabase Secrets (backend-only)
- Client never has access to sensitive API keys
- Prevents accidental key exposure in client code/logs
- More secure for production

**Implementation:**
- `fetch-nearby-restaurants` Edge Function:
  - Receives `photoReference` from Google Places API
  - Builds full URL: `https://maps.googleapis.com/maps/api/place/photo?maxwidth=600&photoreference=...&key=...`
  - Returns `photoUrl` (full URL) to client
  - Caches `photoReference` in database for rebuilding

**Related Files:**
- `supabase/functions/fetch-nearby-restaurants/index.ts` (line 82-84)
- `src/types/index.ts` (Restaurant interface uses `photoUrl`, not `photoReference`)
- `src/components/restaurant/RestaurantCard.tsx` (uses `photoUrl` directly)

---

### 2. **AI-Generated Menu Items** 🤖
**Decision:** Use Claude/Quicksilver LLM to **generate realistic menu items** rather than fetching from a fixed database.

**Why:**
- No dependency on restaurant-specific menu data sources (Nutritionix, etc.)
- Works for ANY restaurant, chain or independent
- LLM can invent realistic menu items with plausible nutrition data
- Cached for 30 days to reduce API calls

**Implementation:**
- `fetch-menu-items-ai` Edge Function:
  - Takes restaurant name → prompts Claude: "Generate 15 realistic menu items for {restaurant}"
  - Claude returns JSON: `[{ name: "...", calories: X, protein_g: Y, ... }]`
  - Parsed and cached in `menu_items` table
  - 30-day cache hits reduce LLM calls significantly

**Tradeoff:** Menu items are AI-generated, not real. Nutrition data is approximate.

**Related Files:**
- `supabase/functions/fetch-menu-items-ai/index.ts` (line 93-108)
- `src/hooks/useMenuRecommendations.ts` (calls `fetchMenuItemsAi`)

---

### 3. **Two-Stage Menu Analysis** 📊
**Stage 1: Generate Items**
- `fetch-menu-items-ai` → creates 15 realistic items + basic nutrition

**Stage 2: Analyze & Rank**
- `scoreAndRankItems()` (client-side) → ranks by user profile
- `ai-item-analysis` Edge Function → "Should I get this?" analysis (on-demand)

**Why:**
- First stage is fast (cached)
- Second stage is lazy (only when user clicks "Should I get this?")
- Reduces token usage

**Related Files:**
- `src/engine/recommendation.ts` (scoring logic)
- `supabase/functions/ai-item-analysis/index.ts` (Claude analysis)

---

### 4. **LLM Provider Flexibility** 🔄
**Decision:** Support both Claude and Quicksilver (DeepSeek) as interchangeable providers.

**Configuration:**
```
AI_PROVIDER=claude  or  quicksilver
CLAUDE_MODEL=claude-haiku-4-5-20251001
QUICKSILVER_MODEL=deepseek-v4-flash
```

**Why:**
- Redundancy: if one provider fails, switch to the other
- Cost optimization: compare token usage & pricing
- No code changes needed to switch

**Related Files:**
- `supabase/functions/fetch-menu-items-ai/index.ts` (line 59-71)
- `supabase/functions/ai-item-analysis/index.ts` (line 21-42)

---

### 5. **Caching Strategy** 💾

| Data | Cache Location | Duration | Why |
|------|---|---|---|
| Restaurant (nearby search) | Database + React Query | On-demand | Latest info needed (7 days DB, 5 min React Query) |
| Menu items | Database | 30 days | AI-generated, rarely changes |
| Item analysis ("Should I get this?") | Database | Forever | Same analysis for same item across users |
| Photos | None (URL only) | N/A | URLs are cheap to regenerate |

**Related Files:**
- `src/hooks/useMenuRecommendations.ts` (React Query cache: 10 min stale, 20 min garbage collect)
- `supabase/functions/fetch-menu-items-ai/index.ts` (line 78-90, 30-day DB cache)
- `src/api/functions.ts` (React Query configuration)

---

### 6. **State Management** 🎯

**Client State (Zustand):**
- `userProfileStore` — user profile (goals, restrictions, allergens)
- `restaurantStore` — restaurants list
- `savedStore` — saved restaurants & menu items

**Server State (Supabase):**
- `auth_users` — authentication
- `user_profiles` — user goals/restrictions (RLS protected)
- `restaurants` — cached restaurant data
- `menu_items` — cached AI-generated menu items
- `item_analysis` — cached "Should I get this?" analysis
- `saved_restaurants` — user's saved restaurants (RLS protected)

**Why split:**
- Client state: fast, optimistic UI, offline capability
- Server state: persistent, shared (analysis), RLS-protected (user data)

---

### 7. **API Key Security** 🔒

**Backend Only (Supabase Secrets):**
- `ANTHROPIC_API_KEY` — Claude API
- `GOOGLE_PLACES_KEY` — Google Places API
- `QUICKSILVER_API_KEY` — Quicksilver (DeepSeek)

**Public (Client Safe):**
- `EXPO_PUBLIC_SUPABASE_URL` — public Supabase endpoint
- `EXPO_PUBLIC_SUPABASE_ANON_KEY` — Supabase anon key (RLS enforces access control)

**NOT Used by Client:**
- ❌ Google Maps API key (server-side only)
- ❌ Anthropic API key (server-side only)

**Related Files:**
- `.env.local` (lists which keys are backend-only)
- `GUARDRAILS.md` (security rules)

---

### 8. **Microinteractions & Animations** ✨
**Tech:** React Native Reanimated 4.3.1 + expo-haptics

**Features:**
- Button press scale animations (0.95x)
- Skeleton loading with shimmer
- Swipe gestures with spring snaps
- Haptic feedback (Medium on buttons, Light on saves)

**Why:**
- Modern, delightful UX
- 60fps animations (Reanimated is optimized)
- Haptics provide tactile feedback

**Related Files:**
- `src/components/menu/MenuItemCardSwipeable.tsx` (gestures)
- `src/components/menu/MenuItemSkeleton.tsx` (shimmer)
- `src/components/menu/MenuItemCard.tsx` (button animations + haptics)

---

### 9. **Search & Filtering** 🔍

**Search:**
- Text-based search on menu item names (client-side, instant)

**Filters:**
- Keyword-based (Veg, Fish, Chicken, Beef, Pork, Ham)
- Multi-select, color-coded
- Combined with search (AND logic)

**Why Client-Side:**
- Fast, no API calls
- Works with React Query cached data
- Instant feedback

**Related Files:**
- `app/restaurant/[id].tsx` (line 51-79, filter logic)

---

### 10. **Error Handling & Logging** 📋

**Edge Function Logging:**
- Prefix: `[function-name]` for easy filtering
- Request logging: `[ai-request]` label for LLM prompts
- Response logging: Full response + token usage (Claude)
- Timestamps: Built into Supabase logs

**Example:**
```
[fetch-menu-items-ai] ========== START ==========
[fetch-menu-items-ai] Fetching menu for: Subway
[fetch-menu-items-ai] [ai-request] You are a personalized food...
[fetch-menu-items-ai] Claude usage - input: 245 output: 856
[fetch-menu-items-ai] Generated 15 items
[fetch-menu-items-ai] ========== END ==========
```

**Client Error Handling:**
- Try/catch in React Query
- Error boundaries for UI crashes
- User-friendly error messages

**Related Files:**
- `supabase/functions/*/index.ts` (all Edge Functions)
- `src/components/common/ErrorBoundary.tsx`

---

## Data Flow Examples

### Example 1: User Opens App → Sees Restaurants

```
User Location (GPS)
    ↓
useLocation Hook
    ↓
REST API call to fetch-nearby-restaurants Edge Function
    ↓
fetch-nearby-restaurants:
  - Calls Google Places Nearby Search API
  - Generates photoUrl for each restaurant
  - Caches in database
  - Returns to client
    ↓
restaurantStore (Zustand)
    ↓
RestaurantCard components render with photos
```

### Example 2: User Taps Restaurant → Sees Menu

```
User taps restaurant
    ↓
useMenuRecommendations Hook
    ↓
React Query calls fetchMenuItemsAi()
    ↓
fetch-menu-items-ai Edge Function:
  - Check 30-day cache in DB
  - If miss: Call Claude LLM with restaurant name
  - Parse JSON response
  - Cache in DB
  - Return items
    ↓
scoreAndRankItems() (client-side)
    ↓
MenuItemCardSwipeable components render
```

### Example 3: User Clicks "Should I get this?" Button

```
User clicks button
    ↓
getItemAnalysis() API call
    ↓
ai-item-analysis Edge Function:
  - Check item_analysis cache
  - If miss: Call Claude with item + user profile
  - Claude returns 2-sentence analysis
  - Cache in DB (shared across users)
  - Return to client
    ↓
Show analysis modal with color-coded background (green=yes, red=no)
```

---

## Performance Considerations

| Operation | Time | Cached | Notes |
|-----------|------|--------|-------|
| Fetch restaurants | 1-2s | 5 min (RQ), 7 days (DB) | Cold: ~2s, Warm: <100ms |
| Fetch menu items | 3-5s | 30 days (DB) | Cold: LLM call, Warm: <100ms |
| Analyze item | 2-3s | Forever (DB) | Cold: LLM call, Warm: <10ms |
| Render 15 items | <100ms | N/A | Local scoring only |
| Swipe gesture | 60fps | N/A | Reanimated optimized |

---

## Token Usage (Claude)

### fetch-menu-items-ai
- **Input:** ~245 tokens (prompt + instruction)
- **Output:** ~850 tokens (15 items × ~56 tokens each)
- **Per Restaurant:** 1,095 tokens
- **Cached:** 30 days (significant savings)

### ai-item-analysis
- **Input:** ~150 tokens (prompt + nutrition data)
- **Output:** ~28 tokens (2 sentences)
- **Per Item:** 178 tokens
- **Cached:** Forever (shared across users)

---

## Database Schema Highlights

**menu_items**
- `item_id` — unique item ID (AI-generated for AI items)
- `restaurant_name` — source restaurant
- `name, calories, protein_g, ...` — nutrition data
- `is_verified` — false for AI-generated, true for real data
- `cached_at` — when cached (used for TTL checks)

**item_analysis**
- `item_id` — which item
- `summary` — "Should I get this?" analysis (2 sentences)
- `cached_at` — cached at timestamp

**saved_restaurants / saved_menu_items**
- User-specific, RLS protected

---

## Future Improvements

1. **Real Menu Data:** Integrate Nutritionix API as fallback
2. **Photos Sync:** Cache generated photo URLs in DB to avoid regeneration
3. **Batch Analysis:** Analyze multiple items in one API call (reduce token usage)
4. **User Feedback:** Train LLM on which recommendations users liked
5. **Offline Support:** Sync restaurants locally for offline browsing
6. **Multi-language:** Translate prompts and responses

---

## Related Documentation

- **GUARDRAILS.md** — Rules & security constraints
- **CLAUDE.md** → **AGENTS.md** — Development guidelines
- **TEST_GUIDE.md** — Testing strategies
- **PLAN.md** — Implementation timeline

---

**Last Updated:** June 18, 2026  
**Expo SDK:** v56  
**Backend:** Supabase (self-hosted)
