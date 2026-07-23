-- ─── 1. Upsert full user profile ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.upsert_user_profile(
  p_display_name         TEXT,
  p_dietary_restrictions TEXT[],
  p_health_goals         TEXT[],
  p_allergens            TEXT[],
  p_cuisine_preferences  TEXT[],
  p_nutrition_targets    JSONB,
  p_search_radius_meters INT,
  p_onboarding_complete  BOOLEAN
) RETURNS VOID AS $$
DECLARE v_user_id UUID := auth.uid();
BEGIN
  INSERT INTO public.user_profiles (id, display_name, search_radius_meters, onboarding_complete)
    VALUES (v_user_id, p_display_name, p_search_radius_meters, p_onboarding_complete)
    ON CONFLICT (id) DO UPDATE SET
      display_name         = EXCLUDED.display_name,
      search_radius_meters = EXCLUDED.search_radius_meters,
      onboarding_complete  = EXCLUDED.onboarding_complete,
      updated_at           = NOW();

  DELETE FROM public.user_dietary_restrictions WHERE user_id = v_user_id;
  INSERT INTO public.user_dietary_restrictions (user_id, value)
    SELECT v_user_id, unnest(p_dietary_restrictions);

  DELETE FROM public.user_health_goals WHERE user_id = v_user_id;
  INSERT INTO public.user_health_goals (user_id, value)
    SELECT v_user_id, unnest(p_health_goals);

  DELETE FROM public.user_allergens WHERE user_id = v_user_id;
  INSERT INTO public.user_allergens (user_id, allergen)
    SELECT v_user_id, unnest(p_allergens);

  DELETE FROM public.user_cuisine_preferences WHERE user_id = v_user_id;
  INSERT INTO public.user_cuisine_preferences (user_id, value)
    SELECT v_user_id, unnest(p_cuisine_preferences);

  INSERT INTO public.user_nutrition_targets (
    user_id, daily_calories, max_meal_calories, max_carbs_g,
    max_sodium_mg, min_protein_g, max_saturated_fat_g
  ) VALUES (
    v_user_id,
    (p_nutrition_targets->>'dailyCalories')::INT,
    (p_nutrition_targets->>'maxMealCalories')::INT,
    (p_nutrition_targets->>'maxCarbs_g')::INT,
    (p_nutrition_targets->>'maxSodium_mg')::INT,
    (p_nutrition_targets->>'minProtein_g')::INT,
    (p_nutrition_targets->>'maxSaturatedFat_g')::INT
  )
  ON CONFLICT (user_id) DO UPDATE SET
    daily_calories      = EXCLUDED.daily_calories,
    max_meal_calories   = EXCLUDED.max_meal_calories,
    max_carbs_g         = EXCLUDED.max_carbs_g,
    max_sodium_mg       = EXCLUDED.max_sodium_mg,
    min_protein_g       = EXCLUDED.min_protein_g,
    max_saturated_fat_g = EXCLUDED.max_saturated_fat_g;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 2. Get full user profile ─────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_user_profile()
RETURNS JSONB AS $$
DECLARE v_user_id UUID := auth.uid();
BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'id',                   p.id,
      'displayName',          p.display_name,
      'searchRadiusMeters',   p.search_radius_meters,
      'onboardingComplete',   p.onboarding_complete,
      'dietaryRestrictions',  COALESCE((SELECT jsonb_agg(value) FROM public.user_dietary_restrictions WHERE user_id = v_user_id), '[]'),
      'healthGoals',          COALESCE((SELECT jsonb_agg(value) FROM public.user_health_goals WHERE user_id = v_user_id), '[]'),
      'allergens',            COALESCE((SELECT jsonb_agg(allergen) FROM public.user_allergens WHERE user_id = v_user_id), '[]'),
      'cuisinePreferences',   COALESCE((SELECT jsonb_agg(value) FROM public.user_cuisine_preferences WHERE user_id = v_user_id), '[]'),
      'nutritionTargets',     COALESCE((SELECT row_to_json(t) FROM public.user_nutrition_targets t WHERE user_id = v_user_id), '{}')
    )
    FROM public.user_profiles p WHERE p.id = v_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 3. Bulk upsert restaurants ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.upsert_restaurants(p_restaurants JSONB)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.restaurants (
    place_id, name, latitude, longitude, address, city,
    rating, price_level, cuisine_types, photo_reference, opening_hours, open_now, cached_at
  )
  SELECT
    r->>'placeId', r->>'name',
    (r->>'latitude')::DOUBLE PRECISION, (r->>'longitude')::DOUBLE PRECISION,
    r->>'address', r->>'city',
    (r->>'rating')::NUMERIC, (r->>'priceLevel')::SMALLINT,
    ARRAY(SELECT jsonb_array_elements_text(r->'cuisineTypes')),
    r->>'photoReference', r->'openingHours', (r->>'openNow')::BOOLEAN, NOW()
  FROM jsonb_array_elements(p_restaurants) AS r
  ON CONFLICT (place_id) DO UPDATE SET
    rating         = EXCLUDED.rating,
    opening_hours  = EXCLUDED.opening_hours,
    open_now       = EXCLUDED.open_now,
    cached_at      = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 4. Bulk upsert menu items ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.upsert_menu_items(p_items JSONB)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.menu_items (
    item_id, restaurant_name, name, serving_weight_grams,
    calories, total_fat_g, saturated_fat_g, sodium_mg,
    total_carbs_g, protein_g, image_url, is_verified, cached_at
  )
  SELECT
    i->>'itemId', i->>'restaurantName', i->>'name',
    (i->>'servingWeightGrams')::NUMERIC,
    (i->>'calories')::INT, (i->>'totalFat_g')::NUMERIC,
    (i->>'saturatedFat_g')::NUMERIC, (i->>'sodium_mg')::INT,
    (i->>'totalCarbs_g')::NUMERIC, (i->>'protein_g')::NUMERIC,
    i->>'imageUrl', (i->>'isVerified')::BOOLEAN, NOW()
  FROM jsonb_array_elements(p_items) AS i
  ON CONFLICT (item_id) DO UPDATE SET cached_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 5. Filter menu items by user hard constraints ────────────────────────────
DROP FUNCTION IF EXISTS public.filter_menu_items_for_user(TEXT[]);
CREATE OR REPLACE FUNCTION public.filter_menu_items_for_user(p_item_ids TEXT[])
RETURNS TABLE (item_id TEXT) AS $$
DECLARE
  v_user_id    UUID := auth.uid();
  v_restrictions TEXT[];
  v_allergens  TEXT[];
  v_max_cal    INT;
BEGIN
  SELECT ARRAY(SELECT value FROM public.user_dietary_restrictions WHERE user_id = v_user_id)
    INTO v_restrictions;
  SELECT ARRAY(SELECT allergen FROM public.user_allergens WHERE user_id = v_user_id)
    INTO v_allergens;
  SELECT max_meal_calories * 1.5 FROM public.user_nutrition_targets WHERE user_id = v_user_id
    INTO v_max_cal;

  RETURN QUERY
  SELECT m.item_id FROM public.menu_items m
  WHERE m.item_id = ANY(p_item_ids)
    AND (v_max_cal IS NULL OR m.calories <= v_max_cal)
    AND NOT EXISTS (
      SELECT 1 FROM unnest(v_allergens) AS a
      WHERE lower(m.name) LIKE '%' || lower(a) || '%'
    )
    AND (NOT ('vegan' = ANY(v_restrictions)) OR
         NOT (lower(m.name) ~ 'chicken|beef|pork|fish|shrimp|turkey|bacon|ham|lamb|dairy|cheese|butter|milk|egg'))
    AND (NOT ('vegetarian' = ANY(v_restrictions)) OR
         NOT (lower(m.name) ~ 'chicken|beef|pork|fish|shrimp|turkey|bacon|ham|lamb'))
    AND (NOT ('gluten_free' = ANY(v_restrictions)) OR
         NOT (lower(m.name) ~ 'bread|pasta|bun|wrap|tortilla|wheat|flour|sandwich|sub|burger'))
    AND (NOT ('halal' = ANY(v_restrictions)) OR
         NOT (lower(m.name) ~ 'pork|bacon|ham|lard'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 6. Toggle saved restaurant ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.toggle_saved_restaurant(p_place_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE v_user_id UUID := auth.uid();
BEGIN
  IF EXISTS (SELECT 1 FROM public.saved_restaurants WHERE user_id = v_user_id AND place_id = p_place_id) THEN
    DELETE FROM public.saved_restaurants WHERE user_id = v_user_id AND place_id = p_place_id;
    RETURN FALSE;
  ELSE
    INSERT INTO public.saved_restaurants (user_id, place_id) VALUES (v_user_id, p_place_id);
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 7. Toggle saved menu item ────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.toggle_saved_menu_item(TEXT);
CREATE OR REPLACE FUNCTION public.toggle_saved_menu_item(p_item_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE v_user_id UUID := auth.uid();
BEGIN
  IF EXISTS (SELECT 1 FROM public.saved_menu_items WHERE user_id = v_user_id AND item_id = p_item_id) THEN
    DELETE FROM public.saved_menu_items WHERE user_id = v_user_id AND item_id = p_item_id;
    RETURN FALSE;
  ELSE
    INSERT INTO public.saved_menu_items (user_id, item_id) VALUES (v_user_id, p_item_id);
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 8. Get saved items ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_saved_items()
RETURNS JSONB AS $$
DECLARE v_user_id UUID := auth.uid();
BEGIN
  RETURN jsonb_build_object(
    'restaurants', COALESCE(
      (SELECT jsonb_agg(row_to_json(r.*) ORDER BY sr.saved_at DESC)
       FROM public.saved_restaurants sr
       LEFT JOIN public.restaurants r ON r.place_id = sr.place_id
       WHERE sr.user_id = v_user_id),
      '[]'::JSONB
    ),
    'menuItems', COALESCE(
      (SELECT jsonb_agg(row_to_json(m.*) ORDER BY sm.saved_at DESC)
       FROM public.saved_menu_items sm
       LEFT JOIN public.menu_items m ON m.item_id = sm.item_id
       WHERE sm.user_id = v_user_id),
      '[]'::JSONB
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 9. Append chat message (returns last 20 for GPT context) ─────────────────
CREATE OR REPLACE FUNCTION public.append_chat_message(p_role TEXT, p_content TEXT)
RETURNS JSONB AS $$
DECLARE v_user_id UUID := auth.uid();
BEGIN
  INSERT INTO public.chat_messages (user_id, role, content) VALUES (v_user_id, p_role, p_content);
  RETURN (
    SELECT jsonb_agg(msg ORDER BY msg->>'created_at')
    FROM (
      SELECT jsonb_build_object('role', role, 'content', content, 'created_at', created_at) AS msg
      FROM public.chat_messages
      WHERE user_id = v_user_id
      ORDER BY created_at DESC
      LIMIT 20
    ) recent
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 10. Log recommendation action ───────────────────────────────────────────
DROP FUNCTION IF EXISTS public.log_recommendation_action(TEXT, TEXT, SMALLINT, TEXT);
CREATE OR REPLACE FUNCTION public.log_recommendation_action(
  p_place_id    TEXT,
  p_item_id TEXT,
  p_score       SMALLINT,
  p_action      TEXT
) RETURNS VOID AS $$
BEGIN
  INSERT INTO public.recommendation_logs (user_id, place_id, item_id, score, action)
  VALUES (auth.uid(), p_place_id, p_item_id, p_score, p_action);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 11. Get / set item health analysis ──────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_item_analysis(TEXT);
CREATE OR REPLACE FUNCTION public.get_item_analysis(p_item_id TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT summary_text FROM public.item_health_analysis
    WHERE item_health_analysis.item_id = p_item_id
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

DROP FUNCTION IF EXISTS public.set_item_analysis(TEXT, TEXT);
CREATE OR REPLACE FUNCTION public.set_item_analysis(p_item_id TEXT, p_summary TEXT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.item_health_analysis (item_id, summary_text)
  VALUES (p_item_id, p_summary)
  ON CONFLICT (item_id) DO UPDATE SET summary_text = EXCLUDED.summary_text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
