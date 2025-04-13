import 'package:flutter/material.dart';

class CourseGroupPage extends StatelessWidget {
  final String courseName;
  final List<Map<String, dynamic>> matchingClasses;

  const CourseGroupPage({
    super.key,
    required this.courseName,
    required this.matchingClasses,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$courseName Classes')),
      body: ListView.builder(
        itemCount: matchingClasses.length,
        itemBuilder: (context, index) {
          final cls = matchingClasses[index];
          return ListTile(
            leading: const Icon(Icons.class_),
            title: Text(cls['course_name']),
            subtitle: Text("Code: ${cls['course_id']}"),
          );
        },
      ),
    );
  }
}
