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

      Navigator.pop(context);
      await _loadAvailableSlots(courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Appointment booked at $time")),
      );
    } catch (e) {
      final error = e.toString().contains("already booked")
          ? "⛔ You already booked this slot."
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

    // Sort slots by time
    availableSlots.sort((a, b) => a['time'].compareTo(b['time']));

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            decoration: BoxDecoration(
              color: Colors.grey[900], // Dark background
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
                  const Text(
                    "Book Your Appointment",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (availableSlots.isEmpty)
                    const Text("No slots available",
                        style: TextStyle(color: Colors.white70)),
                  ...availableSlots.map((slot) {
                    final time = slot['time'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          side: const BorderSide(
                              color: Colors.white24, width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close popup
                          _bookSlot(courseId, courseName, professorEmail,
                              professorName, time);
                        },
                        child: Text(
                          time,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotList(List<Map<String, dynamic>> slots, String courseId,
      String courseName, String professorEmail, String professorName) {
    return Column(
      children: slots.map((slot) {
        final time = slot['time'];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: InkWell(
            onTap: () => _bookSlot(
                courseId, courseName, professorEmail, professorName, time),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
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
                    subtitle: Text("Instructor: ${cls['professor_name']}"),
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
