import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';
import 'classes.dart'; // for ClassStudentsPage

class CourseGroupPage extends StatefulWidget {
  final String courseName;
  final List<Map<String, dynamic>> matchingClasses;

  const CourseGroupPage({
    super.key,
    required this.courseName,
    required this.matchingClasses,
  });

  @override
  State<CourseGroupPage> createState() => _CourseGroupPageState();
}

class _CourseGroupPageState extends State<CourseGroupPage> {
  late List<Map<String, dynamic>> classList;

  @override
  void initState() {
    super.initState();
    classList = widget.matchingClasses;
    _loadStudentCounts();
  }

  Future<void> _loadStudentCounts() async {
    for (var cls in classList) {
      final students = await ApiService.getStudentsInClass(cls['course_id']);
      cls['student_count'] = students.length;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.courseName} Classes"),
      ),
      body: classList.isEmpty
          ? const Center(child: Text("No classes found in this category"))
          : ListView.builder(
              itemCount: classList.length,
              itemBuilder: (context, index) {
                final cls = classList[index];
                final name = cls['course_name'];
                final code = cls['course_id'];
                final studentCount = cls['student_count'] ?? 0;
                final hasStudents = studentCount > 0;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      Icons.class_,
                      color: hasStudents ? Colors.blue : Colors.grey,
                    ),
                    title: Text(name),
                    subtitle: Text(
                      hasStudents
                          ? "Code: $code • $studentCount student${studentCount == 1 ? '' : 's'}"
                          : "Code: $code • No students enrolled",
                      style: TextStyle(
                        color: hasStudents ? Colors.black87 : Colors.grey,
                        fontStyle:
                            hasStudents ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                    onTap: hasStudents
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassStudentsPage(
                                  courseId: code,
                                  courseName: name,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
