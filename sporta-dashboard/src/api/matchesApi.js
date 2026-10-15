import apiClient from './apiClient';

export const matchesApi = {
  // GET /api/matches has returned a plain array in newer backend builds and a
  // paginated `{ items, page, ... }` object in older ones (e.g. production may
  // lag behind local during a deploy). Normalize to a plain array either way
  // so callers (HomePage, MatchesPage) never have to special-case the shape.
  getAll: async (city) => {
    const res = await apiClient.get('/api/matches', { params: { city } });
    const raw = res.data?.data;
    res.data.data = Array.isArray(raw) ? raw : (raw?.items ?? []);
    return res;
  },
  getById: (id) => apiClient.get(`/api/matches/${id}`),

  // حذف نهائي من الإدارة: يعيد الحصص المحجوزة ويُخطر اللاعبين قبل المحو.
  remove: (id) => apiClient.delete(`/api/admin/matches/${id}`),
};
