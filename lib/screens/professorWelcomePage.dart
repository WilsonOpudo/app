import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetme/api_service.dart';
import 'package:meetme/app_navigation.dart'; // ✅ for jumpToPage
import 'professorappointments.dart';
import 'CourseGroupPage.dart';

class ProfessorWelcomePage extends StatefulWidget {
  const ProfessorWelcomePage({super.key});

  @override
  State<ProfessorWelcomePage> createState() => _ProfessorWelcomePageState();
}

class _ProfessorWelcomePageState extends State<ProfessorWelcomePage> {
  List<Map<String, dynamic>> createdClasses = [];
  List<Map<String, dynamic>> todayAppointments = [];
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

      List<Map<String, dynamic>> appointments = [];
      for (final cls in filtered) {
        final appts =
            await ApiService.getProfessorAppointments(cls['course_id']);
        appointments.addAll(appts);
      }

      final today = DateTime.now();
      todayAppointments = appointments.where((appt) {
        final apptDate = DateTime.tryParse(appt['appointment_date'] ?? '');
        return apptDate != null &&
            apptDate.year == today.year &&
            apptDate.month == today.month &&
            apptDate.day == today.day;
      }).toList();

      setState(() => createdClasses = filtered);
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory();
    final greeting = _getGreeting();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$greeting, ${username ?? 'Professor'}!",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // 🔹 Quick Action Buttons
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

            // 🔹 Today’s Appointments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Today's Appointments",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.view_list, size: 16),
                  label: const Text("View All"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfessorAppointmentsPage()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (todayAppointments.isEmpty)
              const Text("No upcoming appointments for today.",
                  style: TextStyle(color: Colors.grey))
            else
              ...todayAppointments.map((appt) {
                final time = DateFormat.jm()
                    .format(DateTime.parse(appt['appointment_date']));
                return ListTile(
                  leading: const Icon(Icons.access_time,
                      color: Colors.teal, size: 20),
                  title:
                      Text("${appt['student_name']} - ${appt['course_name']}"),
                  subtitle: Text(time),
                );
              }),

            const SizedBox(height: 24),

            const Text("Your Course Categories",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
              children: grouped.entries.map((entry) {
                final category = entry.key;
                final classes = entry.value;
                final imgPath = courseImages[category]!;

                return GestureDetector(
                  onTap: () {
                    if (classes.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseGroupPage(
                            courseName: category,
                            matchingClasses: classes,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(imgPath),
                        fit: BoxFit.cover,
                        colorFilter: classes.isEmpty
                            ? ColorFilter.mode(
                                Colors.black.withOpacity(0.4), BlendMode.darken)
                            : null,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text(
                          classes.isEmpty
                              ? "No class yet"
                              : "${classes.length} class${classes.length > 1 ? 'es' : ''}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

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
