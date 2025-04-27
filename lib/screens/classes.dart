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
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.courseName,
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(
                  child: Text(
                    'No students have joined this class.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: students.length,
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final email = student['email'] ?? 'No email';
                    final username = student['username'] ?? 'Unnamed';

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          radius: screenWidth * 0.06,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: screenWidth * 0.06,
                          ),
                        ),
                        title: Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
