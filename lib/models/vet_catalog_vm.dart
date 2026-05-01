/// Veterinario del cat\u00E1logo p\u00FAblico ([GET /api/vets]).
class VetCatalogVm {
  const VetCatalogVm({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.specialty,
    this.acceptsEmergencies = false,
    this.onDuty = false,
    this.baseLatitude,
    this.baseLongitude,
    this.coverageRadiusKm,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final String? specialty;
  final bool acceptsEmergencies;
  final bool onDuty;
  final double? baseLatitude;
  final double? baseLongitude;
  final double? coverageRadiusKm;

  String get displaySubtitle {
    final parts = <String>[];
    if (specialty != null && specialty!.trim().isNotEmpty) {
      parts.add(specialty!.trim());
    }
    if (onDuty) {
      parts.add('En turno');
    } else {
      parts.add('Fuera de turno');
    }
    if (!acceptsEmergencies) {
      parts.add('Sin urgencias');
    }
    return parts.join(' \u00B7 ');
  }

  factory VetCatalogVm.fromJson(Map<String, dynamic> j) {
    double? d(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return VetCatalogVm(
      id: j['id'] as String? ?? '',
      fullName: (j['full_name'] as String?)?.trim() ?? '',
      avatarUrl: j['avatar_url'] as String?,
      phone: j['phone'] as String?,
      specialty: j['specialty'] as String?,
      acceptsEmergencies: j['accepts_emergencies'] == true,
      onDuty: j['on_duty'] == true,
      baseLatitude: d(j['base_latitude']),
      baseLongitude: d(j['base_longitude']),
      coverageRadiusKm: d(j['coverage_radius_km']),
    );
  }
}
