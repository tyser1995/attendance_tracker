import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';

class CourseFormScreen extends ConsumerStatefulWidget {
  final String? courseId;
  const CourseFormScreen({super.key, this.courseId});

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.courseId != null;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  void _load() async {
    final course = await ref.read(courseSourceProvider).getById(widget.courseId!);
    if (course != null && mounted) {
      _codeCtrl.text = course.courseCode;
      _nameCtrl.text = course.courseName;
      _yearCtrl.text = course.yearLevel;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose(); _nameCtrl.dispose(); _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(courseNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Course' : 'Add Course')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(labelText: 'Course Code *', hintText: 'e.g. BSCS', prefixIcon: Icon(Icons.code_rounded)),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Course Name *', hintText: 'e.g. BS Computer Science', prefixIcon: Icon(Icons.school_rounded)),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _yearCtrl,
                      decoration: const InputDecoration(labelText: 'Year Level *', hintText: 'e.g. 1st Year, 2nd Year', prefixIcon: Icon(Icons.grade_rounded)),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (formState.hasError)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0x1AEF4444), borderRadius: BorderRadius.circular(8)),
                child: Text('${formState.error}', style: const TextStyle(color: Color(0xFFEF4444))),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: formState.isLoading ? null : _submit,
                child: formState.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Save Changes' : 'Add Course'),
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
    final course = Course(
      id: _isEdit ? widget.courseId! : uuid.v4(),
      courseCode: _codeCtrl.text.trim().toUpperCase(),
      courseName: _nameCtrl.text.trim(),
      yearLevel: _yearCtrl.text.trim(),
    );
    final ok = await ref.read(courseNotifierProvider.notifier).save(course, isEdit: _isEdit);
    if (ok && mounted) context.go('/courses');
  }
}
