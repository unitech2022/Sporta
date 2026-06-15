import '../domain/entities/court_entity.dart';

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

/// Client-side filtering/sorting applied on top of the courts returned by the
/// API (search text, price band, rating, sort order).
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
