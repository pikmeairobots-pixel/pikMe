import { create } from 'zustand';
import type { Restaurant } from '../types';

interface Coords {
  latitude: number;
  longitude: number;
}

interface RestaurantStore {
  restaurants: Restaurant[];
  selectedRestaurantId: string | null;
  userLocation: Coords | null;
  setRestaurants: (restaurants: Restaurant[]) => void;
  setSelectedRestaurantId: (id: string | null) => void;
  setUserLocation: (loc: Coords | null) => void;
}

export const useRestaurantStore = create<RestaurantStore>((set) => ({
  restaurants: [],
  selectedRestaurantId: null,
  userLocation: null,
  setRestaurants: (restaurants) => set({ restaurants }),
  setSelectedRestaurantId: (id) => set({ selectedRestaurantId: id }),
  setUserLocation: (userLocation) => set({ userLocation }),
}));
