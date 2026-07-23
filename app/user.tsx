import { useEffect } from 'react';
import { useRouter } from 'expo-router';
import { useRestaurantOwnerStore } from '../src/store/restaurantOwnerStore';

export default function UserScreen() {
  const router = useRouter();
  const logout = useRestaurantOwnerStore(state => state.logout);

  useEffect(() => {
    console.log('[/user] Page loaded');
    console.log('[/user] Logging out restaurant owner...');

    // Call logout (which handles supabase.auth.signOut safely)
    logout().catch((err) => {
      console.log('[/user] Logout error (expected if not authenticated):', err?.message);
    });

    console.log('[/user] Redirecting to /sign-in');
    router.replace('/sign-in');
    console.log('[/user] Router.replace called');
  }, []);

  return null;
}
