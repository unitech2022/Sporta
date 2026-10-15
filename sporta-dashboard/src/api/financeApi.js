import apiClient from './apiClient';

// Finance / wallet endpoints (admin only).
export const financeApi = {
  // Platform-wide financial summary (incoming / outgoing / balances / breakdown).
  getStats: () => apiClient.get('/api/admin/finance/stats'),

  // All wallet transactions across users. params: { type, search, page, pageSize }
  getTransactions: (params = {}) =>
    apiClient.get('/api/admin/transactions', { params }),
  getTransaction: (id) => apiClient.get(`/api/admin/transactions/${id}`),

  // Withdrawal requests. params: { page, pageSize, status }
  getWithdrawals: (params = {}) =>
    apiClient.get('/api/admin/withdrawals', { params }),
  // body: { approved: bool, adminNotes?: string }
  processWithdrawal: (id, body) =>
    apiClient.patch(`/api/admin/withdrawals/${id}`, body),
};
