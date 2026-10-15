import apiClient from './apiClient';

// The three legal documents are stored as system settings (keys below) with
// full Markdown content in valueAr / valueEn. This helper narrows the generic
// settings store down to just those keys for the dedicated Policies editor.
export const POLICY_KEYS = ['terms_conditions', 'privacy_policy', 'refund_policy'];

export const policiesApi = {
  // Dedicated policy endpoints — gated by the policies.* permissions, so an
  // employee can edit the legal texts without holding full settings access.
  list: async () => {
    const res = await apiClient.get('/api/admin/settings/policies');
    return res.data.data ?? [];
  },
  update: (setting, { valueAr, valueEn }) =>
    apiClient.put(`/api/admin/settings/policies/${setting.id}`, { valueAr, valueEn }),
};
