import 'package:flutter/material.dart';

enum InstitutionType { school, institute, vocationalFiveYear, college }

class Institution {
  final String id;
  final InstitutionType type;
  final String nameKu,
      nameEn,
      province,
      city,
      sector,
      descriptionKu,
      descriptionEn,
      websiteUrl,
      instagramUrl,
      facebookUrl,
      phone,
      address,
      logoUrl;
  final bool active;
  final int durationYears;
  final bool admissionAfterGrade9;
  final String studyLanguage, specialties;
  const Institution({
    required this.id,
    required this.type,
    required this.nameKu,
    required this.nameEn,
    required this.city,
    this.province = '',
    this.sector = 'government',
    this.descriptionKu = '',
    this.descriptionEn = '',
    this.websiteUrl = '',
    this.instagramUrl = '',
    this.facebookUrl = '',
    this.phone = '',
    this.address = '',
    this.logoUrl = '',
    this.active = true,
    this.durationYears = 0,
    this.admissionAfterGrade9 = false,
    this.studyLanguage = '',
    this.specialties = '',
  });
  factory Institution.fromMap(Map<String, dynamic> d) {
    final t = InstitutionType.values.firstWhere(
      (x) => x.name == '${d['type'] ?? 'college'}',
      orElse: () => InstitutionType.college,
    );
    return Institution(
      id: '${d['id'] ?? ''}',
      type: t,
      nameKu: '${d['nameKu'] ?? ''}',
      nameEn: '${d['nameEn'] ?? ''}',
      province: '${d['province'] ?? ''}',
      city: '${d['city'] ?? ''}',
      sector: '${d['sector'] ?? 'government'}',
      descriptionKu: '${d['descriptionKu'] ?? ''}',
      descriptionEn: '${d['descriptionEn'] ?? ''}',
      websiteUrl: '${d['websiteUrl'] ?? ''}',
      instagramUrl: '${d['instagramUrl'] ?? ''}',
      facebookUrl: '${d['facebookUrl'] ?? ''}',
      phone: '${d['phone'] ?? ''}',
      address: '${d['address'] ?? ''}',
      logoUrl: '${d['logoUrl'] ?? ''}',
      active: d['active'] != false,
      durationYears: (d['durationYears'] as num?)?.toInt() ?? 0,
      admissionAfterGrade9: d['admissionAfterGrade9'] == true,
      studyLanguage: '${d['studyLanguage'] ?? ''}',
      specialties: '${d['specialties'] ?? ''}',
    );
  }
  Map<String, dynamic> toMap() => {
    'type': type.name,
    'nameKu': nameKu,
    'nameEn': nameEn,
    'province': province,
    'city': city,
    'sector': sector,
    'descriptionKu': descriptionKu,
    'descriptionEn': descriptionEn,
    'websiteUrl': websiteUrl,
    'instagramUrl': instagramUrl,
    'facebookUrl': facebookUrl,
    'phone': phone,
    'address': address,
    'logoUrl': logoUrl,
    'active': active,
    'durationYears': durationYears,
    'admissionAfterGrade9': admissionAfterGrade9,
    'studyLanguage': studyLanguage,
    'specialties': specialties,
  };
  String name(bool ku) => ku ? nameKu : nameEn;
  String description(bool ku) => ku ? descriptionKu : descriptionEn;
  IconData get icon => switch (type) {
    InstitutionType.school => Icons.school_rounded,
    InstitutionType.institute => Icons.apartment_rounded,
    InstitutionType.vocationalFiveYear => Icons.construction_rounded,
    InstitutionType.college => Icons.account_balance_rounded,
  };
}
