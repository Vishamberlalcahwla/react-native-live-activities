import { useCallback, useEffect, useRef, useState } from 'react';
import { LiveActivity, OrderInfo, OrderState } from './index';

/**
 * Ties a Live Activity (iOS) / Live Update (Android) to an order's lifecycle.
 *
 *   const { start, update, finish, isActive } = useOrderLiveActivity(order);
 */
export function useOrderLiveActivity(order: OrderInfo) {
  const activityId = useRef<string | null>(null);
  const [isActive, setIsActive] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const start = useCallback(
    async (state: OrderState) => {
      setError(null);
      try {
        const allowed = await LiveActivity.prepare();
        if (!allowed) {
          setError('Live updates are not available or not allowed on this device.');
          return;
        }
        activityId.current = await LiveActivity.start(order, state);
        setIsActive(activityId.current != null);
      } catch (e: any) {
        setError(e?.message ?? String(e));
      }
    },
    [order],
  );

  const update = useCallback(async (state: OrderState) => {
    if (!activityId.current) return;
    try {
      await LiveActivity.update(activityId.current, state);
    } catch (e: any) {
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

  // Never leave an orphaned activity behind when the screen goes away
  useEffect(() => {
    return () => {
      if (activityId.current) LiveActivity.end(activityId.current);
    };
  }, []);

  return { start, update, finish, isActive, error };
}
