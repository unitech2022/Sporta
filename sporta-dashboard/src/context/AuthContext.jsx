import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { authApi } from '../api/authApi';
import { adminApi } from '../api/adminApi';
import { playersApi } from '../api/playersApi';
import { disconnectSupportHub } from '../api/supportHub';

const AuthContext = createContext(null);

// Only platform staff belong in this dashboard.
const DASHBOARD_ROLES = ['admin', 'staff'];

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [access, setAccess] = useState(null); // { role, permissions[], scope }
  const [loading, setLoading] = useState(true); // checking persisted session

  // Permissions + geo scope come from the server, never from the stored user.
  const loadAccess = useCallback(async () => {
    try {
      const res = await adminApi.getMyAccess();
      const dto = res.data.data ?? null;
      setAccess(dto);
      return dto;
    } catch {
      setAccess(null);
      return null;
    }
  }, []);

  // Restore session from localStorage on mount, then enrich with player profile
  useEffect(() => {
    const stored = localStorage.getItem('user');
    const token = localStorage.getItem('access_token');
    if (stored && token) {
      try { setUser(JSON.parse(stored)); } catch { /* ignore */ }
      Promise.all([
        loadAccess(),
        // Staff accounts have no player profile — a failure here is expected.
        playersApi.getMe()
          .then(res => {
            const profile = res.data.data;
            if (profile) {
              const enriched = { ...JSON.parse(stored || '{}'), ...profile };
              setUser(enriched);
              localStorage.setItem('user', JSON.stringify(enriched));
            }
          })
          .catch(() => { /* not a player — keep stored user */ }),
      ]).finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, [loadAccess]);

  const login = async (phone, password) => {
    const res = await authApi.login(phone, password);
    const { accessToken, refreshToken, user: userDto } = res.data.data;

    const roles = userDto?.roles ?? [];
    if (!roles.some(r => DASHBOARD_ROLES.includes(r))) {
      const err = new Error('NOT_DASHBOARD_USER');
      err.messageAr = 'هذا الحساب لا يملك صلاحية الدخول للوحة التحكم';
      throw err;
    }

    localStorage.setItem('access_token', accessToken);
    localStorage.setItem('refresh_token', refreshToken);
    localStorage.setItem('user', JSON.stringify(userDto));
    setUser(userDto);

    await loadAccess();

    // Enrich with player profile (firstName/lastName etc.) when there is one.
    try {
      const pRes = await playersApi.getMe();
      const profile = pRes.data.data;
      if (profile) {
        const enriched = { ...userDto, ...profile };
        setUser(enriched);
        localStorage.setItem('user', JSON.stringify(enriched));
        return enriched;
      }
    } catch { /* staff accounts have no player profile */ }

    return userDto;
  };

  const logout = () => {
    // Drop the chat socket first — it authenticated with the token we are
    // about to delete, and would otherwise stay open on the old identity.
    disconnectSupportHub();
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('user');
    setUser(null);
    setAccess(null);
  };

  const updateUser = (patch) => {
    const updated = { ...user, ...patch };
    setUser(updated);
    localStorage.setItem('user', JSON.stringify(updated));
  };

  const isAdmin = access?.role === 'admin';

  /// Admins hold everything; staff hold exactly what was granted.
  const can = useCallback(
    (permission) => isAdmin || (access?.permissions ?? []).includes(permission),
    [isAdmin, access],
  );

  /// True when any one of the passed permissions is held (for section access).
  const canAny = useCallback(
    (...permissions) => permissions.some(p => can(p)),
    [can],
  );

  return (
    <AuthContext.Provider
      value={{ user, access, isAdmin, can, canAny, loading, login, logout, updateUser }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
