import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/state/data_signals.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/venue_repository.dart';
import '../../domain/entities/owner_venue.dart';

part 'manage_venues_state.dart';

/// Drives the venue-owner management screen: list venues + create venue / court.
class ManageVenuesCubit extends Cubit<ManageVenuesState> {
  ManageVenuesCubit(this._repository) : super(const ManageVenuesState());

  final VenueRepository _repository;

  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: ManageVenuesStatus.loading, error: null));
    try {
      final venues = await _repository.fetchMyVenues();
      emit(state.copyWith(status: ManageVenuesStatus.success, venues: venues));
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: ManageVenuesStatus.failure, error: e.display),
      );
    }
  }

  /// Returns an error message on failure (null on success).
  Future<String?> createVenue({
    required String name,
    String? nameEn,
    String? city,
    String? district,
    required int cityId,
    required int districtId,
    required String address,
    double? latitude,
    double? longitude,
    List<String> imageUrls = const [],
    int courtCount = 1,
    double pricePerHour = 0,
    List<CourtTier> bookingTiers = const [],
    bool isArabic = true,
  }) async {
    try {
      await _repository.createVenue(
        name: name,
        nameEn: nameEn,
        city: city,
        district: district,
        cityId: cityId,
        districtId: districtId,
        address: address,
        latitude: latitude,
        longitude: longitude,
        imageUrls: imageUrls,
        courtCount: courtCount,
        pricePerHour: pricePerHour,
        bookingTiers: bookingTiers,
      );
      await load(isArabic: isArabic);
      // لوحة المنشأة في تبويب آخر حيّ داخل IndexedStack — تسمع الإشارة فتتحدّث.
      DataSignals.venuesChanged();
      return null;
    } on ApiException catch (e) {
      return e.display;
    }
  }

  Future<String?> addCourt({
    required int venueId,
    required String name,
    required String type,
    required double pricePerHour,
    int courtCount = 1,
    String? imageUrl,
    double? latitude,
    double? longitude,
    List<CourtTier> bookingTiers = const [],
    bool isArabic = true,
  }) async {
    try {
      await _repository.addCourt(
        venueId: venueId,
        name: name,
        type: type,
        pricePerHour: pricePerHour,
        courtCount: courtCount,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        bookingTiers: bookingTiers,
      );
      await load(isArabic: isArabic);
      // لوحة المنشأة في تبويب آخر حيّ داخل IndexedStack — تسمع الإشارة فتتحدّث.
      DataSignals.venuesChanged();
      return null;
    } on ApiException catch (e) {
      return e.display;
    }
  }

  Future<String?> updateCourt({
    required int courtId,
    required double pricePerHour,
    required bool isAvailable,
    int courtCount = 1,
    String? imageUrl,
    double? latitude,
    double? longitude,
    List<CourtTier> bookingTiers = const [],
    bool isArabic = true,
  }) async {
    try {
      await _repository.updateCourt(
        courtId: courtId,
        pricePerHour: pricePerHour,
        isAvailable: isAvailable,
        courtCount: courtCount,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        bookingTiers: bookingTiers,
      );
      await load(isArabic: isArabic);
      // لوحة المنشأة في تبويب آخر حيّ داخل IndexedStack — تسمع الإشارة فتتحدّث.
      DataSignals.venuesChanged();
      return null;
    } on ApiException catch (e) {
      return e.display;
    }
  }

  Future<String?> deleteCourt(int courtId, {bool isArabic = true}) async {
    try {
      await _repository.deleteCourt(courtId);
      await load(isArabic: isArabic);
      // لوحة المنشأة في تبويب آخر حيّ داخل IndexedStack — تسمع الإشارة فتتحدّث.
      DataSignals.venuesChanged();
      return null;
    } on ApiException catch (e) {
      return e.display;
    }
  }
}
