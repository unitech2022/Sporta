import apiClient from './apiClient';

export const authApi = {
  login: (phone, password) =>
    apiClient.post('/api/auth/login', { phone, password }),

  refresh: (refreshToken) =>
    apiClient.post('/api/auth/refresh', { refreshToken }),
};
