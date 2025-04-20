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
      final classIds =
          classes.map((c) => c['course_id']).toSet(); // keep valid class IDs

      final appts = await ApiService.getAppointments(email);
      final now = DateTime.now();

      final todays = <Map<String, dynamic>>[];
      final upcoming = <Map<String, dynamic>>[];

      for (final appt in appts) {
        if (!classIds.contains(appt['course_id']))
          continue; // ❌ skip deleted class appointments

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

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$greeting, ${username ?? 'Student'}!",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // 🔸 Today's Appointments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Today's Appointments",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.list, size: 16),
                  label: const Text("View All"),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyAppointmentsPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (todayAppointments.isEmpty)
              const Text("No upcoming appointments.",
                  style: TextStyle(color: Colors.grey))
            else
              ...todayAppointments.map((appt) {
                final time = DateFormat.jm()
                    .format(DateTime.parse(appt['appointment_date']));
                return ListTile(
                  leading: const Icon(Icons.calendar_today,
                      color: Color.fromARGB(255, 201, 66, 21)),
                  title: Text(appt['course_name']),
                  subtitle: Text(time),
                );
              }),

            const SizedBox(height: 20),

            // 🔸 Upcoming Appointments
            const Text("Upcoming Appointments",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (upcomingAppointments.isEmpty)
              const Text("No upcoming appointments.",
                  style: TextStyle(color: Colors.grey))
            else
              ...upcomingAppointments.map((appt) {
                final dt = DateTime.parse(appt['appointment_date']);
                final date = DateFormat.yMMMd().format(dt);
                final time = DateFormat.jm().format(dt);
                return ListTile(
                  leading:
                      const Icon(Icons.calendar_today, color: Colors.orange),
                  title: Text(appt['course_name']),
                  subtitle: Text("$date • $time"),
                );
              }),

            const SizedBox(height: 24),

            // 🔸 Moved Quick Actions here
            const Text("Quick Actions",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickAction(Icons.add, "Book", 2),
                _quickAction(Icons.group_add, "Join", 1),
                _quickAction(Icons.calendar_month, "Calendar", 3),
              ],
            ),

            const SizedBox(height: 24),

            // 🔸 Enrolled Classes
            const Text("Enrolled Classes",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
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
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: ClipOval(
                        child: Image.asset(
                          imagePath,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          cacheWidth: 80, // Reduces memory usage
                          cacheHeight: 80,
                        ),
                      ),
                      title: Text(
                        cls['course_name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "Instructor: ${cls['professor_name']}",
                        style: const TextStyle(fontSize: 13),
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
    final name = courseName.toLowerCase();
    if (name.contains('math')) return 'assets/math.jpg';
    if (name.contains('science')) return 'assets/science.jpg';
    if (name.contains('english')) return 'assets/english.jpg';
    if (name.contains('history')) return 'assets/history.jpg';
    if (name.contains('art')) return 'assets/art.jpg';
    return 'assets/other.jpg'; // fallback
  }

  Widget _quickAction(IconData icon, String label, int pageIndex) {
    return InkWell(
      onTap: () async {
        debugPrint("⏳ Attempting to navigate to page index: $pageIndex");

        int retries = 0;
        while (StudentNavigation.jumpToPage == null && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 100));
          retries++;
        }

        if (StudentNavigation.jumpToPage == null) {
          debugPrint("❌ Still NULL after waiting, navigation failed.");
        } else {
          debugPrint("✅ jumpToPage is set. Navigating...");
          StudentNavigation.jumpToPage!(pageIndex);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.brown.shade100,
            radius: 24,
            child: Icon(icon, color: Colors.brown.shade800),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _reminderTile(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text),
    );
  }
}
