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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Class Details",
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.04,
                      screenWidth * 0.04,
                      screenWidth * 0.04,
                      screenWidth * 0.01),
                  child: Text(
                    courseName ?? "Class Name",
                    style: TextStyle(
                      fontSize: screenWidth * 0.065,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Text(
                    "Instructor: ${professorName ?? 'Unknown'}",
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.04),
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
                          style: TextStyle(fontSize: screenWidth * 0.04),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        if (userRole == "professor")
                          Text(
                            "Class Code: $courseCode",
                            style: TextStyle(
                              fontSize: screenWidth * 0.038,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAppointmentPage,
                    icon: Icon(Icons.calendar_today_rounded,
                        size: screenWidth * 0.06),
                    label: Text(
                      "New Appointment",
                      style: TextStyle(fontSize: screenWidth * 0.045),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(screenWidth * 0.13),
                      textStyle: TextStyle(fontSize: screenWidth * 0.045),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
