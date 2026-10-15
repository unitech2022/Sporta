import apiClient from './apiClient';

/**
 * Support chat (الدعم الفني) — the admin side of the same endpoints the mobile
 * app talks to. REST holds the full history; `supportHub` only pushes what just
 * happened, so every screen stays correct even when the socket is down.
 */
export const supportApi = {
  /** Paginated conversation list, newest activity first. */
  conversations: ({ page = 1, pageSize = 20, search = '', status = '', unreadOnly = false } = {}) =>
    apiClient.get('/api/support-chat/conversations', {
      params: {
        page,
        pageSize,
        ...(search ? { search } : {}),
        ...(status ? { status } : {}),
        ...(unreadOnly ? { unreadOnly: true } : {}),
      },
    }),

  /**
   * One conversation's messages, newest page first.
   * `before` is a message id cursor — pass the oldest loaded id to page back.
   */
  messages: (conversationId, { before, limit = 30 } = {}) =>
    apiClient.get(`/api/support-chat/conversations/${conversationId}/messages`, {
      params: { ...(before ? { before } : {}), limit },
    }),

  reply: (conversationId, body) =>
    apiClient.post(`/api/support-chat/conversations/${conversationId}/messages`, { body }),

  /** Opens (or resumes) a thread with a specific account, optionally with a first line. */
  start: (userId, body) =>
    apiClient.post('/api/support-chat/conversations', { userId, body }),

  markRead: (conversationId) =>
    apiClient.post(`/api/support-chat/conversations/${conversationId}/read`),

  /** status: 'Open' | 'Closed' */
  setStatus: (conversationId, status) =>
    apiClient.post(`/api/support-chat/conversations/${conversationId}/status`, null, {
      params: { status },
    }),
};
