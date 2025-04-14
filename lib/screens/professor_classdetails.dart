import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadClassDetails();
  }

  String? userRole;

  Future<void> _loadClassDetails() async {
    try {
      final userInfo = await ApiService.getUserInfo();
      userRole = userInfo['role']; // either "student" or "professor"

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
                // ✅ Heading
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

                // ✅ Subheading
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Instructor: ${professorName ?? 'Unknown'}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Square Description + Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
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
                        if (userRole ==
                            "professor") // 🔒 Only professors see this
                          Text(
                            "Class Code: $courseCode",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ✅ New Appointment Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Future.delayed(Duration.zero, () {
                        widget.onNavigateToAppointments();
                      });
                    },
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
