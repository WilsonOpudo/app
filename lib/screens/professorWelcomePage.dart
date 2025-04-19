import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';
import 'package:meetme/app_navigation.dart';
import 'package:meetme/screens/courseGroupPage.dart';

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

      final now = DateTime.now();
      List<Map<String, dynamic>> enrichedClasses = [];
      List<Map<String, dynamic>> allAppointments = [];

      final futures = filtered.map((cls) async {
        final courseId = cls['course_id'];

        final studentFuture = ApiService.getStudentsInClass(courseId)
            .then((students) => cls['student_count'] = students.length)
            .catchError((_) => cls['student_count'] = 0);

        final apptFuture =
            ApiService.getProfessorAppointments(courseId).then((appts) {
          if (appts is List) {
            allAppointments.addAll(appts);
          }
        }).catchError((_) {});

        await Future.wait([studentFuture, apptFuture]);
        return cls;
      });

      enrichedClasses = await Future.wait(futures);

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
            apptDate.isAfter(now) &&
            !(apptDate.year == now.year &&
                apptDate.month == now.month &&
                apptDate.day == now.day);
      }).toList()
        ..sort((a, b) => DateTime.parse(a['appointment_date'])
            .compareTo(DateTime.parse(b['appointment_date'])));

      setState(() => createdClasses = enrichedClasses);
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
    final grouped = _groupByCategory();
    final visibleCategories =
        grouped.entries.where((entry) => entry.value.isNotEmpty).toList();

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
            RepaintBoundary(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleCategories.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final entry = visibleCategories[index];
                  final category = entry.key;
                  final classList = entry.value;

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        courseImages[category] ?? courseImages['Other']!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        cacheWidth: 80,
                        cacheHeight: 80,
                        gaplessPlayback: true,
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
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory() {
    final grouped = {
      for (final cat in courseImages.keys) cat: <Map<String, dynamic>>[]
    };
    for (final cls in createdClasses) {
      final category = courseImages.keys.firstWhere(
        (key) => cls['course_name']
            .toString()
            .toLowerCase()
            .contains(key.toLowerCase()),
        orElse: () => 'Other',
      );
      grouped[category]?.add(cls);
    }
    return grouped;
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments) {
    if (appointments.isEmpty) {
      return const Text("No upcoming appointments.",
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: appointments.map((appt) {
        final dt = DateTime.tryParse(appt['appointment_date'] ?? '');
        if (dt == null) return const SizedBox();

        final date = dt.toLocal().toIso8601String().split('T').first;
        final time = TimeOfDay.fromDateTime(dt).format(context);
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
