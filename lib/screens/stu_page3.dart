import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:meetme/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StudentPage3 extends StatefulWidget {
  const StudentPage3({super.key});

  @override
  State<StudentPage3> createState() => _StudentPage3State();
}

class _StudentPage3State extends State<StudentPage3> {
  final DatePickerController _datePickerController = DatePickerController();
  final CalendarController _calendarController = CalendarController();

  DateTime _selectedDate = DateTime.now();
  Map<String, List<Appointment>> _appointmentsByDate = {};

  @override
  void initState() {
    super.initState();
    _calendarController.displayDate = _selectedDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _datePickerController.animateToDate(_selectedDate);
    });

    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    if (email == null) return;

    try {
      final raw = await ApiService.getAppointments(email);
      Map<String, List<Appointment>> grouped = {};

      for (var appt in raw) {
        final dateTime = DateTime.tryParse(appt['appointment_date']);
        if (dateTime == null) continue;

        final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);
        grouped.putIfAbsent(dateKey, () => []).add(
              Appointment(
                startTime: dateTime,
                endTime: dateTime.add(const Duration(minutes: 30)),
                subject: appt['course_name'] ?? 'Appointment',
                color: _colorFromCourse(appt['course_name']),
              ),
            );
      }

      setState(() => _appointmentsByDate = grouped);
    } catch (e) {
      debugPrint("❌ Appointment load failed: $e");
    }
  }

  List<Appointment> _getAppointmentsForSelectedDate() {
    final key = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _appointmentsByDate[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
              child: DatePicker(
                DateTime.now(),
                controller: _datePickerController,
                initialSelectedDate: _selectedDate,
                height: screenWidth * 0.25,
                width: screenWidth * 0.13,
                selectionColor: Theme.of(context).primaryColor,
                selectedTextColor: Colors.white,
                daysCount: 7,
                onDateChange: (date) {
                  if (!isSameDay(_selectedDate, date)) {
                    setState(() => _selectedDate = date);
                    _calendarController.displayDate = date;
                  }
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.02),
                child: SfCalendar(
                  controller: _calendarController,
                  view: CalendarView.day,
                  dataSource:
                      MeetingDataSource(_getAppointmentsForSelectedDate()),
                  todayHighlightColor: Theme.of(context).secondaryHeaderColor,
                  initialDisplayDate: _selectedDate,
                  appointmentBuilder: (context, details) {
                    final Appointment appointment = details.appointments.first;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: appointment.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          appointment.subject,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    );
                  },
                  viewHeaderStyle: ViewHeaderStyle(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    dateTextStyle: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Theme.of(context).shadowColor,
                    ),
                  ),
                  headerHeight: 0,
                  timeSlotViewSettings: TimeSlotViewSettings(
                    startHour: 8,
                    endHour: 20,
                    timeInterval: const Duration(minutes: 30),
                    timeIntervalHeight: screenWidth * 0.15,
                    timeFormat: 'h:mm a',
                    timeTextStyle: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).shadowColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onViewChanged: (ViewChangedDetails details) {
                    if (details.visibleDates.isNotEmpty) {
                      final newDate = details.visibleDates.first;
                      if (!isSameDay(newDate, _selectedDate)) {
                        setState(() => _selectedDate = newDate);
                        _datePickerController.animateToDate(newDate);
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Color _colorFromCourse(String? courseName) {
    final name = (courseName ?? '').toLowerCase();
    if (name.contains('math')) return Colors.indigo;
    if (name.contains('science')) return Colors.green;
    if (name.contains('english')) return Colors.orange;
    if (name.contains('lab')) return Colors.red;
    if (name.contains('history')) return Colors.brown;
    return Colors.teal;
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
