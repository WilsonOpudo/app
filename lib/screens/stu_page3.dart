import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:meetme/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentPage3 extends StatefulWidget {
  const StudentPage3({super.key});

  @override
  State<StudentPage3> createState() => _StudentPage3State();
}

class _StudentPage3State extends State<StudentPage3> {
  DateTime _selectedDate = DateTime.now();
  final DatePickerController _datePickerController = DatePickerController();
  final CalendarController _calendarController = CalendarController();

  Map<String, List<Appointment>> _appointmentsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    if (email == null) return;

    try {
      final rawAppointments = await ApiService.getAppointments(email);
      Map<String, List<Appointment>> grouped = {};

      for (var appt in rawAppointments) {
        final dateStr = appt['appointment_date'];
        final dateTime = DateTime.tryParse(dateStr);

        if (dateTime != null) {
          final dateKey = "${dateTime.year}-${dateTime.month}-${dateTime.day}";

          grouped.putIfAbsent(dateKey, () => []).add(
                Appointment(
                  startTime: dateTime,
                  endTime: dateTime.add(const Duration(minutes: 30)),
                  subject: appt['course_name'] ?? 'Meeting',
                  color: _getColorFromCourse(appt['course_name']),
                ),
              );
        }
      }

      setState(() => _appointmentsByDate = grouped);
    } catch (e) {
      debugPrint("❌ Failed to load appointments: $e");
    }
  }

  List<Appointment> _getAppointmentsForSelectedDate() {
    final key =
        "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}";
    return _appointmentsByDate[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              child: DatePicker(
                DateTime.now(),
                controller: _datePickerController,
                height: 120,
                width: 60,
                initialSelectedDate: _selectedDate,
                selectionColor: Theme.of(context).primaryColor,
                selectedTextColor: Theme.of(context).scaffoldBackgroundColor,
                locale: 'en_US',
                daysCount: 14,
                onDateChange: (date) {
                  setState(() {
                    _selectedDate = date;
                    _calendarController.displayDate = _selectedDate;
                  });
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SfCalendar(
                  controller: _calendarController,
                  view: CalendarView.day,
                  initialDisplayDate: _selectedDate,
                  dataSource:
                      MeetingDataSource(_getAppointmentsForSelectedDate()),
                  todayHighlightColor: Theme.of(context).secondaryHeaderColor,
                  appointmentBuilder: (context, details) {
                    final Appointment appointment = details.appointments.first;
                    return Container(
                      decoration: BoxDecoration(
                        color: appointment.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          appointment.subject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                  viewHeaderStyle: ViewHeaderStyle(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    dateTextStyle: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).shadowColor,
                    ),
                  ),
                  headerHeight: 0,
                  timeSlotViewSettings: TimeSlotViewSettings(
                    startHour: 8,
                    endHour: 20,
                    timeInterval: const Duration(minutes: 30),
                    timeIntervalHeight: 60,
                    timeFormat: 'h:mm a',
                    timeTextStyle: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).shadowColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromCourse(String? courseName) {
    final name = (courseName ?? '').toLowerCase();
    if (name.contains('math')) return Colors.indigo;
    if (name.contains('science')) return Colors.green;
    if (name.contains('english')) return Colors.orange;
    if (name.contains('lab')) return Colors.red;
    return Colors.teal;
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
