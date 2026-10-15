import apiClient from './apiClient';

export const courtsApi = {
  /** GET /api/admin/courts — كل الملاعب بما فيها الموقوفة (لوحة التحكم) */
  getAll: () => apiClient.get('/api/admin/courts'),

  /** GET /api/courts/:id */
  // مسار إداري: يفتح الملعب حتى قبل اعتماد ناديه — المسار العام يشترط الاعتماد
  // فكانت اللوحة تسرد ملاعب لا تستطيع فتحها.
  getById: (id) => apiClient.get(`/api/admin/courts/${id}`),

  /** GET /api/admin/courts/:id/availability?date=yyyy-MM-dd */
  getAvailability: (id, date) =>
    apiClient.get(`/api/admin/courts/${id}/availability?date=${date}`),

  /** PUT /api/admin/courts/:id/commission — نسبة سبورتا */
  updateCommission: (id, percent) =>
    apiClient.put(`/api/admin/courts/${id}/commission`, { percent }),

  /** PUT /api/admin/courts/:id/suspend — إيقاف/تفعيل الملعب (يُشعر المالك) */
  setSuspended: (id, suspended) =>
    apiClient.put(`/api/admin/courts/${id}/suspend`, { suspended }),

  /** DELETE /api/admin/courts/:id — حذف الملعب (حذف ناعم، انظر venuesApi.remove) */
  remove: (id) => apiClient.delete(`/api/admin/courts/${id}`),
};
