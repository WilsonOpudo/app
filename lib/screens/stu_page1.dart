import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';
import 'professor_classdetails.dart';
import 'studentappointmentlist.dart';

class StudentPage1 extends StatefulWidget {
  const StudentPage1({super.key});

  @override
  State<StudentPage1> createState() => _StudentPage1State();
}

class AppNavigation {
  static void Function(int pageIndex)? jumpToPage;
}

class _StudentPage1State extends State<StudentPage1> {
  List<Map<String, dynamic>> joinedClasses = [];
  String? studentEmail;

  @override
  void initState() {
    super.initState();
    _loadEnrolledClasses();
  }

  Future<void> _loadEnrolledClasses() async {
    final userInfo = await ApiService.getUserInfo();
    studentEmail = userInfo['email'];

    if (studentEmail != null) {
      try {
        final classes = await ApiService.getEnrolledClasses(studentEmail!);
        setState(() => joinedClasses = classes);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classes: $e')),
        );
      }
    }
  }

  Future<void> _classAdder(BuildContext context) {
    final codeController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('Class Registration',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).shadowColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please enter the code provided by your teacher',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Theme.of(context).shadowColor)),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  hintText: 'Class Code Ex: ABCD',
                  hintStyle: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Poppins',
                      color: Theme.of(context).hintColor),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style:
                      TextStyle(color: Theme.of(context).secondaryHeaderColor)),
            ),
            TextButton(
              onPressed: () async {
                final classCode = codeController.text.trim();
                if (classCode.isNotEmpty && studentEmail != null) {
                  try {
                    final info = await ApiService.getUserInfo();
                    final email = info['email'];
                    final username = info['username'];

                    final classData = await ApiService.getClassById(classCode);
                    final alreadyJoined = joinedClasses.any(
                        (cls) => cls['course_id'] == classData['course_id']);

                    if (!alreadyJoined) {
                      await ApiService.enrollInClass(
                        courseId: classCode,
                        studentEmail: email!,
                        studentUsername: username!,
                      );

                      setState(() => joinedClasses.add(classData));
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Class joined successfully!')));
                    } else {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('You already joined this class.')));
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Invalid class code or join error.')));
                  }
                }
              },
              child: Text('Register',
                  style: TextStyle(color: Theme.of(context).shadowColor)),
            ),
          ],
        );
      },
    );
  }

  String _getCourseIcon(String courseName) {
    final name = courseName.toLowerCase();
    if (name.contains('math')) return 'assets/math.jpg';
    if (name.contains('science')) return 'assets/science.jpg';
    if (name.contains('english')) return 'assets/english.jpg';
    if (name.contains('history')) return 'assets/history.jpg';
    if (name.contains('art')) return 'assets/art.jpg';
    return 'assets/other.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Classes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).shadowColor,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MyAppointmentsPage()),
                          );
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text("My Appointments"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.add_rounded,
                            size: 25, color: Theme.of(context).shadowColor),
                        onPressed: () => _classAdder(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Classes',
                  hintStyle: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      color: Theme.of(context).hintColor),
                  prefixIcon:
                      Icon(Icons.search, color: Theme.of(context).shadowColor),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                onChanged: (value) {
                  // Optional search filter
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: joinedClasses.length,
                itemBuilder: (context, index) {
                  final cls = joinedClasses[index];
                  final iconPath = _getCourseIcon(cls['course_name']);

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).shadowColor,
                        backgroundImage: AssetImage(iconPath),
                      ),
                      title: Text(
                        cls['course_name'],
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).shadowColor),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Instructor: ${cls['professor_name']}",
                            style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).hintColor),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfessorClassDetailsPage(
                              courseId: cls['course_id'],
                              onNavigateToAppointments: () {
                                Navigator.pop(context);
                                Future.delayed(Duration.zero, () {
                                  AppNavigation.jumpToPage?.call(1);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
