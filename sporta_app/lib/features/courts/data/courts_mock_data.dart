import '../domain/entities/court_entity.dart';

final List<CourtEntity> mockCourts = [
  CourtEntity(
    id: '1',
    name: 'نادي البادل الملكي',
    rating: 4.8,
    reviews: 124,
    distance: '1.8 كم',
    distanceValue: 1.8,
    city: 'الدمام',
    neighborhood: 'العزيزية',
    country: 'السعودية',
    type: CourtType.indoor,
    gender: CourtGender.men,
    basePrice: 100,
    peakHourPrice: 150,
    availableTimes: [
      '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
      '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
      '18:00', '19:00', '20:00', '21:00', '22:00',
    ],
    availableDurations: [60, 90, 120],
    facilities: ['مواقف', 'كافيتيريا', 'غرف تبديل'],
  ),
  CourtEntity(
    id: '2',
    name: 'بادل كلوب الشرقية',
    rating: 4.6,
    reviews: 89,
    distance: '3.2 كم',
    distanceValue: 3.2,
    city: 'الخبر',
    neighborhood: 'الثقبة',
    country: 'السعودية',
    type: CourtType.outdoor,
    gender: CourtGender.women,
    basePrice: 80,
    peakHourPrice: 120,
    availableTimes: [
      '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
      '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
      '18:00', '19:00', '20:00', '21:00', '22:00',
    ],
    availableDurations: [60, 90],
    facilities: ['مواقف', 'غرف تبديل'],
  ),
  CourtEntity(
    id: '3',
    name: 'مركز بادل المدينة',
    rating: 4.9,
    reviews: 201,
    distance: '5.4 كم',
    distanceValue: 5.4,
    city: 'الدمام',
    neighborhood: 'الفيصلية',
    country: 'السعودية',
    type: CourtType.indoor,
    gender: CourtGender.family,
    basePrice: 120,
    peakHourPrice: 180,
    availableTimes: [
      '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
      '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
      '18:00', '19:00', '20:00', '21:00', '22:00',
    ],
    availableDurations: [90, 120],
    facilities: ['مواقف', 'كافيتيريا', 'غرف تبديل', 'ملاعب أطفال'],
  ),
  CourtEntity(
    id: '4',
    name: 'ملاعب الواحة',
    rating: 4.3,
    reviews: 56,
    distance: '4.1 كم',
    distanceValue: 4.1,
    city: 'القطيف',
    neighborhood: 'الجش',
    country: 'السعودية',
    type: CourtType.outdoor,
    gender: CourtGender.all,
    basePrice: 70,
    peakHourPrice: 100,
    availableTimes: [
      '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
      '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
      '18:00', '19:00', '20:00', '21:00', '22:00',
    ],
    availableDurations: [60, 120],
    facilities: ['مواقف'],
  ),
  CourtEntity(
    id: '5',
    name: 'نادي النخبة',
    rating: 4.7,
    reviews: 145,
    distance: '2.3 كم',
    distanceValue: 2.3,
    city: 'الخبر',
    neighborhood: 'العقربية',
    country: 'السعودية',
    type: CourtType.indoor,
    gender: CourtGender.men,
    basePrice: 110,
    peakHourPrice: 160,
    availableTimes: [
      '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
      '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
      '18:00', '19:00', '20:00', '21:00', '22:00',
    ],
    availableDurations: [60, 90, 120],
    facilities: ['مواقف', 'كافيتيريا', 'غرف تبديل', 'صالة لياقة'],
  ),
];

CourtEntity? findCourtById(String id) {
  try {
    return mockCourts.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

String courtTypeLabel(CourtType type) {
  switch (type) {
    case CourtType.indoor:
      return 'مغطى';
    case CourtType.outdoor:
      return 'مفتوح';
  }
}

String courtGenderLabel(CourtGender gender) {
  switch (gender) {
    case CourtGender.all:
      return 'مختلط';
    case CourtGender.men:
      return 'رجال';
    case CourtGender.women:
      return 'نساء';
    case CourtGender.family:
      return 'عائلي';
  }
}

List<CourtEntity> filterCourts({
  required List<CourtEntity> courts,
  required String query,
  required String sortBy,
  required String selectedCity,
  required CourtType? selectedType,
  required CourtGender? selectedGender,
  required String priceRange,
  required String ratingFilter,
}) {
  List<CourtEntity> result = List.from(courts);

  if (query.isNotEmpty) {
    result = result
        .where((c) =>
            c.name.contains(query) ||
            c.city.contains(query) ||
            c.neighborhood.contains(query))
        .toList();
  }

  if (selectedCity.isNotEmpty) {
    result = result.where((c) => c.city == selectedCity).toList();
  }

  if (selectedType != null) {
    result = result.where((c) => c.type == selectedType).toList();
  }

  if (selectedGender != null) {
    result = result.where((c) => c.gender == selectedGender).toList();
  }

  switch (priceRange) {
    case 'low':
      result = result.where((c) => c.basePrice < 80).toList();
      break;
    case 'medium':
      result = result
          .where((c) => c.basePrice >= 80 && c.basePrice <= 110)
          .toList();
      break;
    case 'high':
      result = result.where((c) => c.basePrice > 110).toList();
      break;
  }

  switch (ratingFilter) {
    case '4+':
      result = result.where((c) => c.rating >= 4.0).toList();
      break;
    case '4.5+':
      result = result.where((c) => c.rating >= 4.5).toList();
      break;
  }

  switch (sortBy) {
    case 'rating':
      result.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case 'price':
      result.sort((a, b) => a.basePrice.compareTo(b.basePrice));
      break;
    case 'distance':
      result.sort((a, b) => a.distanceValue.compareTo(b.distanceValue));
      break;
  }

  return result;
}
