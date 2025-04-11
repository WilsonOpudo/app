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
  String? selectedCourseId;
  String? selectedCourseName;
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
    final response = await ApiService.getAvailableSlots(
      professorEmail: await ApiService.getProfessorEmailFromCourse(courseId),
      courseId: courseId,
      date: selectedDate.toIso8601String().split('T').first,
    );
    setState(() => availableSlots = response);
  }

  Future<void> _bookSlot(String courseId, String courseName,
      String professorEmail, String professorName, String time) async {
    final dateTime = DateTime.parse(
        "${selectedDate.toIso8601String().split('T').first}T$time:00");
    await ApiService.createAppointment(
      studentName: studentUsername!,
      studentEmail: studentEmail!,
      courseId: courseId,
      courseName: courseName,
      professorName: professorName,
      dateTime: dateTime,
    );
    await _loadAvailableSlots(courseId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Appointment booked for $time")),
    );
  }

  Future<void> _showSlotPicker(String courseId, String courseName) async {
    final professorEmail =
        await ApiService.getProfessorEmailFromCourse(courseId);
    final profDetails = await ApiService.getProfessorDetails(professorEmail);
    final professorName = profDetails['fullName'];

    await _loadAvailableSlots(courseId);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: availableSlots.isEmpty
            ? const Text("No available slots for selected date")
            : Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: availableSlots.map((slot) {
                  final time = slot['time'];
                  return ElevatedButton(
                    onPressed: () => _bookSlot(courseId, courseName,
                        professorEmail, professorName, time),
                    child: Text(time),
                  );
                }).toList(),
              ),
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
                  child: ListTile(
                    title: Text(cls['course_name']),
                    subtitle: Text("Professor: ${cls['professor_name']}"),
                    trailing: ElevatedButton(
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
