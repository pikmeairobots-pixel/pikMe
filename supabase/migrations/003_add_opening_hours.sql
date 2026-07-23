-- Add opening hours to restaurants table
ALTER TABLE public.restaurants
ADD COLUMN opening_hours JSONB,
ADD COLUMN open_now BOOLEAN DEFAULT false;

-- opening_hours structure from Google Places:
-- {
--   "open_now": boolean,
--   "periods": [...],
--   "weekday_text": ["Monday: 10:00 AM – 11:00 PM", ...]
-- }
