import { useState, useEffect, useCallback } from 'react';

/**
 * Generic hook for API calls.
 * @param {Function} fn  - async function that returns axios response
 * @param {any[]} deps   - dependencies that trigger re-fetch
 */
export function useApi(fn, deps = []) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const execute = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fn();
      setData(res.data.data);
    } catch (err) {
      setError(
        err?.response?.data?.messageAr ||
        err?.response?.data?.message ||
        'حدث خطأ في الاتصال بالخادم'
      );
    } finally {
      setLoading(false);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useEffect(() => { execute(); }, [execute]);

  return { data, loading, error, refetch: execute };
}
