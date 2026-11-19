import { useCallback, useEffect, useRef, useState } from 'react';
import { LiveActivity, OrderInfo, OrderState } from './index';

/**
 * Ties a Live Activity (iOS) / Live Update (Android) to an order's lifecycle.
 *
 *   const { start, update, finish, isActive } = useOrderLiveActivity(order);
 */
export function useOrderLiveActivity(order: OrderInfo) {
  const activityId = useRef<string | null>(null);
  const starting = useRef(false);
  const [isActive, setIsActive] = useState(false);
  const [error, setError] = useState<string | null>(null);
  /** Android 16+ only: false when the user has turned Live Updates off for this app */
  const [liveUpdatesEnabled, setLiveUpdatesEnabled] = useState<boolean | null>(null);

  const start = useCallback(
    async (state: OrderState) => {
      // Guard against double taps / re-renders starting two activities
      if (starting.current || activityId.current) return;
      starting.current = true;
      setError(null);
      try {
        const { canShow, liveUpdatesEnabled: promoted } = await LiveActivity.prepare();
        setLiveUpdatesEnabled(promoted);
        if (!canShow) {
          setError('Live updates are not available or not allowed on this device.');
          return;
        }
        activityId.current = await LiveActivity.start(order, state);
        setIsActive(activityId.current != null);
      } catch (e: any) {
        setError(e?.message ?? String(e));
      } finally {
        starting.current = false;
      }
    },
    [order],
  );

  const update = useCallback(async (state: OrderState) => {
    if (!activityId.current) return;
    try {
      await LiveActivity.update(activityId.current, state);
    } catch (e: any) {
      // e.g. NOT_FOUND if the user dismissed it or iOS ended it
      setError(e?.message ?? String(e));
    }
  }, []);

  const finish = useCallback(async (finalState?: OrderState) => {
    if (!activityId.current) return;
    const id = activityId.current;
    activityId.current = null;
    setIsActive(false);
    await LiveActivity.end(id, finalState);
  }, []);

  // Never leave an orphaned activity behind when the screen unmounts.
  // Cleanup can't be async, so fire and forget.
  useEffect(() => {
    return () => {
      const id = activityId.current;
      activityId.current = null;
      if (id) LiveActivity.end(id).catch(() => {});
    };
  }, []);

  return { start, update, finish, isActive, error, liveUpdatesEnabled };
}
