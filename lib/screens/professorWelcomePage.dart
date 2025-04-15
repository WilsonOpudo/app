import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetme/api_service.dart';
import 'package:meetme/app_navigation.dart';
import 'professorappointments.dart';
import 'package:meetme/screens/courseGroupPage.dart';
import 'package:meetme/screens/classes.dart'; // Assumed ClassStudentsPage

class ProfessorWelcomePage extends StatefulWidget {
  const ProfessorWelcomePage({super.key});

  @override
  State<ProfessorWelcomePage> createState() => _ProfessorWelcomePageState();
}

class _ProfessorWelcomePageState extends State<ProfessorWelcomePage> {
  List<Map<String, dynamic>> createdClasses = [];
  List<Map<String, dynamic>> todayAppointments = [];
  List<Map<String, dynamic>> upcomingAppointments = [];
  String? professorEmail;
  String? username;

  final Map<String, String> courseImages = {
    'Mathematics': 'assets/math.jpg',
    'Science': 'assets/science.jpg',
    'English': 'assets/english.jpg',
    'History': 'assets/history.jpg',
    'Art': 'assets/art.jpg',
    'Other': 'assets/other.jpg',
  };

  final Map<String, List<String>> categoryKeywords = {
    'Mathematics': ['math', 'algebra', 'calculus', 'geometry'],
    'Science': ['science', 'biology', 'physics', 'chemistry', 'computer'],
    'English': ['english', 'literature', 'grammar'],
    'History': ['history', 'geography', 'civics'],
    'Art': ['art', 'drawing', 'painting', 'music'],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final info = await ApiService.getUserInfo();
    professorEmail = info['email'];
    username = info['username'];

    if (professorEmail != null) {
      final allClasses = await ApiService.getClasses();
      final filtered = allClasses
          .where((cls) => cls['professor_email'] == professorEmail)
          .toList();

      List<Map<String, dynamic>> enrichedClasses = [];
      List<Map<String, dynamic>> allAppointments = [];

      for (final cls in filtered) {
        // Safely get students
        try {
          final students =
              await ApiService.getStudentsInClass(cls['course_id']);
          cls['student_count'] = students.length;
        } catch (e) {
          print('⚠️ Failed to load students for ${cls['course_id']}: $e');
          cls['student_count'] = 0;
        }

        // Safely get appointments
        try {
          final appts =
              await ApiService.getProfessorAppointments(cls['course_id']);
          if (appts is List) {
            allAppointments.addAll(appts);
          }
        } catch (e) {
          print('⚠️ Failed to load appointments for ${cls['course_id']}: $e');
        }

        enrichedClasses.add(cls);
      }

      final now = DateTime.now();

      todayAppointments = allAppointments.where((appt) {
        final apptDate = DateTime.tryParse(appt['appointment_date'] ?? '');
        return apptDate != null &&
            apptDate.year == now.year &&
            apptDate.month == now.month &&
            apptDate.day == now.day;
      }).toList()
        ..sort((a, b) => DateTime.parse(a['appointment_date'])
            .compareTo(DateTime.parse(b['appointment_date'])));

      upcomingAppointments = allAppointments.where((appt) {
        final apptDate = DateTime.tryParse(appt['appointment_date'] ?? '');
        return apptDate != null &&
            (apptDate.isAfter(now) &&
                !(apptDate.year == now.year &&
                    apptDate.month == now.month &&
                    apptDate.day == now.day));
      }).toList()
        ..sort((a, b) => DateTime.parse(a['appointment_date'])
            .compareTo(DateTime.parse(b['appointment_date'])));

      setState(() => createdClasses = enrichedClasses);
    }
  }

  String _categorize(String name) {
    final lower = name.toLowerCase();
    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return 'Other';
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory() {
    final grouped = {
      for (final cat in courseImages.keys) cat: <Map<String, dynamic>>[]
    };
    for (final cls in createdClasses) {
      final category = _categorize(cls['course_name']);
      grouped[category]?.add(cls);
    }
    return grouped;
  }

  String _getCourseImage(String courseName) {
    final lower = courseName.toLowerCase();
    for (final entry in courseImages.entries) {
      if (lower.contains(entry.key.toLowerCase())) return entry.value;
    }
    return courseImages['Other']!;
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
    final grouped = _groupByCategory();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$greeting, ${username ?? 'Professor'}!",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickAction(
                  icon: Icons.add_box,
                  label: 'Create Class',
                  onTap: () => AppNavigation.jumpToPage?.call(1),
                ),
                _quickAction(
                  icon: Icons.schedule,
                  label: 'Manage Slots',
                  onTap: () => AppNavigation.jumpToPage?.call(2),
                ),
                _quickAction(
                  icon: Icons.calendar_month,
                  label: 'Calendar',
                  onTap: () => AppNavigation.jumpToPage?.call(3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔹 Today's Appointments
            _buildSectionTitle("Today's Appointments"),
            _buildAppointmentsList(todayAppointments),

            const SizedBox(height: 24),
            _buildSectionTitle("Upcoming Appointments"),
            _buildAppointmentsList(upcomingAppointments),

            const SizedBox(height: 24),
            _buildSectionTitle("Your Course Categories"),
            const SizedBox(height: 8),
            const Text(
              "Explore and manage your classes by tapping on them below.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // 🔹 Compact Swipeable Grid using Wrap
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courseImages.keys.length,
              itemBuilder: (context, index) {
                final category = courseImages.keys.elementAt(index);
                final classList = grouped[category] ?? [];

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      courseImages[category]!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      "${classList.length} class${classList.length == 1 ? '' : 'es'}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseGroupPage(
                          courseName: category,
                          matchingClasses: classList,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments) {
    if (appointments.isEmpty) {
      return const Text("No upcoming appointments.",
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: appointments.map((appt) {
        final dt = DateTime.tryParse(appt['appointment_date'] ?? '');
        if (dt == null) return const SizedBox(); // Skip if invalid date

        final date = DateFormat.yMMMd().format(dt);
        final time = DateFormat.jm().format(dt);
        return ListTile(
          leading: const Icon(Icons.event_note, color: Colors.indigo),
          title: Text(
              "${appt['student_name'] ?? 'Unknown'} - ${appt['course_name'] ?? 'Unknown'}"),
          subtitle: Text("$date • $time"),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
}
