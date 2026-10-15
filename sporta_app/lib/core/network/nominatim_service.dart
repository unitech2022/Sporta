import 'package:dio/dio.dart';

/// A single forward-search result.
class GeocodeResult {
  const GeocodeResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;

  factory GeocodeResult.fromJson(Map<String, dynamic> json) => GeocodeResult(
        displayName: json['display_name'] as String,
        latitude: double.parse(json['lat'] as String),
        longitude: double.parse(json['lon'] as String),
      );
}

/// A resolved (reverse-geocoded) address, split into the parts the
/// registration/venue forms actually use plus a full display string.
class ResolvedAddress {
  const ResolvedAddress({required this.displayName, this.city, this.district});

  final String displayName;
  final String? city;
  final String? district;
}

/// Thin client for OpenStreetMap's Nominatim geocoding API — deliberately a
/// plain unauthenticated [Dio] instance (not [ApiClient].instance.dio) so the
/// Sporta backend's bearer token never leaks to a third-party host. Free,
/// keyless, but rate-limited to ~1 request/second per their usage policy;
/// callers are expected to debounce.
class NominatimService {
  NominatimService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://nominatim.openstreetmap.org',
          headers: const {
            // Nominatim's usage policy requires an identifying User-Agent.
            'User-Agent': 'SportaApp/1.0 (https://apis.sportaapp.net)',
          },
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ));

  final Dio _dio;

  Future<ResolvedAddress?> reverse(double lat, double lon) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/reverse', queryParameters: {
        'format': 'jsonv2',
        'lat': lat,
        'lon': lon,
        'addressdetails': 1,
        'accept-language': 'ar',
      });
      final data = res.data;
      if (data == null || data['display_name'] == null) return null;
      final address = (data['address'] as Map?)?.cast<String, dynamic>();
      return ResolvedAddress(
        displayName: data['display_name'] as String,
        city: _firstNonEmpty(address, ['city', 'town', 'village', 'municipality']),
        district: _firstNonEmpty(address, ['suburb', 'neighbourhood', 'quarter', 'city_district']),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<GeocodeResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final res = await _dio.get<List<dynamic>>('/search', queryParameters: {
        'format': 'jsonv2',
        'q': query.trim(),
        'accept-language': 'ar',
        'limit': 6,
      });
      final data = res.data ?? [];
      return data
          .cast<Map<String, dynamic>>()
          .map(GeocodeResult.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String? _firstNonEmpty(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
