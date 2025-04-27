import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';
import 'prof_page5.dart';

class ProfessorPage4 extends StatefulWidget {
  const ProfessorPage4({super.key});

  @override
  State<ProfessorPage4> createState() => _ProfessorPage4State();
}

class _ProfessorPage4State extends State<ProfessorPage4> {
  List<Map<String, dynamic>> students = [];
  String? professorEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final info = await ApiService.getUserInfo();
      professorEmail = info['email'];

      if (professorEmail == null) return;

      final allClasses = await ApiService.getClasses();
      final myClasses = allClasses
          .where((cls) => cls['professor_email'] == professorEmail)
          .toList();

      Set<String> addedEmails = {};
      List<Map<String, dynamic>> fetchedStudents = [];

      for (var cls in myClasses) {
        final courseId = cls['course_id'];
        try {
          final enrolled = await ApiService.getStudentsInClass(courseId);
          for (var student in enrolled) {
            if (!addedEmails.contains(student['email'])) {
              addedEmails.add(student['email']);
              fetchedStudents.add(student);
            }
          }
        } catch (_) {
          continue;
        }
      }

      setState(() {
        students = fetchedStudents;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat with Students",
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: screenWidth * 0.05),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(
                  child: Text(
                    "No enrolled students yet.",
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.04),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  separatorBuilder: (_, __) =>
                      SizedBox(height: screenWidth * 0.03),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              senderId: professorEmail!,
                              receiverId: student['email'],
                              receiverName: student['username'],
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenWidth * 0.035),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: screenWidth * 0.06,
                              backgroundColor: theme.primaryColor,
                              child: Text(
                                student['username'][0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.045,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.035),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['username'],
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  SizedBox(height: screenWidth * 0.01),
                                  Text(
                                    student['email'],
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: theme.hintColor,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chat_bubble_outline,
                                size: screenWidth * 0.05),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
