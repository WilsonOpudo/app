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

      if (professorEmail == null) {
        print("❌ Professor email is null.");
        return;
      }

      final allClasses = await ApiService.getClasses();
      final myClasses = allClasses
          .where((cls) => cls['professor_email'] == professorEmail)
          .toList();

      print("✅ Professor owns ${myClasses.length} class(es)");

      Set<String> addedEmails = {};
      List<Map<String, dynamic>> fetchedStudents = [];

      for (var cls in myClasses) {
        final courseId = cls['course_id'];
        try {
          final enrolled = await ApiService.getStudentsInClass(courseId);
          if (enrolled.isEmpty) {
            print("ℹ️ No students in course: $courseId");
            continue;
          }

          for (var student in enrolled) {
            if (!addedEmails.contains(student['email'])) {
              addedEmails.add(student['email']);
              fetchedStudents.add(student);
              print(
                  "🟢 Student added: ${student['username']} (${student['email']})");
            }
          }
        } catch (_) {
          // Don't throw or show this in UI – just continue
          continue;
        }
      }

      setState(() {
        students = fetchedStudents;
        isLoading = false;
      });
    } catch (_) {
      // General error catch – don’t show anything to the user
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chat with Students",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(
                  child: Text(
                    "No enrolled students yet.",
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
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
                              radius: 22,
                              backgroundColor: theme.primaryColor,
                              child: Text(
                                student['username'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['username'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    student['email'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.hintColor,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chat_bubble_outline, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
