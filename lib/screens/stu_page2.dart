import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:meetme/api_service.dart';

class StudentPage2 extends StatefulWidget {
  const StudentPage2({super.key});

  @override
  State<StudentPage2> createState() => _StudentPage2State();
}

class _StudentPage2State extends State<StudentPage2>
    with TickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> enrolledClasses = [];
  List<Map<String, dynamic>> availableSlots = [];
  String? studentEmail;
  String? studentUsername;

  @override
  void initState() {
    super.initState();
    _loadEnrolledClasses();
  }

  Future<void> _loadEnrolledClasses() async {
    final info = await ApiService.getUserInfo();
    studentEmail = info['email'];
    studentUsername = info['username'];
    final classes = await ApiService.getEnrolledClasses(studentEmail!);
    setState(() => enrolledClasses = classes);
  }

  Future<void> _loadAvailableSlots(String courseId) async {
    final professorEmail =
        await ApiService.getProfessorEmailFromCourse(courseId);
    final response = await ApiService.getAvailableSlots(
      professorEmail: professorEmail,
      courseId: courseId,
      date: selectedDate.toIso8601String().split('T').first,
    );
    setState(() => availableSlots = response);
  }

  Future<void> _bookSlot(String courseId, String courseName,
      String professorEmail, String professorName, String time) async {
    if (time == null || time is! String || time.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Invalid time slot")),
      );
      return;
    }

    final dateString = selectedDate.toIso8601String().split('T').first;
    DateTime? dateTime;

    try {
      dateTime = DateTime.parse("$dateString" "T$time");
    } catch (_) {
      try {
        dateTime = DateTime.parse("$dateString $time");
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Could not parse selected time")),
        );
        return;
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Booking"),
        content: Text("Book appointment at $time for $courseName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.createAppointment(
        studentName: studentUsername!,
        studentEmail: studentEmail!,
        courseId: courseId,
        courseName: courseName,
        professorName: professorName,
        dateTime: dateTime,
      );

      Navigator.pop(context); // Close modal
      await _loadAvailableSlots(courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Appointment booked for $time")),
      );
    } catch (e) {
      if (e.toString().contains('already booked')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⛔ You already booked this slot.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Booking failed: $e")),
        );
      }
    }
  }

  Future<void> _showSlotPicker(String courseId, String courseName) async {
    final professorEmail =
        await ApiService.getProfessorEmailFromCourse(courseId);

    // 🔥 NEW LINE: get professor name from enrolledClasses
    final classData = enrolledClasses.firstWhere(
      (c) => c['course_id'] == courseId,
      orElse: () => {},
    );
    final professorName =
        classData['professor_name'] ?? professorEmail.split('@')[0];

    await _loadAvailableSlots(courseId);

    final amSlots = availableSlots.where((s) {
      final time = s['time'] ?? '';
      final hour = int.tryParse(time.split(":")[0]) ?? 0;
      return hour < 12;
    }).toList();

    final pmSlots = availableSlots.where((s) {
      final time = s['time'] ?? '';
      final hour = int.tryParse(time.split(":")[0]) ?? 0;
      return hour >= 12;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Available Slots",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (availableSlots.isEmpty)
                const Text("No slots available for this day"),
              if (amSlots.isNotEmpty) ...[
                const Align(
                    alignment: Alignment.centerLeft, child: Text("🌅 Morning")),
                const SizedBox(height: 8),
                _buildAnimatedSlotList(amSlots, courseId, courseName,
                    professorEmail, professorName),
              ],
              if (pmSlots.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("🌇 Afternoon")),
                const SizedBox(height: 8),
                _buildAnimatedSlotList(pmSlots, courseId, courseName,
                    professorEmail, professorName),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSlotList(
      List<Map<String, dynamic>> slots,
      String courseId,
      String courseName,
      String professorEmail,
      String professorName) {
    final now = DateTime.now();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: slots.map((slot) {
          final time = slot['time'];
          if (time == null || time == 'Unknown') return const SizedBox();

          final fullDateTime = DateTime.tryParse(
              "${selectedDate.toIso8601String().split('T').first}T$time");

          // ⛔ Skip past slots
          if (fullDateTime != null && fullDateTime.isBefore(now)) {
            return const SizedBox(); // skip
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: InkWell(
              onTap: () => _bookSlot(
                  courseId, courseName, professorEmail, professorName, time),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.teal),
                    const SizedBox(width: 12),
                    Text(
                      time,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 12),
          DatePicker(
            DateTime.now(),
            height: 100,
            initialSelectedDate: selectedDate,
            selectionColor: Theme.of(context).primaryColor,
            selectedTextColor: Colors.white,
            onDateChange: (date) => setState(() => selectedDate = date),
          ),
          const SizedBox(height: 8),
          const Text('Your Enrolled Classes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: enrolledClasses.length,
              itemBuilder: (context, index) {
                final cls = enrolledClasses[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(cls['course_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Professor: ${cls['professor_name']}"),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: () =>
                          _showSlotPicker(cls['course_id'], cls['course_name']),
                      child: const Text("Book"),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
