import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';
import 'package:meetme/app_navigation.dart';
import 'package:meetme/screens/courseGroupPage.dart';
import 'professorappointments.dart';

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
        name.contains('grammar') ||
        name.contains('lit')) {
      return 'English';
    } else if (name.contains('history') ||
        name.contains('gov') ||
        name.contains('civics')) {
      return 'History';
    } else if (name.contains('art') ||
        name.contains('drawing') ||
        name.contains('design')) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final greeting = _getGreeting();
    final grouped = _groupByCategory();
    final visibleCategories =
        grouped.entries.where((entry) => entry.value.isNotEmpty).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$greeting, ${username ?? 'Professor'}!",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: screenWidth * 0.04),
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
            SizedBox(height: screenWidth * 0.05),
            _buildSectionTitle("Today's Appointments", onViewAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProfessorAppointmentsPage()),
              );
            }),
            _buildAppointmentsList(todayAppointments),
            SizedBox(height: screenWidth * 0.06),
            _buildSectionTitle("Upcoming Appointments"),
            _buildAppointmentsList(upcomingAppointments),
            SizedBox(height: screenWidth * 0.06),
            _buildSectionTitle("Your Course Categories"),
            SizedBox(height: screenWidth * 0.02),
            Text(
              "Explore and manage your classes by tapping on them below.",
              style: TextStyle(
                  color: Colors.black54, fontSize: screenWidth * 0.035),
            ),
            SizedBox(height: screenWidth * 0.03),
            RepaintBoundary(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleCategories.length,
                separatorBuilder: (_, __) =>
                    Divider(height: screenWidth * 0.02),
                itemBuilder: (context, index) {
                  final entry = visibleCategories[index];
                  final category = entry.key;
                  final classList = entry.value;

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.02,
                        horizontal: screenWidth * 0.03),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        courseImages[category] ?? courseImages['Other']!,
                        width: screenWidth * 0.1,
                        height: screenWidth * 0.1,
                        fit: BoxFit.cover,
                        cacheWidth: 80,
                        cacheHeight: 80,
                        gaplessPlayback: true,
                      ),
                    ),
                    title: Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.045,
                      ),
                    ),
                    subtitle: Text(
                        "${classList.length} class${classList.length == 1 ? '' : 'es'}",
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    trailing:
                        Icon(Icons.chevron_right, size: screenWidth * 0.06),
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
      final name = cls['course_name']?.toString() ?? '';
      final category = _matchCategory(name);
      grouped[category]?.add(cls);
    }

    return grouped;
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (appointments.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: screenWidth * 0.02),
        child: Text("No upcoming appointments.",
            style:
                TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035)),
      );
    }

    return Column(
      children: appointments.map((appt) {
        final dt = DateTime.tryParse(appt['appointment_date'] ?? '');
        if (dt == null) return const SizedBox();

        final date = dt.toLocal().toIso8601String().split('T').first;
        final time = TimeOfDay.fromDateTime(dt).format(context);
        return ListTile(
          leading: Icon(Icons.event_note,
              color: Colors.indigo, size: screenWidth * 0.06),
          title: Text(
              "${appt['student_name'] ?? 'Unknown'} - ${appt['course_name'] ?? 'Unknown'}",
              style: TextStyle(fontSize: screenWidth * 0.04)),
          subtitle: Text("$date • $time",
              style: TextStyle(fontSize: screenWidth * 0.035)),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
        if (onViewAll != null)
          TextButton.icon(
            onPressed: onViewAll,
            icon: Icon(Icons.list_alt, size: screenWidth * 0.04),
            label: Text("View All",
                style: TextStyle(fontSize: screenWidth * 0.035)),
          ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.brown.shade100,
            radius: screenWidth * 0.08,
            child: Icon(icon,
                color: Colors.brown.shade800, size: screenWidth * 0.06),
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
