import axios from 'axios';

// Points at the production API by default in every mode (dev/build/preview).
// To work against a local backend, create a git-ignored `.env.local` with
// VITE_API_BASE_URL=http://localhost:7000
export const BASE_URL =
  import.meta.env.VITE_API_BASE_URL || 'https://apis.sportaapp.net';

const apiClient = axios.create({
  baseURL: BASE_URL,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

// ── Request interceptor: attach JWT ──────────────────────────────────────────
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// ── Response interceptor: handle 401 + unwrap ApiResponse<T> ─────────────────
apiClient.interceptors.response.use(
  (response) => {
    // API wraps everything in { success, data, message }
    // Return the full axios response so callers can access .data
    return response;
  },
  async (error) => {
    if (error.response?.status === 401) {
      // Try refresh token
      const refreshToken = localStorage.getItem('refresh_token');
      if (refreshToken && !error.config._retry) {
        error.config._retry = true;
        try {
          const res = await axios.post(`${BASE_URL}/api/auth/refresh`, { refreshToken });
          const { accessToken, refreshToken: newRefresh } = res.data.data;
          localStorage.setItem('access_token', accessToken);
          localStorage.setItem('refresh_token', newRefresh);
          error.config.headers.Authorization = `Bearer ${accessToken}`;
          return apiClient(error.config);
        } catch {
          localStorage.clear();
          window.location.href = '/login';
        }
      } else {
        localStorage.clear();
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient;
