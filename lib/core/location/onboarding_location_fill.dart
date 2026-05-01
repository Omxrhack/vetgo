import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Result of resolving GPS + reverse geocode for onboarding address fields.
final class OnboardingLocationFillResult {
  const OnboardingLocationFillResult._({
    required this.ok,
    this.latitude,
    this.longitude,
    this.addressText,
    this.errorMessage,
  });

  final bool ok;
  final double? latitude;
  final double? longitude;
  final String? addressText;
  final String? errorMessage;

  factory OnboardingLocationFillResult.success({
    required double latitude,
    required double longitude,
    required String addressText,
  }) {
    return OnboardingLocationFillResult._(
      ok: true,
      latitude: latitude,
      longitude: longitude,
      addressText: addressText,
    );
  }

  factory OnboardingLocationFillResult.failure(String message) {
    return OnboardingLocationFillResult._(ok: false, errorMessage: message);
  }
}

String _formatPlacemark(Placemark p) {
  final streetParts = <String>[
    if ((p.subThoroughfare ?? '').trim().isNotEmpty) p.subThoroughfare!.trim(),
    if ((p.thoroughfare ?? '').trim().isNotEmpty) p.thoroughfare!.trim(),
  ];
  var line1 = streetParts.join(' ').trim();
  if (line1.isEmpty && (p.street ?? '').trim().isNotEmpty) {
    line1 = p.street!.trim();
  }

  final localityParts = <String>[
    if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
    if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
  ];
  final line2 = localityParts.join(', ').trim();

  final regionParts = <String>[
    if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea!.trim(),
    if ((p.postalCode ?? '').trim().isNotEmpty) p.postalCode!.trim(),
  ];
  final line3 = regionParts.join(' ').trim();

  final country = (p.country ?? '').trim();

  final segments = <String>[
    if (line1.isNotEmpty) line1,
    if (line2.isNotEmpty) line2,
    if (line3.isNotEmpty) line3,
    if (country.isNotEmpty) country,
  ];
  return segments.join(', ');
}

/// Obtiene posici\u00F3n actual y direcci\u00F3n aproximada (geocodificaci\u00F3n inversa).
Future<OnboardingLocationFillResult> loadAddressFromDeviceLocation() async {
  if (kIsWeb) {
    return OnboardingLocationFillResult.failure(
      'En la versi\u00F3n web escribe la direcci\u00F3n manualmente.',
    );
  }
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return OnboardingLocationFillResult.failure(
        'Activa el GPS o los servicios de ubicaci\u00F3n.',
      );
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      return OnboardingLocationFillResult.failure(
        'Se necesita permiso de ubicaci\u00F3n.',
      );
    }
    if (perm == LocationPermission.deniedForever) {
      return OnboardingLocationFillResult.failure(
        'Permiso denegado. Act\u00EDvalo en Ajustes del dispositivo.',
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (placemarks.isEmpty) {
      return OnboardingLocationFillResult.failure(
        'No se encontr\u00F3 una direcci\u00F3n para esta ubicaci\u00F3n.',
      );
    }

    final formatted = _formatPlacemark(placemarks.first).trim();
    if (formatted.length < 5) {
      return OnboardingLocationFillResult.failure(
        'Direcci\u00F3n incompleta; compl\u00E9tala manualmente.',
      );
    }

    return OnboardingLocationFillResult.success(
      latitude: pos.latitude,
      longitude: pos.longitude,
      addressText: formatted,
    );
  } catch (_) {
    return OnboardingLocationFillResult.failure(
      'No se pudo obtener la ubicaci\u00F3n. Intenta de nuevo.',
    );
  }
}
