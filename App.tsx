/**
 * Live Activities demo: an order tracker that shows up on the
 * iOS Dynamic Island / Lock Screen and as an Android Live Update.
 */
import React, { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Linking,
  Platform,
  Pressable,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { LiveActivity, OrderInfo, OrderState } from './src/liveActivity';
import { useOrderLiveActivity } from './src/liveActivity/useOrderLiveActivity';

const STEPS: { statusText: string; minutesLeft: number }[] = [
  { statusText: 'Order confirmed', minutesLeft: 30 },
  { statusText: 'Your order is being prepared', minutesLeft: 22 },
  { statusText: 'Your order is on the way', minutesLeft: 9 },
  { statusText: 'Delivered. Enjoy!', minutesLeft: 0 },
];

const ORDER: OrderInfo = {
  orderNumber: '4821',
  storeName: 'Green Bowl Kitchen',
  itemsSummary: '2 × Chicken bowl, 1 × Lemonade',
};

function stateFor(step: number): OrderState {
  return {
    step: step as OrderState['step'],
    statusText: STEPS[step].statusText,
    etaTimestamp: Date.now() + STEPS[step].minutesLeft * 60_000,
  };
}

function OrderScreen() {
  const order = useMemo(() => ORDER, []);
  const [step, setStep] = useState(0);
  const { start, update, finish, isActive, error, liveUpdatesEnabled } =
    useOrderLiveActivity(order);

  // Tapping the Dynamic Island / notification opens liveactivitiesdemo://order/<number>
  useEffect(() => {
    const sub = Linking.addEventListener('url', ({ url }) => {
      Alert.alert('Opened from live activity', url);
    });
    return () => sub.remove();
  }, []);

  const onStart = async () => {
    setStep(0);
    await start(stateFor(0));
  };

  const onNext = async () => {
    const next = Math.min(step + 1, STEPS.length - 1);
    setStep(next);
    if (next === STEPS.length - 1) {
      await finish(stateFor(next)); // leaves a final "Delivered" state visible
    } else {
      await update(stateFor(next));
    }
  };

  const onCancel = async () => {
    await finish(); // removes it immediately
    setStep(0);
  };

  return (
    <ScrollView contentContainerStyle={styles.content}>
      <Text style={styles.title}>Live Activities in React Native</Text>
      <Text style={styles.subtitle}>
        {Platform.OS === 'ios'
          ? 'Start an order, then go to the Home Screen or lock the phone to see it on the Dynamic Island and Lock Screen.'
          : 'Start an order, then pull down the notification shade or lock the phone. On Android 16+ it appears as a Live Update.'}
      </Text>

      <View style={styles.card}>
        <Text style={styles.store}>{order.storeName}</Text>
        <Text style={styles.meta}>
          Order #{order.orderNumber} · {order.itemsSummary}
        </Text>
        <View style={styles.tracker}>
          {STEPS.map((_, i) => (
            <View
              key={i}
              style={[styles.segment, i <= step && isActive ? styles.segmentOn : null]}
            />
          ))}
        </View>
        <Text style={styles.status}>
          {isActive ? STEPS[step].statusText : 'No active order'}
        </Text>
      </View>

      {!isActive ? (
        <Button label="Start order" onPress={onStart} primary />
      ) : (
        <>
          <Button label="Next step" onPress={onNext} primary />
          <Button label="Cancel order" onPress={onCancel} />
        </>
      )}

      {Platform.OS === 'android' && liveUpdatesEnabled === false && (
        <Button
          label="Turn on Live Updates (Android 16+)"
          onPress={() => LiveActivity.openLiveUpdateSettings()}
        />
      )}

      {error ? <Text style={styles.error}>{error}</Text> : null}
    </ScrollView>
  );
}

function Button(props: { label: string; onPress: () => void; primary?: boolean }) {
  return (
    <Pressable
      onPress={props.onPress}
      style={({ pressed }) => [
        styles.button,
        props.primary ? styles.buttonPrimary : styles.buttonSecondary,
        pressed && { opacity: 0.7 },
      ]}>
      <Text style={props.primary ? styles.buttonTextPrimary : styles.buttonTextSecondary}>
        {props.label}
      </Text>
    </Pressable>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView style={styles.root}>
        <OrderScreen />
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const ORANGE = '#FF8C00';

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#F6F6F8' },
  content: { padding: 20, gap: 14 },
  title: { fontSize: 24, fontWeight: '700', color: '#111' },
  subtitle: { fontSize: 15, color: '#555', lineHeight: 21 },
  card: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 18,
    gap: 8,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 10,
    elevation: 2,
  },
  store: { fontSize: 18, fontWeight: '600', color: '#111' },
  meta: { fontSize: 13, color: '#777' },
  tracker: { flexDirection: 'row', gap: 6, marginVertical: 6 },
  segment: { flex: 1, height: 6, borderRadius: 3, backgroundColor: '#E2E2E6' },
  segmentOn: { backgroundColor: ORANGE },
  status: { fontSize: 16, fontWeight: '600', color: '#111' },
  button: { borderRadius: 12, paddingVertical: 14, alignItems: 'center' },
  buttonPrimary: { backgroundColor: ORANGE },
  buttonSecondary: { backgroundColor: '#fff', borderWidth: 1, borderColor: '#DDD' },
  buttonTextPrimary: { color: '#fff', fontSize: 16, fontWeight: '600' },
  buttonTextSecondary: { color: '#333', fontSize: 16, fontWeight: '500' },
  error: { color: '#C62828', fontSize: 14 },
});
