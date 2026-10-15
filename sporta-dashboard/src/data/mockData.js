export const mockStats = {
  totalUsers: 1240,
  totalCourts: 18,
  totalMatches: 342,
  totalBookings: 890,
  totalRevenue: 48500,
  totalCoaches: 24,
  totalPlayers: 1180,
  totalAnnouncements: 15,
  pendingInvoices: 37,
};

export const mockCourts = [
  { id: 1, name: 'ملعب النور', location: 'الرياض - حي النزهة', sport: 'كرة قدم', status: 'active', pricePerHour: 150, rating: 4.5, bookings: 120 },
  { id: 2, name: 'ملعب الفجر', location: 'جدة - حي الصفا', sport: 'كرة سلة', status: 'active', pricePerHour: 120, rating: 4.2, bookings: 89 },
  { id: 3, name: 'ملعب التحدي', location: 'الدمام - العزيزية', sport: 'تنس', status: 'inactive', pricePerHour: 200, rating: 3.8, bookings: 45 },
  { id: 4, name: 'ملعب الأبطال', location: 'الرياض - حي الملقا', sport: 'كرة قدم', status: 'active', pricePerHour: 180, rating: 4.7, bookings: 210 },
  { id: 5, name: 'ملعب السرعة', location: 'مكة - العزيزية', sport: 'ريشة طائرة', status: 'inactive', pricePerHour: 90, rating: 4.0, bookings: 33 },
];

export const mockCoaches = [
  { id: 1, name: 'أحمد محمد علي', sport: 'كرة قدم', experience: 8, rating: 4.8, sessions: 245, phone: '0501234567', status: 'active' },
  { id: 2, name: 'خالد العتيبي', sport: 'كرة سلة', experience: 5, rating: 4.5, sessions: 180, phone: '0557654321', status: 'active' },
  { id: 3, name: 'فهد السبيعي', sport: 'تنس', experience: 12, rating: 4.9, sessions: 320, phone: '0509876543', status: 'active' },
  { id: 4, name: 'عمر الشهري', sport: 'سباحة', experience: 6, rating: 4.3, sessions: 140, phone: '0551122334', status: 'inactive' },
];

export const mockPlayers = [
  { id: 1, name: 'سلطان الدوسري', age: 22, sport: 'كرة قدم', level: 'متوسط', matches: 34, wins: 20, status: 'active', joinDate: '2024-01-15' },
  { id: 2, name: 'ناصر القحطاني', age: 25, sport: 'كرة سلة', level: 'محترف', matches: 67, wins: 50, status: 'active', joinDate: '2023-11-20' },
  { id: 3, name: 'ماجد العنزي', age: 19, sport: 'تنس', level: 'مبتدئ', matches: 12, wins: 5, status: 'inactive', joinDate: '2024-05-10' },
  { id: 4, name: 'بندر الحربي', age: 28, sport: 'كرة قدم', level: 'محترف', matches: 89, wins: 65, status: 'active', joinDate: '2023-08-01' },
  { id: 5, name: 'يوسف المطيري', age: 21, sport: 'ريشة طائرة', level: 'متوسط', matches: 28, wins: 14, status: 'active', joinDate: '2024-02-28' },
];

export const mockMatches = [
  { id: 1, team1: 'الهلال', team2: 'النصر', court: 'ملعب النور', date: '2025-06-15', time: '18:00', sport: 'كرة قدم', score: '3-1', status: 'completed' },
  { id: 2, team1: 'الاتحاد', team2: 'الأهلي', court: 'ملعب الأبطال', date: '2025-06-18', time: '20:00', sport: 'كرة قدم', score: '2-2', status: 'completed' },
  { id: 3, team1: 'فريق أ', team2: 'فريق ب', court: 'ملعب الفجر', date: '2025-07-01', time: '16:00', sport: 'كرة سلة', score: '-', status: 'upcoming' },
  { id: 4, team1: 'فريق النور', team2: 'فريق الأمل', court: 'ملعب التحدي', date: '2025-06-25', time: '19:00', sport: 'تنس', score: '6-3', status: 'completed' },
];

