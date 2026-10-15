import apiClient from './apiClient';

// Admin CRUD for assessment levels and questions (per sport).
export const assessmentApi = {
  // Levels
  getLevels: (sport) =>
    apiClient.get('/api/admin/assessment/levels', { params: { sport } }),
  createLevel: (body) =>
    apiClient.post('/api/admin/assessment/levels', body),
  updateLevel: (id, body) =>
    apiClient.put(`/api/admin/assessment/levels/${id}`, body),
  deleteLevel: (id) =>
    apiClient.delete(`/api/admin/assessment/levels/${id}`),

  // Questions
  getQuestions: (sport) =>
    apiClient.get('/api/admin/assessment/questions', { params: { sport } }),
  createQuestion: (body) =>
    apiClient.post('/api/admin/assessment/questions', body),
  updateQuestion: (id, body) =>
    apiClient.put(`/api/admin/assessment/questions/${id}`, body),
  deleteQuestion: (id) =>
    apiClient.delete(`/api/admin/assessment/questions/${id}`),
};
