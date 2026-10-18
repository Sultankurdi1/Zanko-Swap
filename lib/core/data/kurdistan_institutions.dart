enum EduOwnership { government, private }

enum EduKind { university, institute }

class EduDepartment {
  final String nameKu;
  final String nameEn;
  const EduDepartment(this.nameKu, this.nameEn);
}

class EduCollege {
  final String nameKu;
  final String nameEn;
  final List<EduDepartment> departments;
  const EduCollege(this.nameKu, this.nameEn, {this.departments = const []});
}

class EduInstitution {
  final String id;
  final String nameKu;
  final String nameEn;
  final String city;
  final EduOwnership ownership;
  final EduKind kind;
  final List<EduCollege> colleges;
  const EduInstitution({
    required this.id,
    required this.nameKu,
    required this.nameEn,
    required this.city,
    required this.ownership,
    required this.kind,
    this.colleges = const [],
  });

  String name(bool ku) => ku ? nameKu : nameEn;
}

const _genericAdminEconDepts = [
  EduDepartment('ژمێریاری', 'Accounting'),
  EduDepartment('کارگێڕی بازرگانی', 'Business Administration'),
  EduDepartment('ئابووری', 'Economics'),
  EduDepartment('باکگێڕی گشتی', 'Public Administration'),
  EduDepartment('دارایی و بانک', 'Finance and Banking'),
];

const _genericEngineeringDepts = [
  EduDepartment('ئەندازیاری شارستانی', 'Civil Engineering'),
  EduDepartment('ئەندازیاری کارەبا', 'Electrical Engineering'),
  EduDepartment('ئەندازیاری کۆمپیوتەر', 'Computer Engineering'),
  EduDepartment('ئەندازیاری میکانیک', 'Mechanical Engineering'),
  EduDepartment('ئەندازیاری ئارکیتێکچەر', 'Architecture Engineering'),
];

const _genericScienceDepts = [
  EduDepartment('زانستی کۆمپیوتەر', 'Computer Science'),
  EduDepartment('بیرکاری', 'Mathematics'),
  EduDepartment('فیزیا', 'Physics'),
  EduDepartment('کیمیا', 'Chemistry'),
  EduDepartment('گیانەوەری', 'Biology'),
];

const _genericEducationDepts = [
  EduDepartment('زانستە پەروەردەییەکان', 'Educational Sciences'),
  EduDepartment('زمانی کوردی', 'Kurdish Language'),
  EduDepartment('زمانی ئینگلیزی', 'English Language'),
  EduDepartment('بیرکاری', 'Mathematics'),
  EduDepartment('کیمیا', 'Chemistry'),
];

const _genericLawDepts = [
  EduDepartment('یاسا', 'Law'),
  EduDepartment('زانستی سیاسی', 'Political Science'),
];

const _commonColleges = [
  EduCollege(
    'کۆلێژی کارگێڕی و ئابووری',
    'College of Administration and Economics',
    departments: _genericAdminEconDepts,
  ),
  EduCollege(
    'کۆلێژی ئەندازیاری',
    'College of Engineering',
    departments: _genericEngineeringDepts,
  ),
  EduCollege(
    'کۆلێژی زانست',
    'College of Science',
    departments: _genericScienceDepts,
  ),
  EduCollege(
    'کۆلێژی پەروەردە',
    'College of Education',
    departments: _genericEducationDepts,
  ),
  EduCollege('کۆلێژی یاسا', 'College of Law', departments: _genericLawDepts),
  EduCollege('کۆلێژی زمان', 'College of Languages'),
  EduCollege('کۆلێژی هونەر', 'College of Arts'),
];

final List<EduInstitution> kurdistanInstitutions = [
  const EduInstitution(
    id: 'vocational5_erbil',
    nameKu: 'پەیمانگای پیشەیی خوێندنی ئینگلیزی - هەولێر (٥ ساڵ)',
    nameEn: 'English Vocational Institute - Erbil (5 years)',
    city: 'هەولێر',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
    colleges: [
      EduCollege('کۆمپیوتەر و IT', 'Computer & IT'),
      EduCollege('گرافیک و ئینتێریەر', 'Graphic & Interior Design'),
      EduCollege('بازرگانی و ژمێریاری', 'Business & Accounting'),
      EduCollege('گەشتوگوزار و میوانداری', 'Tourism & Hospitality'),
    ],
  ),
  const EduInstitution(
    id: 'vocational5_sulaymaniyah',
    nameKu: 'پەیمانگای پیشەیی خوێندنی ئینگلیزی - سلێمانی (٥ ساڵ)',
    nameEn: 'English Vocational Institute - Sulaymaniyah (5 years)',
    city: 'سلێمانی',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
    colleges: [
      EduCollege('کۆمپیوتەر و IT', 'Computer & IT'),
      EduCollege('گرافیک و ئینتێریەر', 'Graphic & Interior Design'),
      EduCollege('بازرگانی و ژمێریاری', 'Business & Accounting'),
      EduCollege('گەشتوگوزار و میوانداری', 'Tourism & Hospitality'),
    ],
  ),
  const EduInstitution(
    id: 'vocational5_garmian',
    nameKu: 'پەیمانگای پیشەیی خوێندنی ئینگلیزی - گەرمیان (٥ ساڵ)',
    nameEn: 'English Vocational Institute - Garmian (5 years)',
    city: 'گەرمیان',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
    colleges: [
      EduCollege('کۆمپیوتەر و IT', 'Computer & IT'),
      EduCollege('گرافیک و ئینتێریەر', 'Graphic & Interior Design'),
      EduCollege('بازرگانی و ژمێریاری', 'Business & Accounting'),
      EduCollege('گەشتوگوزار و میوانداری', 'Tourism & Hospitality'),
    ],
  ),
  const EduInstitution(
    id: 'vocational5_duhok',
    nameKu: 'پەیمانگای پیشەیی خوێندنی ئینگلیزی - دهۆک (٥ ساڵ)',
    nameEn: 'English Vocational Institute - Duhok (5 years)',
    city: 'دهۆک',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
    colleges: [
      EduCollege('کۆمپیوتەر و IT', 'Computer & IT'),
      EduCollege('گرافیک و ئینتێریەر', 'Graphic & Interior Design'),
      EduCollege('بازرگانی و ژمێریاری', 'Business & Accounting'),
      EduCollege('گەشتوگوزار و میوانداری', 'Tourism & Hospitality'),
    ],
  ),
  const EduInstitution(
    id: 'vocational5_halabja',
    nameKu: 'پەیمانگای پیشەیی خوێندنی ئینگلیزی - هەڵەبجە (٥ ساڵ)',
    nameEn: 'English Vocational Institute - Halabja (5 years)',
    city: 'هەڵەبجە',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
    colleges: [
      EduCollege('کۆمپیوتەر و IT', 'Computer & IT'),
      EduCollege('گرافیک و ئینتێریەر', 'Graphic & Interior Design'),
      EduCollege('بازرگانی و ژمێریاری', 'Business & Accounting'),
      EduCollege('گەشتوگوزار و میوانداری', 'Tourism & Hospitality'),
    ],
  ),
  const EduInstitution(
    id: 'vocational5_zakho',
    nameKu: 'پەیمانگای پیشەیی خوێندنی ئینگلیزی - زاخۆ (٥ ساڵ)',
    nameEn: 'English Vocational Institute - Zakho (5 years)',
    city: 'زاخۆ',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
    colleges: [
      EduCollege('کۆمپیوتەر و IT', 'Computer & IT'),
      EduCollege('گرافیک و ئینتێریەر', 'Graphic & Interior Design'),
      EduCollege('بازرگانی و ژمێریاری', 'Business & Accounting'),
      EduCollege('گەشتوگوزار و میوانداری', 'Tourism & Hospitality'),
    ],
  ),

  const EduInstitution(
    id: 'salahaddin_uni',
    nameKu: 'زانکۆی سەلاحەدین - هەولێر',
    nameEn: 'Salahaddin University-Erbil',
    city: 'هەولێر',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: [
      EduCollege(
        'کۆلێژی کارگێڕی و ئابووری',
        'College of Administration and Economics',
        departments: _genericAdminEconDepts,
      ),
      EduCollege(
        'کۆلێژی ئەندازیاری',
        'College of Engineering',
        departments: _genericEngineeringDepts,
      ),
      EduCollege(
        'کۆلێژی زانست',
        'College of Science',
        departments: _genericScienceDepts,
      ),
      EduCollege(
        'کۆلێژی پەروەردە',
        'College of Education',
        departments: _genericEducationDepts,
      ),
      EduCollege(
        'کۆلێژی یاسا و زانستی سیاسی',
        'College of Law and Political Science',
        departments: _genericLawDepts,
      ),
      EduCollege(
        'کۆلێژی کشتوکاڵ',
        'College of Agricultural Engineering Sciences',
      ),
      EduCollege('کۆلێژی زمان', 'College of Languages'),
      EduCollege('کۆلێژی هونەرە جوانەکان', 'College of Fine Arts'),
      EduCollege(
        'کۆلێژی وەرزش',
        'College of Physical Education and Sports Sciences',
      ),
      EduCollege('کۆلێژی ئاست', 'College of Arts'),
    ],
  ),
  const EduInstitution(
    id: 'duhok_uni',
    nameKu: 'زانکۆی دهۆک',
    nameEn: 'University of Duhok',
    city: 'دهۆک',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: [
      EduCollege(
        'کۆلێژی کارگێڕی و ئابووری',
        'College of Administration and Economics',
        departments: _genericAdminEconDepts,
      ),
      EduCollege(
        'کۆلێژی ئەندازیاری',
        'College of Engineering',
        departments: _genericEngineeringDepts,
      ),
      EduCollege(
        'کۆلێژی زانست',
        'College of Science',
        departments: _genericScienceDepts,
      ),
      EduCollege(
        'کۆلێژی پەروەردە',
        'College of Education',
        departments: _genericEducationDepts,
      ),
      EduCollege(
        'کۆلێژی یاسا',
        'College of Law',
        departments: _genericLawDepts,
      ),
      EduCollege('کۆلێژی پزیشکی', 'College of Medicine'),
    ],
  ),
  const EduInstitution(
    id: 'sulaimani_uni',
    nameKu: 'زانکۆی سلێمانی',
    nameEn: 'University of Sulaimani',
    city: 'سلێمانی',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: [
      EduCollege(
        'کۆلێژی کارگێڕی و ئابووری',
        'College of Administration and Economics',
        departments: _genericAdminEconDepts,
      ),
      EduCollege(
        'کۆلێژی ئەندازیاری',
        'College of Engineering',
        departments: _genericEngineeringDepts,
      ),
      EduCollege(
        'کۆلێژی زانست',
        'College of Science',
        departments: _genericScienceDepts,
      ),
      EduCollege('کۆلێژی پەروەردەی بنەڕەتی', 'College of Basic Education'),
      EduCollege(
        'کۆلێژی یاسا',
        'College of Law',
        departments: _genericLawDepts,
      ),
      EduCollege('کۆلێژی پزیشکی', 'College of Medicine'),
    ],
  ),
  const EduInstitution(
    id: 'hawler_medical_uni',
    nameKu: 'زانکۆی پزیشکی هەولێر',
    nameEn: 'Hawler Medical University',
    city: 'هەولێر',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: [
      EduCollege('کۆلێژی پزیشکی', 'College of Medicine'),
      EduCollege('کۆلێژی ددان', 'College of Dentistry'),
      EduCollege('کۆلێژی پەرستاری', 'College of Nursing'),
      EduCollege('کۆلێژی دەرمانسازی', 'College of Pharmacy'),
    ],
  ),
  const EduInstitution(
    id: 'koya_uni',
    nameKu: 'زانکۆی کۆیە',
    nameEn: 'Koya University',
    city: 'کۆیە',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'soran_uni',
    nameKu: 'زانکۆی سۆران',
    nameEn: 'Soran University',
    city: 'سۆران',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'raparin_uni',
    nameKu: 'زانکۆی ڕاپەرین',
    nameEn: 'University of Raparin',
    city: 'ڕانیە',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'halabja_uni',
    nameKu: 'زانکۆی هەڵەبجە',
    nameEn: 'University of Halabja',
    city: 'هەڵەبجە',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'garmian_uni',
    nameKu: 'زانکۆی گەرمیان',
    nameEn: 'University of Garmian',
    city: 'کەلار',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'zakho_uni',
    nameKu: 'زانکۆی زاخۆ',
    nameEn: 'University of Zakho',
    city: 'زاخۆ',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'charmo_uni',
    nameKu: 'زانکۆی چەرمۆ',
    nameEn: 'Charmo University',
    city: 'چەمچەماڵ',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'akre_uni',
    nameKu: 'زانکۆی ئاکرێ',
    nameEn: 'University of Akre',
    city: 'ئاکرێ',
    ownership: EduOwnership.government,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),

  const EduInstitution(
    id: 'ishik_uni',
    nameKu: 'زانکۆی ئیشیک',
    nameEn: 'Ishik University',
    city: 'هەولێر',
    ownership: EduOwnership.private,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'tishk_uni',
    nameKu: 'زانکۆی تیشک',
    nameEn: 'Tishk International University',
    city: 'هەولێر',
    ownership: EduOwnership.private,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'cihan_uni_erbil',
    nameKu: 'زانکۆی جیهان - هەولێر',
    nameEn: 'Cihan University-Erbil',
    city: 'هەولێر',
    ownership: EduOwnership.private,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'cihan_uni_slemani',
    nameKu: 'زانکۆی جیهان - سلێمانی',
    nameEn: 'Cihan University-Sulaimaniya',
    city: 'سلێمانی',
    ownership: EduOwnership.private,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'american_uni_kurdistan',
    nameKu: 'زانکۆی ئەمەریکی لە کوردستان',
    nameEn: 'American University of Kurdistan',
    city: 'دهۆک',
    ownership: EduOwnership.private,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'lebanese_french_uni',
    nameKu: 'زانکۆی لوبنانی فەرەنسی',
    nameEn: 'Lebanese French University',
    city: 'هەولێر',
    ownership: EduOwnership.private,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'catholic_uni_erbil',
    nameKu: 'زانکۆی کاسۆلیکی - هەولێر',
    nameEn: 'Catholic University in Erbil',
    city: 'هەولێر',
    ownership: EduOwnership.private,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'komar_uni',
    nameKu: 'زانکۆی کۆمار',
    nameEn: 'Komar University of Science and Technology',
    city: 'سلێمانی',
    ownership: EduOwnership.private,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'qaiwan_uni',
    nameKu: 'زانکۆی قەیوان',
    nameEn: 'Qaiwan International University',
    city: 'سلێمانی',
    ownership: EduOwnership.private,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),
  const EduInstitution(
    id: 'university_kurdistan_hewler',
    nameKu: 'زانکۆی کوردستان - هەولێر (UKH)',
    nameEn: 'University of Kurdistan Hewler (UKH)',
    city: 'هەولێر',
    ownership: EduOwnership.private,
    kind: EduKind.university,
    colleges: _commonColleges,
  ),

  const EduInstitution(
    id: 'erbil_polytechnic',
    nameKu: 'زانکۆی پۆلیتەکنیکی هەولێر',
    nameEn: 'Erbil Polytechnic University',
    city: 'هەولێر',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
  ),
  const EduInstitution(
    id: 'sulaimani_polytechnic',
    nameKu: 'زانکۆی پۆلیتەکنیکی سلێمانی',
    nameEn: 'Sulaimani Polytechnic University',
    city: 'سلێمانی',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
  ),
  const EduInstitution(
    id: 'duhok_polytechnic',
    nameKu: 'زانکۆی پۆلیتەکنیکی دهۆک',
    nameEn: 'Duhok Polytechnic University',
    city: 'دهۆک',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
  ),
  const EduInstitution(
    id: 'technical_institute_erbil',
    nameKu: 'پەیمانگای تەکنیکی هەولێر',
    nameEn: 'Erbil Technical Institute',
    city: 'هەولێر',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
  ),
  const EduInstitution(
    id: 'technical_institute_slemani',
    nameKu: 'پەیمانگای تەکنیکی سلێمانی',
    nameEn: 'Sulaimani Technical Institute',
    city: 'سلێمانی',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
  ),
  const EduInstitution(
    id: 'technical_institute_duhok',
    nameKu: 'پەیمانگای تەکنیکی دهۆک',
    nameEn: 'Duhok Technical Institute',
    city: 'دهۆک',
    ownership: EduOwnership.government,
    kind: EduKind.institute,
  ),
];

const List<String> academicStages = [
  'قۆناغی یەکەم',
  'قۆناغی دووەم',
  'قۆناغی سێیەم',
  'قۆناغی چوارەم',
  'قۆناغی پێنجەم',
  'تەواوکار / دەرچوو',
];
