import 'package:flutter/material.dart';
import '../../core/data/custom_institutions.dart';
import '../../core/data/kurdistan_institutions.dart';
import '../../core/localization/app_strings.dart';
import '../../core/models/academic_path.dart';

class AcademicPathPicker extends StatefulWidget {
  final AcademicPath initialValue;
  final ValueChanged<AcademicPath> onChanged;
  const AcademicPathPicker({
    super.key,
    this.initialValue = const AcademicPath(),
    required this.onChanged,
  });

  @override
  State<AcademicPathPicker> createState() => _AcademicPathPickerState();
}

class _AcademicPathPickerState extends State<AcademicPathPicker> {
  EduInstitution? institution;
  EduCollege? college;
  String? department;
  String? stage;

  final _collegeCustom = TextEditingController();
  final _deptCustom = TextEditingController();
  List<EduInstitution> allInstitutions = kurdistanInstitutions;

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
    if (widget.initialValue.institutionId.isNotEmpty) {
      institution = kurdistanInstitutions
          .where((x) => x.id == widget.initialValue.institutionId)
          .cast<EduInstitution?>()
          .firstOrNull;
    }
    stage = widget.initialValue.stage.isNotEmpty
        ? widget.initialValue.stage
        : null;
    _collegeCustom.text = widget.initialValue.collegeName;
    _deptCustom.text = widget.initialValue.departmentName;
  }

  Future<void> _loadInstitutions() async {
    final all = await CustomInstitutionsService.getAll();
    if (!mounted) return;
    setState(() {
      allInstitutions = all;
      final initialId = widget.initialValue.institutionId;
      if (institution == null && initialId.isNotEmpty) {
        institution = all
            .where((x) => x.id == initialId)
            .cast<EduInstitution?>()
            .firstOrNull;
      }
    });
  }

  Future<void> _addCustomInstitution() async {
    final s = AppStrings.of(context);
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final collegesCtrl = TextEditingController();
    EduKind kind = EduKind.institute;
    final saved = await showDialog<EduInstitution>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            s.isKurdish
                ? 'زیادکردنی پەیمانگا / زانکۆ'
                : s.isArabic
                ? 'إضافة معهد / جامعة'
                : 'Add institute / university',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: s.isKurdish ? 'ناوی پەیمانگا / زانکۆ' : 'Name',
                    hintText: s.isKurdish
                        ? 'بۆ نموونە: پەیمانگای نیشتمانی'
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityCtrl,
                  decoration: InputDecoration(
                    labelText: s.isKurdish ? 'شار' : 'City',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<EduKind>(
                  initialValue: kind,
                  decoration: InputDecoration(
                    labelText: s.isKurdish ? 'جۆر' : 'Type',
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: EduKind.institute,
                      child: Text(
                        s.isKurdish
                            ? 'پەیمانگا'
                            : s.isArabic
                            ? 'معهد'
                            : 'Institute',
                      ),
                    ),
                    DropdownMenuItem(
                      value: EduKind.university,
                      child: Text(
                        s.isKurdish
                            ? 'زانکۆ'
                            : s.isArabic
                            ? 'جامعة'
                            : 'University',
                      ),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => kind = v ?? kind),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: collegesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: s.isKurdish
                        ? 'کۆلێژەکان (بە کۆما جیابکە)'
                        : 'Colleges (comma separated)',
                    hintText: s.isKurdish
                        ? 'نەشتەوانگ، زانست، ئەدەبیات'
                        : 'IT, Science, Arts',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final inst = await CustomInstitutionsService.add(
                  name: nameCtrl.text.trim(),
                  city: cityCtrl.text.trim().isEmpty
                      ? '-'
                      : cityCtrl.text.trim(),
                  ownership: EduOwnership.government,
                  kind: kind,
                  colleges: collegesCtrl.text
                      .split(',')
                      .map((x) => x.trim())
                      .where((x) => x.isNotEmpty)
                      .toList(),
                );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx, inst);
              },
              child: Text(s.add),
            ),
          ],
        ),
      ),
    );
    if (saved != null) {
      await _loadInstitutions();
      if (mounted) {
        setState(() {
          institution = saved;
          college = null;
          department = null;
          _collegeCustom.clear();
          _deptCustom.clear();
        });
        _emit();
      }
    }
  }

  @override
  void dispose() {
    _collegeCustom.dispose();
    _deptCustom.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      AcademicPath(
        institutionId: institution?.id ?? '',
        institutionName: institution?.name(true) ?? '',
        collegeName: college?.nameKu ?? _collegeCustom.text.trim(),
        departmentName: department ?? _deptCustom.text.trim(),
        stage: stage ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final govList = allInstitutions
        .where((x) => x.ownership == EduOwnership.government)
        .toList();
    final privList = allInstitutions
        .where((x) => x.ownership == EduOwnership.private)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.academicPath,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EduInstitution>(
              initialValue: institution,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: s.universityOrInstitute,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  tooltip: s.isKurdish
                      ? 'زیادکردنی پەیمانگا / زانکۆ'
                      : s.isArabic
                      ? 'إضافة معهد / جامعة'
                      : 'Add institute / university',
                  onPressed: _addCustomInstitution,
                ),
              ),
              items: [
                ...govList.map(
                  (x) => DropdownMenuItem(
                    value: x,
                    child: Text(
                      '${s.governmentSection} — ${x.name(s.isKurdish)} (${x.city})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                ...privList.map(
                  (x) => DropdownMenuItem(
                    value: x,
                    child: Text(
                      '${s.privateSection} — ${x.name(s.isKurdish)} (${x.city})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  institution = v;
                  college = null;
                  department = null;
                  _collegeCustom.clear();
                  _deptCustom.clear();
                });
                _emit();
              },
            ),
            if (institution != null) ...[
              const SizedBox(height: 12),
              if (institution!.colleges.isNotEmpty)
                DropdownButtonFormField<EduCollege>(
                  initialValue: college,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: s.college,
                    border: const OutlineInputBorder(),
                  ),
                  items: institution!.colleges
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            s.isKurdish ? c.nameKu : c.nameEn,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      college = v;
                      department = null;
                      _deptCustom.clear();
                    });
                    _emit();
                  },
                )
              else
                TextField(
                  controller: _collegeCustom,
                  decoration: InputDecoration(
                    labelText: s.college,
                    border: const OutlineInputBorder(),
                    helperText: s.typeManually,
                  ),
                  onChanged: (_) => _emit(),
                ),
            ],
            if (institution != null &&
                (college != null || _collegeCustom.text.trim().isNotEmpty)) ...[
              const SizedBox(height: 12),
              if (college != null && college!.departments.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: department,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: s.department,
                    border: const OutlineInputBorder(),
                  ),
                  items: college!.departments
                      .map(
                        (d) => DropdownMenuItem(
                          value: s.isKurdish ? d.nameKu : d.nameEn,
                          child: Text(
                            s.isKurdish ? d.nameKu : d.nameEn,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => department = v);
                    _emit();
                  },
                )
              else
                TextField(
                  controller: _deptCustom,
                  decoration: InputDecoration(
                    labelText: s.department,
                    border: const OutlineInputBorder(),
                    helperText: s.typeManually,
                  ),
                  onChanged: (_) => _emit(),
                ),
            ],
            if (institution != null) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: stage,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.stageLabel,
                  border: const OutlineInputBorder(),
                ),
                items: academicStages.map((x) {
                  final stageIndex = academicStages.indexOf(x);
                  const arabicStages = [
                    'المرحلة الأولى',
                    'المرحلة الثانية',
                    'المرحلة الثالثة',
                    'المرحلة الرابعة',
                    'المرحلة الخامسة',
                    'إكمال الدراسة / التخرج',
                  ];
                  return DropdownMenuItem(
                    value: x,
                    child: Text(s.isArabic ? arabicStages[stageIndex] : x),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => stage = v);
                  _emit();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
