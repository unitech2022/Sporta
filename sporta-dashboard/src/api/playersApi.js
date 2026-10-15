import apiClient from './apiClient';

export const playersApi = {
  getMe: () => apiClient.get('/api/players/me'),
};
