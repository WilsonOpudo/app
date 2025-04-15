import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';
import 'package:meetme/student_navigation.dart'; // ✅ Make sure this is imported

class ProfessorClassDetailsPage extends StatefulWidget {
  final String courseId;
  final VoidCallback onNavigateToAppointments;

  const ProfessorClassDetailsPage({
    super.key,
    required this.courseId,
    required this.onNavigateToAppointments,
  });

  @override
  State<ProfessorClassDetailsPage> createState() =>
      _ProfessorClassDetailsPageState();
}

class _ProfessorClassDetailsPageState extends State<ProfessorClassDetailsPage> {
  bool isLoading = true;
  String? courseName;
  String? description;
  String? professorName;
  String? courseCode;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadClassDetails();
  }

  Future<void> _loadClassDetails() async {
    try {
      final userInfo = await ApiService.getUserInfo();
      userRole = userInfo['role']; // "student" or "professor"

      final classData = await ApiService.getClassById(widget.courseId);
      setState(() {
        courseName = classData['course_name'];
        professorName = classData['professor_name'];
        description = classData['description'];
        courseCode = classData['course_id'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load class info: $e")),
      );
    }
  }

  void _navigateToAppointmentPage() {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 100), () async {
      int retries = 0;
      while (StudentNavigation.jumpToPage == null && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
      if (StudentNavigation.jumpToPage != null) {
        StudentNavigation.jumpToPage!(2); // 📍 Index 2 for `stu_page2`
      } else {
        debugPrint("❌ Navigation to stu_page2 failed.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Details"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).shadowColor,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    courseName ?? "Class Name",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Instructor: ${professorName ?? 'Unknown'}",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description: ${description?.trim().isNotEmpty == true ? description : 'No description'}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        if (userRole == "professor")
                          Text(
                            "Class Code: $courseCode",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAppointmentPage,
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: const Text("New Appointment"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
