# PikMe — Guardrails

## Core Rule
**🛑 No changes or implementations without explicit written consent.**
- Read-only analysis, questions, and explanations are always OK
- Any code change, file modification, or feature implementation requires explicit "go ahead" or similar approval
- This includes: edits, refactors, bug fixes, new files, dependency updates, migrations

---

## Code Changes
- **Always ask before modifying** existing code or creating new files
- **Always ask before running** `npm install`, migrations, or commands that affect state
- **Never force push** or use destructive git operations without confirmation

---

## Security
- Keep `ANTHROPIC_API_KEY` and other secrets **server-side only** (Supabase Edge Functions)
- `EXPO_PUBLIC_*` keys are meant to be public, protected by RLS
- Restrict API keys in provider consoles (Google Cloud, etc.)

---

## Architecture
- Location: Device GPS via `expo-location` (web falls back to browser geolocation)
- External APIs (Claude, Google Places): Called via Supabase Edge Functions
- Database: RLS protects user data — users can only see their own data
- Frontend: Does NOT call Claude API directly (goes through edge functions)

---

## Status
- Phases 1–6: ✅ Complete
- Phase 7 (Production Prep): ⏳ Pending
- Current SDK: Expo v56
- Running on: Self-hosted Supabase at `http://srv1747781.hstgr.cloud:8000`

---

Last updated: June 15, 2026
