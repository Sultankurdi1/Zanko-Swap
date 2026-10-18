import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
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
    final govList = kurdistanInstitutions
        .where((x) => x.ownership == EduOwnership.government)
        .toList();
    final privList = kurdistanInstitutions
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
