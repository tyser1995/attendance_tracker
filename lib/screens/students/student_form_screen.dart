import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../providers/course_provider.dart';

class StudentFormScreen extends ConsumerStatefulWidget {
  final String? studentId;
  const StudentFormScreen({super.key, this.studentId});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _fnCtrl = TextEditingController();
  final _lnCtrl = TextEditingController();
  final _mnCtrl = TextEditingController();

  String? _selectedCourseId;
  String _sex = 'M';
  String _dob = '';
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.studentId != null;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudent());
    }
  }

  void _loadStudent() async {
    final student = await ref.read(studentSourceProvider).getById(widget.studentId!);
    if (student != null && mounted) {
      setState(() {
        _idCtrl.text = student.idNumber;
        _fnCtrl.text = student.firstName;
        _lnCtrl.text = student.lastName;
        _mnCtrl.text = student.middleName ?? '';
        _selectedCourseId = student.courseId;
        _sex = student.sex ?? 'M';
        _dob = student.dateOfBirth ?? '';
      });
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose(); _fnCtrl.dispose(); _lnCtrl.dispose(); _mnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final formState = ref.watch(studentNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Student' : 'Add Student')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Card(title: 'Personal Information', children: [
              TextFormField(
                controller: _idCtrl,
                decoration: const InputDecoration(labelText: 'ID Number *', prefixIcon: Icon(Icons.badge_rounded)),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _fnCtrl,
                    decoration: const InputDecoration(labelText: 'First Name *'),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lnCtrl,
                    decoration: const InputDecoration(labelText: 'Last Name *'),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mnCtrl,
                decoration: const InputDecoration(labelText: 'Middle Name (optional)'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sex,
                    decoration: const InputDecoration(labelText: 'Sex'),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Male')),
                      DropdownMenuItem(value: 'F', child: Text('Female')),
                    ],
                    onChanged: (v) { if (v != null) setState(() => _sex = v); },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _DatePicker(
                  label: 'Date of Birth',
                  value: _dob,
                  onChanged: (v) => setState(() => _dob = v),
                )),
              ]),
            ]),
            const SizedBox(height: 12),
            _Card(title: 'Academic Information', children: [
              coursesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppTheme.danger)),
                data: (courses) => DropdownButtonFormField<String>(
                  initialValue: _selectedCourseId,
                  decoration: const InputDecoration(labelText: 'Course *', prefixIcon: Icon(Icons.school_rounded)),
                  items: courses.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.courseCode} - ${c.courseName}'))).toList(),
                  onChanged: (v) => setState(() => _selectedCourseId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
            ]),
            const SizedBox(height: 24),
            if (formState.hasError)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${formState.error}', style: const TextStyle(color: AppTheme.danger)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: formState.isLoading ? null : _submit,
                child: formState.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Save Changes' : 'Add Student'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    const uuid = Uuid();
    final student = Student(
      id: _isEdit ? widget.studentId! : uuid.v4(),
      idNumber: _idCtrl.text.trim(),
      firstName: _fnCtrl.text.trim(),
      lastName: _lnCtrl.text.trim(),
      middleName: _mnCtrl.text.trim().isEmpty ? null : _mnCtrl.text.trim(),
      dateOfBirth: _dob.isEmpty ? null : _dob,
      sex: _sex,
      courseId: _selectedCourseId,
    );
    final ok = await ref.read(studentNotifierProvider.notifier).save(student, isEdit: _isEdit);
    if (ok && mounted) context.go('/students/${student.id}');
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _DatePicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value.isNotEmpty ? DateTime.tryParse(value) ?? DateTime(2003) : DateTime(2003),
          firstDate: DateTime(1980),
          lastDate: DateTime.now(),
        );
        if (date != null) onChanged(AppUtils.toDateStr(date));
      },
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_rounded),
          ),
          controller: TextEditingController(text: value.isEmpty ? '' : AppUtils.formatDate(value)),
        ),
      ),
    );
  }
}
