import { useState, useEffect } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet, FlatList,
  ActivityIndicator, Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { claimRestaurant, getRestaurantForOwner } from '../../src/api/restaurantAuth';
import { useRestaurantOwnerStore } from '../../src/store/restaurantOwnerStore';
import { supabase } from '../../src/api/supabase';

interface PlaceResult {
  place_id: string;
  name: string;
  formatted_address: string;
}

interface ClaimedRestaurant {
  google_place_id: string;
}

export default function ClaimRestaurantScreen() {
  const router = useRouter();
  const { session, setRestaurant } = useRestaurantOwnerStore();
  const [searchQuery, setSearchQuery] = useState('');
  const [results, setResults] = useState<PlaceResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [claimingId, setClaimingId] = useState<string | null>(null);
  const [claimedRestaurants, setClaimedRestaurants] = useState<Set<string>>(new Set());

  // Load all claimed restaurants
  useEffect(() => {
    async function loadClaimed() {
      try {
        const { data, error } = await supabase
          .from('restaurants')
          .select('google_place_id');
        if (!error && data) {
          setClaimedRestaurants(new Set(data.map(r => r.google_place_id)));
        }
      } catch (err) {
        console.error('[claim] Failed to load claimed restaurants:', err);
      }
    }
    loadClaimed();
  }, []);

  async function handleSearch() {
    if (!searchQuery.trim()) return;

    setLoading(true);
    try {
      const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL || '';
      const response = await fetch(
        `${supabaseUrl}/functions/v1/restaurant-search`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ query: searchQuery.trim() }),
        }
      );
      const data = await response.json();
      if (!response.ok) throw new Error(data.error);
      setResults(data.results || []);
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to search restaurants');
    } finally {
      setLoading(false);
    }
  }

  async function handleClaim(result: PlaceResult) {
    console.log('[claim] handleClaim called for:', result.place_id);

    if (!session?.access_token) {
      console.error('[claim] No session token');
      Alert.alert('Error', 'Session not found');
      return;
    }

    setClaimingId(result.place_id);
    console.log('[claim] Set claiming ID, about to call claimRestaurant');

    try {
      console.log('[claim] Claiming restaurant:', result.place_id, result.name);
      console.log('[claim] Using access token:', session.access_token ? 'present' : 'missing');

      const claimResult = await claimRestaurant(
        result.place_id,
        result.name,
        result.formatted_address,
        session.access_token
      );

      console.log('[claim] Claim result received:', JSON.stringify(claimResult, null, 2));
      console.log('[claim] Claim result type:', typeof claimResult, 'keys:', Object.keys(claimResult || {}));

      if (claimResult?.restaurant) {
        console.log('[claim] Restaurant claimed successfully, setting in store');
        setRestaurant(claimResult.restaurant);
        Alert.alert('Success', 'Restaurant claimed! 🎉', [
          { text: 'OK', onPress: () => {
            console.log('[claim] Navigating to dashboard');
            router.replace('/restaurant/dashboard');
          }},
        ]);
      } else if (claimResult?.message === 'You already own this restaurant') {
        console.log('[claim] Already owns restaurant');
        Alert.alert('Info', claimResult.message, [
          { text: 'OK', onPress: () => router.replace('/restaurant/dashboard') },
        ]);
      } else {
        console.warn('[claim] Unexpected response:', JSON.stringify(claimResult, null, 2));
        Alert.alert('Info', claimResult?.message || 'Restaurant claimed');
      }
    } catch (err: any) {
      console.error('[claim] Catch block - Error:', err);
      console.error('[claim] Error stringified:', JSON.stringify(err, null, 2));
      console.error('[claim] Error message:', err.message);
      Alert.alert('Error', err.message || 'Failed to claim restaurant');
    } finally {
      console.log('[claim] Finally block - clearing claiming ID');
      setClaimingId(null);
    }
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Claim Your Restaurant</Text>
        <Text style={styles.subtitle}>Search for your restaurant to get started</Text>
      </View>

      <View style={styles.infoBox}>
        <Text style={styles.infoIcon}>⏳</Text>
        <Text style={styles.infoText}>Your restaurant claim is awaiting admin approval. You'll receive a notification once it's approved.</Text>
      </View>

      <View style={styles.searchBox}>
        <TextInput
          style={styles.searchInput}
          placeholder="Restaurant name or address..."
          placeholderTextColor="#999"
          value={searchQuery}
          onChangeText={setSearchQuery}
          onSubmitEditing={handleSearch}
        />
        <TouchableOpacity
          style={[styles.searchBtn, loading && styles.searchBtnDisabled]}
          onPress={handleSearch}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator size="small" color="#fff" />
          ) : (
            <Text style={styles.searchBtnText}>🔍</Text>
          )}
        </TouchableOpacity>
      </View>

      <FlatList
        data={results}
        keyExtractor={(item) => item.place_id}
        renderItem={({ item }) => {
          const isClaimed = claimedRestaurants.has(item.place_id);
          return (
            <View style={[styles.resultCard, isClaimed && styles.resultCardClaimed]}>
              <View style={styles.resultInfo}>
                <View style={styles.resultHeader}>
                  <Text style={styles.resultName}>{item.name}</Text>
                  {isClaimed && <Text style={styles.claimedBadge}>✓ Claimed</Text>}
                </View>
                <Text style={styles.resultAddress}>{item.formatted_address}</Text>
              </View>
              <TouchableOpacity
                style={[
                  styles.claimBtn,
                  isClaimed && styles.claimBtnClaimed,
                  (claimingId === item.place_id || isClaimed) && styles.claimBtnDisabled
                ]}
                onPress={() => handleClaim(item)}
                disabled={claimingId === item.place_id || isClaimed}
              >
                {claimingId === item.place_id ? (
                  <ActivityIndicator size="small" color="#fff" />
                ) : isClaimed ? (
                  <Text style={styles.claimBtnText}>✓</Text>
                ) : (
                  <Text style={styles.claimBtnText}>Claim</Text>
                )}
              </TouchableOpacity>
            </View>
          );
        }}
        contentContainerStyle={styles.list}
        ListEmptyComponent={
          searchQuery ? (
            <Text style={styles.emptyText}>No restaurants found</Text>
          ) : (
            <Text style={styles.emptyText}>Search for your restaurant</Text>
          )
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f6f6f6' },
  header: { paddingHorizontal: 16, paddingTop: 20, paddingBottom: 16 },
  title: { fontSize: 24, fontWeight: '800', color: '#222', marginBottom: 4 },
  subtitle: { fontSize: 14, color: '#666' },
  infoBox: { backgroundColor: '#FFF3E0', marginHorizontal: 16, marginBottom: 16, paddingHorizontal: 14, paddingVertical: 12, borderRadius: 10, borderLeftWidth: 4, borderLeftColor: '#E65100', flexDirection: 'row', alignItems: 'flex-start', gap: 10 },
  infoIcon: { fontSize: 20, marginTop: 2 },
  infoText: { flex: 1, fontSize: 13, fontWeight: '500', color: '#E65100', lineHeight: 18 },
  searchBox: { flexDirection: 'row', paddingHorizontal: 16, paddingBottom: 16, gap: 8 },
  searchInput: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    color: '#222',
  },
  searchBtn: {
    width: 44,
    height: 44,
    borderRadius: 10,
    backgroundColor: '#4CAF50',
    alignItems: 'center',
    justifyContent: 'center',
  },
  searchBtnDisabled: { opacity: 0.6 },
  searchBtnText: { fontSize: 20 },
  list: { paddingHorizontal: 16, paddingBottom: 20 },
  resultCard: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    alignItems: 'center',
    gap: 12,
    elevation: 2,
  },
  resultCardClaimed: { backgroundColor: '#f0f0f0' },
  resultHeader: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 4 },
  resultInfo: { flex: 1 },
  resultName: { fontSize: 15, fontWeight: '700', color: '#222' },
  resultAddress: { fontSize: 12, color: '#666' },
  claimedBadge: { fontSize: 11, fontWeight: '700', color: '#4CAF50', backgroundColor: '#E8F5E9', paddingHorizontal: 8, paddingVertical: 3, borderRadius: 4 },
  claimBtn: {
    backgroundColor: '#4CAF50',
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 8,
    minWidth: 60,
    alignItems: 'center',
  },
  claimBtnClaimed: { backgroundColor: '#ccc' },
  claimBtnDisabled: { opacity: 0.6 },
  claimBtnText: { color: '#fff', fontSize: 13, fontWeight: '600' },
  emptyText: { fontSize: 14, color: '#999', textAlign: 'center', marginTop: 40 },
});
