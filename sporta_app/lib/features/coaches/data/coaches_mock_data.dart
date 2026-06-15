import '../domain/entities/coach_entity.dart';

final List<CoachEntity> mockCoaches = [
  CoachEntity(
    id: 'coach-1',
    name: 'محمد أحمد',
    avatarInitials: 'م.أ',
    rating: 4.9,
    reviews: 87,
    students: 152,
    levelMin: 0,
    levelMax: 7,
    location: 'نادي البادل الملكي',
    distanceKm: 1.8,
    price: 200,
    specialties: ['تقنيات متقدمة', 'استراتيجية اللعب', 'التحليل الفني'],
    badgeLabel: 'معتمد',
    badgeType: 'certified',
    avatarGradientColors: ['#2AB5CE', '#1E9AB0'],
    isBooked: true,
  ),
  CoachEntity(
    id: 'coach-2',
    name: 'سارة عبدالله',
    avatarInitials: 'س.ع',
    rating: 4.7,
    reviews: 64,
    students: 98,
    levelMin: 0,
    levelMax: 5,
    location: 'بادل كلوب الشرقية',
    distanceKm: 3.2,
    price: 150,
    specialties: ['تدريب مبتدئين', 'الأساسيات', 'اللياقة البدنية'],
    badgeLabel: 'نساء',
    badgeType: 'women',
    avatarGradientColors: ['#0A2540', '#1A3A5C'],
    isBooked: false,
  ),
  CoachEntity(
    id: 'coach-3',
    name: 'خالد محمود',
    avatarInitials: 'خ.م',
    rating: 4.8,
    reviews: 112,
    students: 203,
    levelMin: 3,
    levelMax: 7,
    location: 'مركز بادل المدينة',
    distanceKm: 5.4,
    price: 280,
    specialties: ['إعداد احترافي', 'المنافسات', 'التكتيك المتقدم'],
    badgeLabel: 'محترف',
    badgeType: 'pro',
    avatarGradientColors: ['#16A34A', '#15803D'],
    isBooked: false,
  ),
];

CoachEntity? findCoachById(String id) {
  try {
    return mockCoaches.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
