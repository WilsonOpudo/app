import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetme/api_service.dart';
import 'package:meetme/student_navigation.dart';
import 'package:meetme/screens/studentappointmentlist.dart';
import 'package:meetme/screens/professor_classdetails.dart';

class StudentWelcomePage extends StatefulWidget {
  const StudentWelcomePage({super.key});

  @override
  State<StudentWelcomePage> createState() => _StudentWelcomePageState();
}

class _StudentWelcomePageState extends State<StudentWelcomePage> {
  String? username;
  List<Map<String, dynamic>> joinedClasses = [];
  List<Map<String, dynamic>> todayAppointments = [];
  List<Map<String, dynamic>> upcomingAppointments = [];

  final Map<String, String> courseImages = {
    'Mathematics': 'assets/math.png',
    'Science': 'assets/science.png',
    'English': 'assets/english.png',
    'History': 'assets/history.png',
    'Art': 'assets/art.png',
    'Other': 'assets/other.png',
  };

  String _matchCategory(String courseName) {
    final name = courseName.toLowerCase();

    if (name.contains('math') ||
        name.contains('algebra') ||
        name.contains('geometry')) {
      return 'Mathematics';
    } else if (name.contains('science') ||
        name.contains('bio') ||
        name.contains('chem') ||
        name.contains('physics')) {
      return 'Science';
    } else if (name.contains('english') ||
        name.contains('grammar') ||
        name.contains('lit')) {
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
    _loadData();
  }

  Future<void> _loadData() async {
    final info = await ApiService.getUserInfo();
    final email = info['email'];
    final user = info['username'];

    if (email != null) {
      final classes = await ApiService.getEnrolledClasses(email);
      final classIds = classes.map((c) => c['course_id']).toSet();

      final appts = await ApiService.getAppointments(email);
      final now = DateTime.now();

      final todays = <Map<String, dynamic>>[];
      final upcoming = <Map<String, dynamic>>[];

      for (final appt in appts) {
        if (!classIds.contains(appt['course_id'])) continue;

        final apptDate = DateTime.tryParse(appt['appointment_date'] ?? '');
        if (apptDate != null) {
          if (apptDate.year == now.year &&
              apptDate.month == now.month &&
              apptDate.day == now.day) {
            todays.add(appt);
          } else if (apptDate.isAfter(now)) {
            upcoming.add(appt);
          }
        }
      }

      todays.sort((a, b) => DateTime.parse(a['appointment_date'])
          .compareTo(DateTime.parse(b['appointment_date'])));
      upcoming.sort((a, b) => DateTime.parse(a['appointment_date'])
          .compareTo(DateTime.parse(b['appointment_date'])));

      setState(() {
        username = user;
        joinedClasses = classes;
        todayAppointments = todays;
        upcomingAppointments = upcoming;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$greeting, ${username ?? 'Student'}!",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: screenWidth * 0.07,
                    )),
            SizedBox(height: screenWidth * 0.04),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Appointments",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.045)),
                TextButton.icon(
                  icon: Icon(Icons.list, size: screenWidth * 0.045),
                  label: Text("View All",
                      style: TextStyle(fontSize: screenWidth * 0.04)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyAppointmentsPage()),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.02),
            if (todayAppointments.isEmpty)
              Text("No upcoming appointments.",
                  style: TextStyle(
                      color: Colors.grey, fontSize: screenWidth * 0.04))
            else
              ...todayAppointments.map((appt) {
                final time = DateFormat.jm()
                    .format(DateTime.parse(appt['appointment_date']));
                return ListTile(
                  leading: Icon(Icons.calendar_today,
                      color: const Color.fromARGB(255, 201, 66, 21),
                      size: screenWidth * 0.07),
                  title: Text(appt['course_name'],
                      style: TextStyle(fontSize: screenWidth * 0.045)),
                  subtitle: Text(time,
                      style: TextStyle(fontSize: screenWidth * 0.035)),
                );
              }),
            SizedBox(height: screenWidth * 0.05),
            Text("Upcoming Appointments",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045)),
            SizedBox(height: screenWidth * 0.02),
            if (upcomingAppointments.isEmpty)
              Text("No upcoming appointments.",
                  style: TextStyle(
                      color: Colors.grey, fontSize: screenWidth * 0.04))
            else
              ...upcomingAppointments.map((appt) {
                final dt = DateTime.parse(appt['appointment_date']);
                final date = DateFormat.yMMMd().format(dt);
                final time = DateFormat.jm().format(dt);
                return ListTile(
                  leading: Icon(Icons.calendar_today,
                      color: Colors.orange, size: screenWidth * 0.07),
                  title: Text(appt['course_name'],
                      style: TextStyle(fontSize: screenWidth * 0.045)),
                  subtitle: Text("$date • $time",
                      style: TextStyle(fontSize: screenWidth * 0.035)),
                );
              }),
            SizedBox(height: screenWidth * 0.06),
            Text("Quick Actions",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045)),
            SizedBox(height: screenWidth * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickAction(Icons.add, "Book", 2, screenWidth),
                _quickAction(Icons.group_add, "Join", 1, screenWidth),
                _quickAction(Icons.calendar_month, "Calendar", 3, screenWidth),
              ],
            ),
            SizedBox(height: screenWidth * 0.06),
            Text("Enrolled Classes",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045)),
            SizedBox(height: screenWidth * 0.03),
            RepaintBoundary(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: joinedClasses.length,
                itemBuilder: (context, index) {
                  final cls = joinedClasses[index];
                  final imagePath = _getCourseImage(cls['course_name']);

                  return Card(
                    elevation: 1.5,
                    margin: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                    child: ListTile(
                      leading: ClipOval(
                        child: Image.asset(
                          imagePath,
                          width: screenWidth * 0.1,
                          height: screenWidth * 0.1,
                          fit: BoxFit.cover,
                          cacheWidth: 80,
                          cacheHeight: 80,
                        ),
                      ),
                      title: Text(
                        cls['course_name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.045,
                        ),
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
                                Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () async {
                                  int retries = 0;
                                  while (StudentNavigation.jumpToPage == null &&
                                      retries < 10) {
                                    await Future.delayed(
                                        const Duration(milliseconds: 100));
                                    retries++;
                                  }
                                  if (StudentNavigation.jumpToPage != null) {
                                    StudentNavigation.jumpToPage!(2);
                                  } else {
                                    debugPrint(
                                        "❌ Navigation to appointments failed (still null)");
                                  }
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
          ],
        ),
      ),
    );
  }

  String _getCourseImage(String courseName) {
    final category = _matchCategory(courseName);
    return courseImages[category] ?? courseImages['Other']!;
  }

  Widget _quickAction(
      IconData icon, String label, int pageIndex, double screenWidth) {
    return InkWell(
      onTap: () async {
        int retries = 0;
        while (StudentNavigation.jumpToPage == null && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 100));
          retries++;
        }
        if (StudentNavigation.jumpToPage != null) {
          StudentNavigation.jumpToPage!(pageIndex);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.brown.shade100,
            radius: screenWidth * 0.07,
            child: Icon(icon,
                color: Colors.brown.shade800, size: screenWidth * 0.07),
          ),
          SizedBox(height: screenWidth * 0.015),
          Text(label,
              style: TextStyle(
                  fontSize: screenWidth * 0.03, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
