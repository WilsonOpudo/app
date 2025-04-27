import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetme/api_service.dart';

class ProfessorAppointmentsPage extends StatefulWidget {
  const ProfessorAppointmentsPage({super.key});

  @override
  State<ProfessorAppointmentsPage> createState() =>
      _ProfessorAppointmentsPageState();
}

class _ProfessorAppointmentsPageState extends State<ProfessorAppointmentsPage> {
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> filteredAppointments = [];
  String? professorEmail;
  bool isLoading = true;
  String searchQuery = '';

  List<Map<String, dynamic>> _getTodayAppointments() {
    final now = DateTime.now();
    return filteredAppointments.where((a) {
      final dt = DateTime.tryParse(a['appointment_date'] ?? '');
      return dt != null &&
          dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day;
    }).toList()
      ..sort((a, b) => a['appointment_date'].compareTo(b['appointment_date']));
  }

  List<Map<String, dynamic>> _getUpcomingAppointments() {
    final now = DateTime.now();
    return filteredAppointments.where((a) {
      final dt = DateTime.tryParse(a['appointment_date'] ?? '');
      return dt != null &&
          dt.isAfter(now) &&
          !(dt.year == now.year && dt.month == now.month && dt.day == now.day);
    }).toList()
      ..sort((a, b) => a['appointment_date'].compareTo(b['appointment_date']));
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => isLoading = true);
    try {
      final info = await ApiService.getUserInfo();
      professorEmail = info['email'];
      final allClasses = await ApiService.getClasses();

      final classIds = allClasses
          .where((cls) => cls['professor_email'] == professorEmail)
          .map((cls) => cls['course_id'])
          .toList();

      List<Map<String, dynamic>> allAppts = [];
      for (String courseId in classIds) {
        final appts = await ApiService.getProfessorAppointments(courseId);
        allAppts.addAll(appts);
      }

      appointments = allAppts;
      _applySearchFilter();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text("Failed to load appointments: $e"),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applySearchFilter() {
    filteredAppointments = appointments
        .where((a) =>
            a['course_name'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
    setState(() {});
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await ApiService.cancelAppointment(appointmentId);
      await _loadAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          content: const Text("✅ Appointment cancelled"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text("❌ Failed to cancel: $e"),
        ),
      );
    }
  }

  void _rescheduleAppointment(Map<String, dynamic> appt) {
    final courseId = appt['course_id'];
    final studentEmail = appt['student_email'];
    if (courseId == null || studentEmail == null || professorEmail == null)
      return;

    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Reschedule Appointment",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    onDateChanged: (date) {
                      setModalState(() => selectedDate = date);
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    child: const Text("Show Available Slots"),
                    onPressed: () async {
                      final slots = await ApiService.getAvailableSlots(
                        professorEmail: professorEmail!,
                        courseId: courseId,
                        date: DateFormat('yyyy-MM-dd').format(selectedDate),
                      );

                      if (slots.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No available slots.")),
                        );
                        return;
                      }

                      final amSlots = slots
                          .where((s) =>
                              s['time'].startsWith(RegExp(r'0[0-9]|1[0-1]')))
                          .toList();
                      final pmSlots =
                          slots.where((s) => !amSlots.contains(s)).toList();

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                if (amSlots.isNotEmpty) ...[
                                  const Text("AM Slots",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  _buildSlotRow(
                                      amSlots, appt, courseId, studentEmail),
                                  const SizedBox(height: 20),
                                ],
                                if (pmSlots.isNotEmpty) ...[
                                  const Text("PM Slots",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  _buildSlotRow(
                                      pmSlots, appt, courseId, studentEmail),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSlotRow(List<Map<String, dynamic>> slots,
      Map<String, dynamic> appt, String courseId, String studentEmail) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: slots
            .map((slot) => _buildSlotChip(slot, appt, courseId, studentEmail))
            .toList(),
      ),
    );
  }

  Widget _buildSlotChip(Map<String, dynamic> slot, Map<String, dynamic> appt,
      String courseId, String studentEmail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ActionChip(
        avatar: const Icon(Icons.access_time, size: 18, color: Colors.white),
        backgroundColor: Colors.teal.shade600,
        label: Text(slot['time'], style: const TextStyle(color: Colors.white)),
        onPressed: () async {
          Navigator.pop(context);
          try {
            await ApiService.rescheduleAppointment(
              appointmentId: appt['id'],
              newDateTime: DateTime.parse("${slot['date']}T${slot['time']}"),
              courseId: courseId,
              studentEmail: studentEmail,
            );
            await _loadAppointments();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Rescheduled successfully")),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("❌ Failed to reschedule: $e")),
            );
          }
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dateTime = DateTime.tryParse(appt['appointment_date']);
    final formattedDate = dateTime != null
        ? DateFormat.yMMMMd().add_jm().format(dateTime)
        : 'Unknown Time';

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.event_note,
            color: Colors.teal, size: screenWidth * 0.08),
        title: Text(
          appt['course_name'],
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("With: ${appt['student_name']}",
                style: TextStyle(fontSize: screenWidth * 0.035)),
            Text("At: $formattedDate",
                style: TextStyle(fontSize: screenWidth * 0.035)),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: screenWidth * 0.06),
          onSelected: (value) {
            if (value == 'Cancel') {
              _cancelAppointment(appt['id']);
            } else if (value == 'Reschedule') {
              _rescheduleAppointment(appt);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'Cancel',
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            PopupMenuItem(
              value: 'Reschedule',
              child: Text("Reschedule"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "My Appointments",
          style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.05),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).canvasColor,
                      hintText: "Search by Class Name",
                      prefixIcon: Icon(Icons.search,
                          color: Colors.teal, size: screenWidth * 0.065),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      searchQuery = value;
                      _applySearchFilter();
                    },
                  ),
                ),
                Expanded(
                  child: filteredAppointments.isEmpty
                      ? Center(
                          child: Text(
                            "No appointments found.",
                            style: TextStyle(fontSize: screenWidth * 0.045),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          children: [
                            if (_getTodayAppointments().isNotEmpty) ...[
                              Padding(
                                padding:
                                    EdgeInsets.only(bottom: screenWidth * 0.02),
                                child: Text(
                                  "Today",
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal),
                                ),
                              ),
                              ..._getTodayAppointments()
                                  .map(_buildAppointmentCard),
                              SizedBox(height: screenWidth * 0.04),
                            ],
                            if (_getUpcomingAppointments().isNotEmpty) ...[
                              Padding(
                                padding:
                                    EdgeInsets.only(bottom: screenWidth * 0.02),
                                child: Text(
                                  "Upcoming",
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange),
                                ),
                              ),
                              ..._getUpcomingAppointments()
                                  .map(_buildAppointmentCard),
                            ],
                          ],
                        ),
                )
              ],
            ),
    );
  }
}
