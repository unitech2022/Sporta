import apiClient from './apiClient';

export const coachesApi = {
  // Admin dashboard passes includeInactive so suspended coaches stay visible.
  getAll: (city, includeInactive = false) =>
    apiClient.get('/api/coaches', { params: { city, includeInactive } }),
  getById: (id) => apiClient.get(`/api/coaches/${id}`),

  /**
   * DELETE /api/admin/coaches/:userId — حذف حساب المدرب نهائياً.
   * المعرّف هو userId لا معرّف ملف المدرب. يمرّ على نفس مسار حذف الحساب في
   * التطبيق: إلغاء الجلسات القادمة وإشعار اللاعبين، ثم تعمية البيانات الشخصية.
   */
  remove: (userId) => apiClient.delete(`/api/admin/coaches/${userId}`),
};
