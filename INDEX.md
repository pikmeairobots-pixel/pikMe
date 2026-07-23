# PikMe Project Index — Complete Context Recovery

This file serves as the **master index** for reconstructing full context if conversation history is lost.

---

## 📚 Documentation Files (Read in This Order)

### 1. **GUARDRAILS.md** ← START HERE
   - Core project rules (no changes without written consent)
   - Security model (backend-only API keys)
   - Architecture overview
   - Current status (Phases 1-6 complete, Phase 7 pending)
   - Self-hosted Supabase at `http://srv1747781.hstgr.cloud:8000`

### 2. **CONTEXT.md** ← COMPREHENSIVE REFERENCE
   - Complete tech stack & versions
   - Project structure (file organization)
   - All 6 implemented phases (with key files listed)
   - Environment setup (.env.local keys)
   - Known issues & fixes (troubleshooting guide)
   - Testing checklist for Phase 6
   - Architecture diagram
   - Migration checklist (if moving to new folder)

### 3. **ARCHITECTURE.md** ← DESIGN DECISIONS
   - 10 major architectural decisions with tradeoffs
   - Examples: photo URL generation, AI menu items, caching strategy
   - Data flow diagrams (3 key examples)
   - Performance metrics & token usage analysis
   - Database schema highlights
   - Future improvements roadmap

### 4. **PLAN.md** ← ORIGINAL BLUEPRINT
   - Tech stack rationale
   - Folder structure (Expo scaffold)
   - Core data models (TypeScript interfaces)
   - Database schema overview
   - Edge Functions (6 total)
   - Recommendation engine details
   - Implementation phases (timeline)
   - Critical files list

### 5. **AGENTS.md** ← DEVELOPMENT NOTES
   - Reminder: Read Expo docs at `https://docs.expo.dev/versions/v56.0.0/`
   - Expo SDK 56 is locked (don't upgrade without consent)

### 6. **TEST_GUIDE.md** ← TESTING STRATEGY
   - Jest test setup
   - Integration tests for Edge Functions
   - Manual testing on web + phone

---

## 🎯 Key Facts At a Glance

| Aspect | Value |
|--------|-------|
| **Framework** | Expo (React Native) SDK 56 + TypeScript |
| **Backend** | Supabase (self-hosted at http://srv1747781.hstgr.cloud:8000) |
| **LLM** | Claude (claude-haiku-4-5-20251001) + optional Quicksilver fallback |
| **Database** | PostgreSQL with RLS policies |
| **Auth** | Supabase JWT |
| **State** | Zustand (client) + Supabase (server) + React Query (cache) |
| **Build Status** | Phases 1-6 complete, Phase 7 (Production Prep) pending |
| **User Email** | vvallurupalli@gmail.com |
| **Location** | c:\Users\User\000000\vv\code\PikMe-expo |

---

## 🔑 Critical Files (If Only Reading 6 Files)

1. `GUARDRAILS.md` — Rules & security
2. `CONTEXT.md` — Everything (phases, structure, issues)
3. `ARCHITECTURE.md` — Design decisions
4. `src/types/index.ts` — All TypeScript interfaces
5. `src/api/functions.ts` — All API calls
6. `supabase/functions/*/index.ts` — Edge Function implementations

---

## 📋 Current Project Status

### Completed ✅
- **Phase 1:** Auth & Onboarding
- **Phase 2:** Location & Restaurant Discovery
- **Phase 3:** Menu Fetching & Caching (AI-generated items)
- **Phase 4:** Recommendation Scoring & Ranking
- **Phase 5:** AI Features (analysis, chat, profile extraction)
- **Phase 6:** Polish & UX (saves, skeleton loaders, error boundaries)
- **Recent:** Photo URL generation moved to backend, enhanced logging, keyword filtering

### In Progress ⏳
- **Phase 7:** Production Prep
  - [ ] EAS Build configuration
  - [ ] RLS audit
  - [ ] Performance optimization
  - [ ] Accessibility improvements
  - [ ] Error toast/snackbar
  - [ ] Custom app icon & splash

---

## 🏗️ Architecture Summary

```
Frontend (Expo App) → Supabase Client (JWT auth) → Backend (Edge Functions)
   ↓                        ↓                              ↓
Zustand Stores          React Query Cache          Claude API calls
(ephemeral)             (restaurants, items)       Google Places API
                        RLS-protected data         Anthropic API
```

### Data Flow
1. **User Opens App** → GPS location → `fetch-nearby-restaurants` Edge Function → Google Places API → Caches restaurants → Display on map
2. **User Taps Restaurant** → `fetch-menu-items-ai` Edge Function → Claude generates 15 menu items → Cache 30 days → Client scores & ranks by user profile
3. **User Clicks "Should I get this?"** → `ai-item-analysis` Edge Function → Claude 2-sentence analysis → Cache forever (shared)

### Security Model
- **Public (safe to expose):** `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_ANON_KEY` (RLS protects)
- **Private (backend only):** `ANTHROPIC_API_KEY`, `GOOGLE_PLACES_KEY` (Supabase Secrets)
- **Client never sees:** Google API keys, sensitive API keys, other users' data

---

## 🌐 External Services

| Service | Purpose | Credential | Location |
|---------|---------|-----------|----------|
| **Claude API** | Menu generation, analysis, chat | ANTHROPIC_API_KEY | Supabase Secrets |
| **Google Places API** | Nearby search, photos | GOOGLE_PLACES_KEY | Supabase Secrets |
| **Supabase** | Database, Auth, Edge Functions | EXPO_PUBLIC_SUPABASE_ANON_KEY | .env.local |
| **Quicksilver (optional)** | LLM fallback (DeepSeek) | QUICKSILVER_API_KEY | Supabase Secrets |
| **Nutritionix API** | Menu data backup (unused) | Keys in Supabase | Not active |

---

## 📝 Recent Changes (Session Context)

### June 17-18, 2026
1. **Photo URL Generation** — Moved from client to Edge Function (`fetch-nearby-restaurants`)
   - Client no longer needs Google Maps API key
   - `photoUrl` (full URL) generated server-side
   - Database still caches `photoReference` for rebuilding
   - See: ARCHITECTURE.md section 1

2. **Enhanced Logging** — Added `[ai-request]` labels to LLM logging
   - `ai-item-analysis/index.ts` — logs prompt + response + token usage
   - `fetch-menu-items-ai/index.ts` — logs prompt + generated items
   - Keyword: search logs for `[ai-request]` to see LLM prompts
   - See: ARCHITECTURE.md section 10

3. **Keyword Filtering** — Added color-coded filters (Veg, Fish, Chicken, Beef, Pork, Ham)
   - Multi-select, works with text search
   - Client-side, instant filtering
   - See: `app/restaurant/[id].tsx` lines 51-79

4. **TypeScript Fixes** — Removed `photoReference` references from `src/api/functions.ts`
   - Line 148: `mapDbRestaurant()` now uses `photoUrl` instead
   - Line 192: `toggleSavedRestaurant()` no longer references `photoReference`
   - No database migration needed (schema unchanged)

---

## 🔄 Development Workflow

### Before Making Changes
1. Read GUARDRAILS.md (no changes without written consent)
2. Check git status (`git status`)
3. Read relevant .md files for context

### Running the App
```bash
# Install
npm install --legacy-peer-deps

# Start dev server (Windows PowerShell)
$env:NODE_OPTIONS = "--openssl-legacy-provider"
npx expo start --clear

# Web: press 'w'
# Expo Go: press 's'
```

### Deploying Edge Functions
```bash
# Deploy all
supabase functions deploy

# Deploy specific
supabase functions deploy fetch-menu-items-ai
supabase functions deploy ai-item-analysis
supabase functions deploy fetch-nearby-restaurants
```

### Checking Logs
```bash
# View Edge Function logs
supabase functions logs fetch-menu-items-ai --tail

# Search for LLM requests
# Look for: [ai-request]
```

---

## 🧪 Testing

### Manual Testing Checklist
- [ ] Sign up & complete onboarding
- [ ] Location permission granted → nearby restaurants load with photos
- [ ] Tap restaurant → menu items load & rank by score
- [ ] Click "Should I get this?" → 2-sentence analysis appears
- [ ] Heart button → save/unsave works
- [ ] Saved tab → can view & remove saved items
- [ ] Search & filter → find items by name/keyword
- [ ] Chat tab → type question → get response
- [ ] Error handling → intentional error → fallback UI appears

### Integration Tests
- See TEST_GUIDE.md for Jest/integration test setup
- Run: `npm test`

---

## 🚀 Edge Functions

All located in `supabase/functions/`. Deployed via `supabase functions deploy`.

| Function | Purpose | LLM? | Logs? |
|----------|---------|------|-------|
| `fetch-nearby-restaurants` | Google Places API | ❌ | ✅ (photocopy generation) |
| `fetch-menu-items-ai` | Claude generates 15 menu items | ✅ Claude | ✅ [ai-request] label |
| `ai-item-analysis` | Claude: "Should I get this?" | ✅ Claude | ✅ [ai-request] label |
| `ai-chat` | Claude chat assistant | ✅ Claude | ✅ |
| `ai-onboard` | Extract profile from free text | ✅ Claude | ✅ |
| `ai-recommend` | (Not used, client-side scoring) | ✅ Claude | N/A |

---

## 💾 Database Schema (Key Tables)

| Table | Purpose | RLS | Cached |
|-------|---------|-----|--------|
| `auth.users` | Supabase auth | Built-in | N/A |
| `user_profiles` | User goals, restrictions | Per-user | Client |
| `restaurants` | Cached from Google Places | None | 7 days |
| `menu_items` | AI-generated or from Nutritionix | None | 30 days |
| `item_analysis` | Claude "Should I get?" summary | None | Forever |
| `saved_restaurants` | User's saved restaurants | Per-user | Client |
| `saved_menu_items` | User's saved menu items | Per-user | Client |
| `chat_messages` | User's chat history | Per-user | Client |

---

## 🔐 Security Checklist

- ✅ Google API key: Backend only (Edge Function secrets)
- ✅ Claude API key: Backend only (Edge Function secrets)
- ✅ Supabase anon key: Public, RLS-protected
- ✅ User auth: JWT via Supabase
- ✅ User data: RLS policies per table
- ⚠️ Phase 7 TODO: RLS audit for cross-user data leaks

---

## 📊 Performance Metrics

| Operation | Time | Cache | Notes |
|-----------|------|-------|-------|
| Fetch restaurants | 1-2s | 5 min (RQ), 7 days (DB) | Cold ~2s, warm <100ms |
| Fetch menu items | 3-5s | 30 days (DB) | LLM call if not cached |
| Analyze item | 2-3s | Forever | Shared across users |
| Render 15 items | <100ms | N/A | Client-side only |

---

## 🛠️ Common Tasks

### Add a New Feature
1. Read GUARDRAILS.md, ask for consent
2. Update ARCHITECTURE.md with decision
3. Implement in code
4. Test manually
5. Update CONTEXT.md if structural change

### Fix a Bug
1. Check CONTEXT.md "Known Issues" section
2. Look at git blame/log for context
3. Implement fix
4. Test
5. Document in issue/PR

### Deploy to Production (Phase 7)
1. Run full test suite
2. Deploy Edge Functions: `supabase functions deploy`
3. Build with EAS: `eas build --platform ios --profile preview`
4. Verify RLS policies
5. Test on real device

### Check Logs
```bash
# Edge Function logs
supabase functions logs fetch-menu-items-ai --tail

# Search for specific requests
# Look for [ai-request] to see LLM prompts
```

---

## 🎓 Learning Resources

- **Expo Docs:** https://docs.expo.dev/versions/v56.0.0/
- **Supabase Docs:** https://supabase.com/docs
- **React Query Docs:** https://tanstack.com/query/latest
- **Zustand Docs:** https://github.com/pmndrs/zustand

---

## 📞 Contact & Support

- **User:** vvallurupalli@gmail.com
- **Supabase:** Self-hosted at http://srv1747781.hstgr.cloud:8000
- **Dev:** C:\Users\User\000000\vv\code\PikMe-expo

---

## 🔗 Related Memory Files

Auto-memory stored at: `C:\Users\User\.claude\projects\c--Users-User-000000-vv-code-PikMe-expo\memory\`

- `project_pikme.md` — Project status & phases
- (May contain user preferences & feedback)

---

**Last Updated:** June 18, 2026  
**Expo SDK:** v56  
**Status:** Phases 1-6 complete, Phase 7 in progress

---

## ✅ How to Use This File

1. **Lost all context?** Read in this order: GUARDRAILS → CONTEXT → ARCHITECTURE → PLAN
2. **Need quick facts?** Jump to "Key Facts At a Glance"
3. **Want to change something?** Check GUARDRAILS first (consent needed)
4. **Debugging issue?** See CONTEXT.md "Known Issues & Fixes"
5. **Viewing logs?** Search for `[ai-request]` in Edge Function logs
6. **Deploying?** Follow "Deploying Edge Functions" section
