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

  final Map<String, String> courseImages = {
    'Mathematics': 'assets/math.jpg',
    'Science': 'assets/science.jpg',
    'English': 'assets/english.jpg',
    'History': 'assets/history.jpg',
    'Art': 'assets/art.jpg',
    'Other': 'assets/other.jpg',
  };

  String _matchCategory(String courseName) {
    final name = courseName.toLowerCase();

    if (name.contains('math') ||
        name.contains('algebra') ||
        name.contains('geometry')) {
      return 'Mathematics';
    } else if (name.contains('sci') ||
        name.contains('bio') ||
        name.contains('chem') ||
        name.contains('physics')) {
      return 'Science';
    } else if (name.contains('english') ||
        name.contains('lit') ||
        name.contains('grammar')) {
      return 'English';
    } else if (name.contains('history') ||
        name.contains('civics') ||
        name.contains('gov')) {
      return 'History';
    } else if (name.contains('art') ||
        name.contains('design') ||
        name.contains('drawing')) {
      return 'Art';
    } else {
      return 'Other';
    }
  }

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
          decoration: const InputDecoration(
              hintText: "Enter Class Code to Join Your Class"),
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
    final category = _matchCategory(courseName);
    return courseImages[category] ?? courseImages['Other']!;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03, vertical: screenWidth * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Classes',
                    style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold),
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
                        icon: Icon(Icons.calendar_today,
                            size: screenWidth * 0.045),
                        label: Text("My Appointments",
                            style: TextStyle(fontSize: screenWidth * 0.035)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 13, 75, 69),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenWidth * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      IconButton(
                        icon: Icon(Icons.add_rounded, size: screenWidth * 0.08),
                        onPressed: _showJoinClassDialog,
                      ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Classes',
                  prefixIcon: Icon(Icons.search, size: screenWidth * 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                onChanged: _filterClasses,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(screenWidth * 0.03),
                itemCount: filteredClasses.length,
                itemBuilder: (context, index) {
                  final cls = filteredClasses[index];
                  final iconPath = _getCourseIcon(cls['course_name']);
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(iconPath),
                        backgroundColor: Colors.grey.shade200,
                        radius: screenWidth * 0.07,
                      ),
                      title: Text(
                        cls['course_name'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.045),
                      ),
                      subtitle: Text(
                        "Instructor: ${cls['professor_name']}",
                        style: TextStyle(fontSize: screenWidth * 0.035),
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
            SizedBox(height: screenWidth * 0.05),
          ],
        ),
      ),
    );
  }
}
