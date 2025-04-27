import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:meetme/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'stu_page5.dart';

class StudentPage4 extends StatefulWidget {
  const StudentPage4({super.key});

  @override
  State<StudentPage4> createState() => _StudentPage4State();
}

class _StudentPage4State extends State<StudentPage4> {
  List<Map<String, dynamic>> professors = [];
  String? studentEmail;

  @override
  void initState() {
    super.initState();
    _loadProfessors();
  }

  Future<void> _loadProfessors() async {
    final userInfo = await ApiService.getUserInfo();
    studentEmail = userInfo['email'];

    final enrolledClasses = await ApiService.getEnrolledClasses(studentEmail!);

    Set<String> addedEmails = {};
    List<Map<String, dynamic>> loadedProfessors = [];

    for (var cls in enrolledClasses) {
      try {
        final email =
            await ApiService.getProfessorEmailFromCourse(cls['course_id']);

        if (addedEmails.add(email)) {
          final user = await ApiService.getUserByEmail(email);
          loadedProfessors.add(user);
        }
      } catch (_) {
        continue;
      }
    }

    setState(() {
      professors = loadedProfessors;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Professors"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Theme.of(context).shadowColor,
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        iconTheme: IconThemeData(color: Theme.of(context).shadowColor),
      ),
      body: professors.isEmpty
          ? Center(
              child: Text(
                "Not enrolled in any class yet.",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04, vertical: screenWidth * 0.03),
              itemCount: professors.length,
              itemBuilder: (context, index) {
                final prof = professors[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentPage5(
                          senderId: studentEmail!,
                          receiverId: prof['email'],
                          receiverName: prof['username'],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenWidth * 0.03),
                      leading: CircleAvatar(
                        radius: screenWidth * 0.07,
                        backgroundColor: Colors.teal.shade300,
                        child: Text(
                          prof['username'][0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                      ),
                      title: Text(
                        prof['username'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: Theme.of(context).shadowColor,
                          fontSize: screenWidth * 0.045,
                        ),
                      ),
                      subtitle: Text(
                        prof['email'],
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Theme.of(context).hintColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      trailing: Icon(
                        Icons.chat_bubble_outline,
                        size: screenWidth * 0.065,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
