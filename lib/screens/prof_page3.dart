import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:meetme/api_service.dart';

class ProfessorPage3 extends StatefulWidget {
  const ProfessorPage3({super.key});

  @override
  State<ProfessorPage3> createState() => _ProfessorPage3State();
}

class _ProfessorPage3State extends State<ProfessorPage3> {
  DateTime _selectedDate = DateTime.now();
  final DatePickerController _datePickerController = DatePickerController();
  final CalendarController _calendarController = CalendarController();
  List<Appointment> calendarAppointments = [];

  @override
  void initState() {
    super.initState();
    _calendarController.displayDate = _selectedDate;

    // 🔥 Fix the crash on animateToDate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _datePickerController.animateToDate(_selectedDate);
    });

    _fetchAppointmentsForDate(_selectedDate);
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _fetchAppointmentsForDate(DateTime date) async {
    final userInfo = await ApiService.getUserInfo();
    final email = userInfo['email'];
    final allClasses = await ApiService.getClasses();

    final classIds = allClasses
        .where((cls) => cls['professor_email'] == email)
        .map((cls) => cls['course_id'])
        .toList();

    List<Map<String, dynamic>> allAppts = [];

    for (String courseId in classIds) {
      final appts = await ApiService.getProfessorAppointments(courseId);
      allAppts.addAll(appts);
    }

    final filtered = allAppts.where((appt) {
      final apptDate = DateTime.tryParse(appt['appointment_date']);
      return apptDate != null &&
          apptDate.year == date.year &&
          apptDate.month == date.month &&
          apptDate.day == date.day;
    }).toList();

    final appointments = filtered.map((appt) {
      final start = DateTime.parse(appt['appointment_date']);
      return Appointment(
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        subject: "${appt['student_name']} - ${appt['course_name']}",
        color: generateRedTint(appt['course_name']),
      );
    }).toList();

    setState(() {
      calendarAppointments = appointments;
    });
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
                daysCount: 7,
                onDateChange: (date) {
                  if (!isSameDay(_selectedDate, date)) {
                    setState(() => _selectedDate = date);
                    _calendarController.displayDate = date;
                    _calendarController.selectedDate =
                        date; // ✅ sync selected date too
                    _fetchAppointmentsForDate(date);
                  }
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SfCalendar(
                  controller: _calendarController,
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
                  todayHighlightColor: Theme.of(context).secondaryHeaderColor,
                  view: CalendarView.day,
                  initialDisplayDate: _selectedDate,
                  initialSelectedDate: _selectedDate,
                  dataSource: MeetingDataSource(calendarAppointments),
                  onViewChanged: (details) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final newDate = details.visibleDates.first;
                      if (!isSameDay(_selectedDate, newDate)) {
                        setState(() => _selectedDate = newDate);
                        _datePickerController.animateToDate(newDate);
                        _fetchAppointmentsForDate(newDate);
                      }
                    });
                  },
                  appointmentBuilder: (context, details) {
                    final appointment = details.appointments.first;
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
                  timeSlotViewSettings: TimeSlotViewSettings(
                    startHour: 8,
                    endHour: 20,
                    timeInterval: const Duration(minutes: 30),
                    timeFormat: 'h:mm a',
                    timeIntervalHeight: 70,
                    timeTextStyle: TextStyle(
                      fontSize: 12,
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
}

// 🔴 Generate unique red-tinted colors based on course name
Color generateRedTint(String key) {
  final hash = key.hashCode;
  final hue = (hash % 360).toDouble(); // hue between 0 and 359
  final saturation = 0.5 + (hash % 50) / 100; // saturation 0.5–1.0
  final brightness = 0.7 + (hash % 30) / 100; // brightness 0.7–1.0

  return HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
