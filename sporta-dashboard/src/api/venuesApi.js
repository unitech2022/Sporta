import apiClient from './apiClient';

// Admin — venues (owner onboarding review): commercial registration, national
// address, owner ID photo, tax certificate, venue photo gallery.
export const venuesApi = {
  getAll: (params = {}) => apiClient.get('/api/admin/venues', { params }),
  getById: (id) => apiClient.get(`/api/admin/venues/${id}`),

  /** PUT /api/admin/venues/:id/approve — الموافقة/إلغاء الموافقة (يُشعر المالك) */
  setApproved: (id, approved) =>
    apiClient.put(`/api/admin/venues/${id}/approve`, { approved }),

  /**
   * DELETE /api/admin/venues/:id — حذف النادي وكل ملاعبه.
   * حذف ناعم على الخادم: يختفي النادي وملاعبه من اللوحة والتطبيق ولوحة المالك،
   * وتُلغى الحجوزات القادمة مع ردّ ما دُفع لمحافظ اللاعبين، بينما تبقى الحجوزات
   * والفواتير السابقة في السجل المالي. لا رجعة فيه.
   */
  remove: (id) => apiClient.delete(`/api/admin/venues/${id}`),
};
