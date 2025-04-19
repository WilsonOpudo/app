import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';
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
          // add() returns false if already present
          final user = await ApiService.getUserByEmail(email);
          loadedProfessors.add(user);
        }
      } catch (_) {
        // Skip silently if email or user lookup fails
        continue;
      }
    }

    setState(() {
      professors = loadedProfessors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Professors"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Theme.of(context).shadowColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        iconTheme: IconThemeData(color: Theme.of(context).shadowColor),
      ),
      body: professors.isEmpty
          ? const Center(
              child: Text(
                "Not enrolled in any class yet.",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.teal.shade300,
                        child: Text(
                          prof['username'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        prof['username'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: Theme.of(context).shadowColor,
                        ),
                      ),
                      subtitle: Text(
                        prof['email'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).hintColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      trailing: const Icon(Icons.chat_bubble_outline),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
