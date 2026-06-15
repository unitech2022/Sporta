import '../../../../core/state/app_settings.dart';

class RegistrationData {
  RegistrationData();

  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String password = '';
  String country = 'السعودية';
  String city = '';
  String district = '';
  String gender = '';
  final Set<UserRole> roles = {};

  // Coach role details (collected when [UserRole.coach] is selected).
  String coachBio = '';
  String coachSpecialization = '';
  String coachHourlyRate = '';

  // Venue role details (collected when [UserRole.venue] is selected).
  String venueName = '';
  String venueDescription = '';
  String venueAddress = '';
  String venueCity = '';
  String venueGenderPolicy = 'mixed';

  bool get hasBasicInfo =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      email.isNotEmpty &&
      phone.isNotEmpty &&
      password.isNotEmpty &&
      gender.isNotEmpty &&
      city.isNotEmpty;

  bool get needsCoachDetails => roles.contains(UserRole.coach);
  bool get needsVenueDetails => roles.contains(UserRole.venue);

  /// Whether an extra step is required to collect coach/venue details.
  bool get needsRoleDetails => needsCoachDetails || needsVenueDetails;
}
