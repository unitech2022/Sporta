import apiClient from './apiClient';

// Admin-only endpoints (require an admin JWT).
export const adminApi = {
  getStats: () => apiClient.get('/api/admin/stats'),

  getUsers: (params = {}) =>
    apiClient.get('/api/admin/users', { params }),
  getUser: (id) => apiClient.get(`/api/admin/users/${id}`),
  lockUser: (id) => apiClient.post(`/api/admin/users/${id}/lock`),
  unlockUser: (id) => apiClient.post(`/api/admin/users/${id}/unlock`),

  /**
   * DELETE /api/admin/users/:id — حذف حساب المستخدم نهائياً (لا رجعة فيه).
   * يُلغي الالتزامات القادمة ويردّ ما دُفع، يمسح البيانات الشخصية والملفات
   * المرفوعة، ثم يُعمّي الحساب — والسجل المالي السابق يبقى سليماً.
   */
  deleteUser: (id) => apiClient.delete(`/api/admin/users/${id}`),

  // تعديل مستوى لاعب يدوياً (1..7) — تجاوز لما قرّره التقييم أو المدرب.
  setPlayerLevel: (id, level) =>
    apiClient.put(`/api/admin/users/${id}/level`, { level }),

  // اعتماد حساب المدرب/صاحب الملعب بعد مراجعة بياناته ('coach' | 'venue').
  approveUserRole: (id, role, approved = true) =>
    apiClient.post(`/api/admin/users/${id}/approve-role`, { role, approved }),

  getNotifications: (params = {}) =>
    apiClient.get('/api/admin/notifications', { params }),
  getUnreadNotificationsCount: () => apiClient.get('/api/admin/notifications/unread-count'),

  // Bookings / invoices
  getBookings: (params = {}) => apiClient.get('/api/admin/bookings', { params }),
  getBooking: (id) => apiClient.get(`/api/admin/bookings/${id}`),

  // Settings
  getSupportPhone: () => apiClient.get('/api/settings/support-phone'),
  setSupportPhone: (phone) => apiClient.put('/api/settings/support-phone', { phone }),
  getDefaultCommission: () => apiClient.get('/api/admin/settings/default-commission'),
  setDefaultCommission: (percent) =>
    apiClient.put('/api/admin/settings/default-commission', { percent }),

  // Ads / announcements
  getAds: () => apiClient.get('/api/admin/ads'),
  createAd: (body) => apiClient.post('/api/admin/ads', body),
  updateAd: (id, body) => apiClient.put(`/api/admin/ads/${id}`, body),
  deleteAd: (id) => apiClient.delete(`/api/admin/ads/${id}`),

  // Sports
  getSports: () => apiClient.get('/api/admin/sports'),
  createSport: (body) => apiClient.post('/api/admin/sports', body),
  updateSport: (id, body) => apiClient.put(`/api/admin/sports/${id}`, body),
  deleteSport: (id) => apiClient.delete(`/api/admin/sports/${id}`),

  // Sport settings (per-sport: title + items under it)
  getSportSettings: (sportId) => apiClient.get(`/api/admin/sports/${sportId}/settings`),
  createSportSetting: (sportId, body) =>
    apiClient.post(`/api/admin/sports/${sportId}/settings`, body),
  updateSportSetting: (id, body) => apiClient.put(`/api/admin/sports/settings/${id}`, body),
  deleteSportSetting: (id) => apiClient.delete(`/api/admin/sports/settings/${id}`),

  // Coach specializations (تخصصات المدربين)
  // سُلَّم المستويات (المستويات والنقاط)
  getLevelDefinitions: () => apiClient.get('/api/admin/level-definitions'),
  createLevelDefinition: (body) => apiClient.post('/api/admin/level-definitions', body),
  updateLevelDefinition: (id, body) =>
    apiClient.put(`/api/admin/level-definitions/${id}`, body),
  deleteLevelDefinition: (id) => apiClient.delete(`/api/admin/level-definitions/${id}`),

  getCoachSpecializations: () => apiClient.get('/api/admin/coach-specializations'),
  createCoachSpecialization: (body) => apiClient.post('/api/admin/coach-specializations', body),
  updateCoachSpecialization: (id, body) =>
    apiClient.put(`/api/admin/coach-specializations/${id}`, body),
  deleteCoachSpecialization: (id) => apiClient.delete(`/api/admin/coach-specializations/${id}`),

  // مناطق الخدمة (Geofencing)
  getServiceZones: () => apiClient.get('/api/admin/service-zones'),
  createServiceZone: (body) => apiClient.post('/api/admin/service-zones', body),
  updateServiceZone: (id, body) => apiClient.put(`/api/admin/service-zones/${id}`, body),
  deleteServiceZone: (id) => apiClient.delete(`/api/admin/service-zones/${id}`),
  checkServiceZone: (lat, lng) =>
    apiClient.get('/api/service-zones/check', { params: { lat, lng } }),
  getServiceZoneMessage: () => apiClient.get('/api/admin/service-zones/message'),
  saveServiceZoneMessage: (body) => apiClient.put('/api/admin/service-zones/message', body),

  // Cities / Districts
  // Countries
  getCountries: () => apiClient.get('/api/admin/countries'),
  createCountry: (body) => apiClient.post('/api/admin/countries', body),
  updateCountry: (id, body) => apiClient.put(`/api/admin/countries/${id}`, body),
  deleteCountry: (id) => apiClient.delete(`/api/admin/countries/${id}`),

  getCities: (params = {}) => apiClient.get('/api/admin/cities', { params }),
  createCity: (body) => apiClient.post('/api/admin/cities', body),
  updateCity: (id, body) => apiClient.put(`/api/admin/cities/${id}`, body),
  deleteCity: (id) => apiClient.delete(`/api/admin/cities/${id}`),
  getDistricts: (cityId) => apiClient.get(`/api/admin/cities/${cityId}/districts`),
  createDistrict: (body) => apiClient.post('/api/admin/districts', body),
  updateDistrict: (id, body) => apiClient.put(`/api/admin/districts/${id}`, body),
  deleteDistrict: (id) => apiClient.delete(`/api/admin/districts/${id}`),

  // Loyalty points
  getUserPoints: (id, page = 1, pageSize = 20) =>
    apiClient.get(`/api/admin/users/${id}/points`, { params: { page, pageSize } }),
  adjustUserPoints: (id, amount, reason) =>
    apiClient.post(`/api/admin/users/${id}/points/adjust`, { amount, reason }),
  getPointsStats: () => apiClient.get('/api/admin/points/stats'),

  // Packages
  getPackages: () => apiClient.get('/api/admin/packages'),
  createPackage: (body) => apiClient.post('/api/admin/packages', body),
  updatePackage: (id, body) => apiClient.put(`/api/admin/packages/${id}`, body),
  deletePackage: (id) => apiClient.delete(`/api/admin/packages/${id}`),

  // Notifications
  broadcast: (body) => apiClient.post('/api/admin/notifications/broadcast', body),
  sendToUser: (body) => apiClient.post('/api/admin/notifications/send', body),
  deleteNotifications: (body) => apiClient.post('/api/admin/notifications/delete', body),

  // Discounts (general or targeted)
  getDiscounts: () => apiClient.get('/api/admin/discounts'),
  createDiscount: (body) => apiClient.post('/api/admin/discounts', body),
  updateDiscount: (id, body) => apiClient.put(`/api/admin/discounts/${id}`, body),
  deleteDiscount: (id) => apiClient.delete(`/api/admin/discounts/${id}`),
  getDiscountBeneficiaries: (id) =>
    apiClient.get(`/api/admin/discounts/${id}/beneficiaries`),
  searchDiscountUsers: (params = {}) =>
    apiClient.get('/api/admin/discounts/user-search', { params }),
  addDiscountBeneficiary: (id, userId) =>
    apiClient.post(`/api/admin/discounts/${id}/beneficiaries`, { userId }),
  removeDiscountBeneficiary: (id, userId) =>
    apiClient.delete(`/api/admin/discounts/${id}/beneficiaries/${userId}`),

  // Venue subscriptions
  getVenueSubscriptionPricing: () =>
    apiClient.get('/api/admin/venue-subscriptions/pricing'),
  saveVenueSubscriptionPricing: (body) =>
    apiClient.put('/api/admin/venue-subscriptions/pricing', body),
  getVenueSubscriptions: (params = {}) =>
    apiClient.get('/api/admin/venue-subscriptions', { params }),

  // Coach commission
  getCoachCommission: () => apiClient.get('/api/admin/settings/coach-commission'),
  setCoachCommission: (percent) =>
    apiClient.put('/api/admin/settings/coach-commission', { percent }),

  // Staff & permissions
  getMyAccess: () => apiClient.get('/api/admin/me/access'),
  getPermissionCatalog: () => apiClient.get('/api/admin/permissions'),
  getStaff: (params = {}) => apiClient.get('/api/admin/staff', { params }),
  getStaffMember: (userId) => apiClient.get(`/api/admin/staff/${userId}`),
  createStaff: (body) => apiClient.post('/api/admin/staff', body),
  updateStaff: (userId, body) => apiClient.put(`/api/admin/staff/${userId}`, body),
  setStaffActive: (userId, active) =>
    apiClient.put(`/api/admin/staff/${userId}/active`, { active }),
  deleteStaff: (userId) => apiClient.delete(`/api/admin/staff/${userId}`),

  // Uploads — returns { url: "/uploads/images/{file}" }, relative to BASE_URL.
  uploadImage: (file) => {
    const form = new FormData();
    form.append('file', file);
    return apiClient.post('/api/uploads/image', form, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },
};
