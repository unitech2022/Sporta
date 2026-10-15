import apiClient from './apiClient';

// Generic system-settings CRUD (maintenance mode, app version gate, policy
// text, commission, etc.) — admin only.
export const settingsApi = {
  getAll: () => apiClient.get('/api/admin/settings'),
  create: (body) => apiClient.post('/api/admin/settings', body),
  update: (id, body) => apiClient.put(`/api/admin/settings/${id}`, body),
  delete: (id) => apiClient.delete(`/api/admin/settings/${id}`),
};
