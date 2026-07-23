import { useQuery } from '@tanstack/react-query';
import { fetchNearbyRestaurants } from '../api/functions';
import { useRestaurantStore } from '../store/restaurantStore';
import { snapToGrid } from '../utils/geo';
import type { Coords } from './useLocation';

export function useNearbyRestaurants(location: Coords | null, radiusMeters = 2000) {
  const setRestaurants = useRestaurantStore((s) => s.setRestaurants);

  // Snap to ~200m grid so minor GPS drift doesn't trigger new fetches
  const snappedLat = location ? snapToGrid(location.latitude) : null;
  const snappedLng = location ? snapToGrid(location.longitude) : null;

  return useQuery({
    queryKey: ['nearbyRestaurants', snappedLat, snappedLng, radiusMeters],
    queryFn: async () => {
      try {
        const restaurants = await fetchNearbyRestaurants(
          location!.latitude,
          location!.longitude,
          radiusMeters
        );
        setRestaurants(restaurants);
        return restaurants;
      } catch (err: any) {
        console.error('[PikMe] fetchNearbyRestaurants failed:', {
          message: err?.message,
          context: err?.context,
          status: err?.status,
          details: err,
        });
        throw err;
      }
    },
    enabled: !!location,
    staleTime: 5 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
  });
}
