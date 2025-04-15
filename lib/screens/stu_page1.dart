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
  List<Map<String, dynamic>> filteredClasses = [];
  String? studentEmail;
  String _searchQuery = "";

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
        setState(() {
          joinedClasses = classes;
          filteredClasses = classes;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classes: $e')),
        );
      }
    }
  }

  void _filterClasses(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      filteredClasses = joinedClasses.where((cls) {
        final name = cls['course_name'].toString().toLowerCase();
        final prof = cls['professor_name'].toString().toLowerCase();
        return name.contains(_searchQuery) || prof.contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _showJoinClassDialog() async {
    final codeController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join a Class"),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(hintText: "Enter Class Code"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty || studentEmail == null) return;

              try {
                final info = await ApiService.getUserInfo();
                final classData = await ApiService.getClassById(code);

                final alreadyJoined = joinedClasses.any(
                  (cls) => cls['course_id'] == classData['course_id'],
                );

                if (!alreadyJoined) {
                  await ApiService.enrollInClass(
                    courseId: code,
                    studentEmail: info['email']!,
                    studentUsername: info['username']!,
                  );

                  setState(() {
                    joinedClasses.add(classData);
                    _filterClasses(_searchQuery);
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Class joined successfully.")),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("You already joined this class.")),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Invalid class code or join error.")),
                );
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Classes',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyAppointmentsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text("My Appointments"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 28),
                        onPressed: _showJoinClassDialog,
                      ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search Classes',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                onChanged: _filterClasses,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredClasses.length,
                itemBuilder: (context, index) {
                  final cls = filteredClasses[index];
                  final iconPath = _getCourseIcon(cls['course_name']);
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(iconPath),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      title: Text(cls['course_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Instructor: ${cls['professor_name']}"),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
