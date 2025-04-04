import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart'; // adjust path

class ClassStudentsPage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const ClassStudentsPage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<ClassStudentsPage> createState() => _ClassStudentsPageState();
}

class _ClassStudentsPageState extends State<ClassStudentsPage> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final enrollmentList =
          await ApiService.getStudentsForClass(widget.courseId);

      List<Map<String, dynamic>> enriched = [];

      for (var enrollment in enrollmentList) {
        final email = enrollment['email'];

        // Fetch actual username using email
        final user = await ApiService.getUserByEmail(email);

        enriched.add({
          "email": email,
          "username": user['username'] ?? email.split('@')[0],
        });
      }

      setState(() {
        students = enriched;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(child: Text('No students have joined this class.'))
              : ListView.builder(
                  itemCount: students.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final email = student['email'] ?? 'No email';
                    final username = student['username'] ?? 'Unnamed';

                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(email),
                      ),
                    );
                  },
                ),
    );
  }
}
