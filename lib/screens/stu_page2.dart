import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:meetme/api_service.dart';

class StudentPage2 extends StatefulWidget {
  const StudentPage2({super.key});

  @override
  State<StudentPage2> createState() => _StudentPage2State();
}

class _StudentPage2State extends State<StudentPage2> {
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
    final dateString = selectedDate.toIso8601String().split('T').first;
    final dateTime = DateTime.tryParse("$dateString" "T$time");
    if (dateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Could not parse time")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Booking"),
        content: Text("Book appointment at $time for $courseName?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirm")),
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

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      await _loadAvailableSlots(courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Appointment booked at $time")),
      );
    } catch (e) {
      final error = e.toString().contains("already booked")
          ? "⛔ You already booked this slot."
          : e.toString().contains("Slot no longer available")
              ? "⛔ That slot was just booked by another student."
              : "❌ Booking failed: $e";

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _showSlotPicker(String courseId, String courseName) async {
    final professorEmail =
        await ApiService.getProfessorEmailFromCourse(courseId);
    final classData = enrolledClasses.firstWhere(
      (c) => c['course_id'] == courseId,
      orElse: () => {},
    );
    final professorName =
        classData['professor_name'] ?? professorEmail.split('@')[0];

    await _loadAvailableSlots(courseId);

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    availableSlots.sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));

    final amSlots = availableSlots.where((slot) {
      final hour = int.tryParse(slot['time']?.split(':').first ?? '0') ?? 0;
      return hour < 12;
    }).toList();

    final pmSlots = availableSlots.where((slot) {
      final hour = int.tryParse(slot['time']?.split(':').first ?? '0') ?? 0;
      return hour >= 12;
    }).toList();

    Widget buildSlotRow(List<Map<String, dynamic>> slots, String label) {
      if (slots.isEmpty) return const SizedBox();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8, bottom: 4),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slots.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final time = slots[index]['time'];
                final hour = int.tryParse(time.split(":").first) ?? 0;
                final minute = int.tryParse(time.split(":")[1]) ?? 0;
                final fullDate = DateTime(selectedDate.year, selectedDate.month,
                    selectedDate.day, hour, minute);

                final isPast = isToday && fullDate.isBefore(now);

                return OutlinedButton(
                  onPressed: isPast
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _bookSlot(courseId, courseName, professorEmail,
                              professorName, time);
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    backgroundColor:
                        isPast ? Colors.grey.shade700 : Colors.transparent,
                    side: BorderSide(
                        color: isPast ? Colors.grey : Colors.white70,
                        width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      color: isPast ? Colors.grey.shade300 : Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Book Your Appointment",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (availableSlots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text("No slots available",
                          style: TextStyle(color: Colors.white70)),
                    ),
                  if (amSlots.isNotEmpty) buildSlotRow(amSlots, "Morning"),
                  if (pmSlots.isNotEmpty) buildSlotRow(pmSlots, "Afternoon"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 12),
          DatePicker(
            DateTime.now(),
            height: screenWidth * 0.28,
            initialSelectedDate: selectedDate,
            selectionColor: Theme.of(context).primaryColor,
            selectedTextColor: Colors.white,
            onDateChange: (date) => setState(() => selectedDate = date),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Enrolled Classes',
            style: TextStyle(
                fontSize: screenWidth * 0.045, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(screenWidth * 0.03),
              itemCount: enrolledClasses.length,
              itemBuilder: (context, index) {
                final cls = enrolledClasses[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
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
                    onTap: () =>
                        _showSlotPicker(cls['course_id'], cls['course_name']),
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
