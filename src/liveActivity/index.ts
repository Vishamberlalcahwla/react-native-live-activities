import { NativeModules, PermissionsAndroid, Platform } from 'react-native';

/** Fixed for the whole order (iOS: ActivityAttributes). */
export type OrderInfo = {
  orderNumber: string;
  storeName: string;
  itemsSummary: string;
};

/** Changes over time (iOS: ContentState). */
export type OrderState = {
  /** 0 = confirmed, 1 = preparing, 2 = on the way, 3 = delivered */
  step: 0 | 1 | 2 | 3;
  statusText: string;
  /** Estimated arrival as epoch milliseconds. The system renders the countdown. */
  etaTimestamp: number;
};

export type AndroidCapabilities = {
  notificationsEnabled: boolean;
  /** true on Android 16+ (API 36) */
  liveUpdatesSupported: boolean;
  /** true when the user allows promoted Live Updates for this app */
  liveUpdatesEnabled: boolean;
};

type NativeLiveActivity = {
  isSupported(): Promise<boolean>;
  start(order: OrderInfo, state: OrderState): Promise<string>;
  update(id: string, state: OrderState): Promise<void>;
  end(id: string, finalState: OrderState | null): Promise<void>;
  endAll(): Promise<void>;
  // Android only
  getAndroidCapabilities?(): Promise<AndroidCapabilities>;
  openLiveUpdateSettings?(): Promise<void>;
};

const Native: NativeLiveActivity | undefined = NativeModules.LiveActivityModule;

/**
 * One API for both platforms:
 * - iOS: Live Activity on the Dynamic Island + Lock Screen (ActivityKit)
 * - Android: ongoing notification, promoted to a Live Update on Android 16+
 */
export const LiveActivity = {
  /** Asks for notification permission where needed and reports whether live updates can be shown. */
  async prepare(): Promise<boolean> {
    if (!Native) return false;
    if (Platform.OS === 'android' && Number(Platform.Version) >= 33) {
      const result = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.POST_NOTIFICATIONS,
      );
      if (result !== PermissionsAndroid.RESULTS.GRANTED) return false;
    }
    return Native.isSupported();
  },

  async start(order: OrderInfo, state: OrderState): Promise<string | null> {
    if (!Native) return null;
    return Native.start(order, state);
  },

  async update(id: string, state: OrderState): Promise<void> {
    if (!Native) return;
    return Native.update(id, state);
  },

  /** Pass a final state (e.g. "Delivered") to leave it visible briefly, or omit to remove it now. */
  async end(id: string, finalState?: OrderState): Promise<void> {
    if (!Native) return;
    return Native.end(id, finalState ?? null);
  },

  async endAll(): Promise<void> {
    if (!Native) return;
    return Native.endAll();
  },

  async getAndroidCapabilities(): Promise<AndroidCapabilities | null> {
    if (Platform.OS !== 'android' || !Native?.getAndroidCapabilities) return null;
    return Native.getAndroidCapabilities();
  },

  async openLiveUpdateSettings(): Promise<void> {
    if (Platform.OS !== 'android' || !Native?.openLiveUpdateSettings) return;
    return Native.openLiveUpdateSettings();
  },
};
