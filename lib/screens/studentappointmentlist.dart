import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetme/api_service.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  List<Map<String, dynamic>> today = [];
  List<Map<String, dynamic>> upcoming = [];
  List<Map<String, dynamic>> past = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => isLoading = true);
    try {
      final userInfo = await ApiService.getUserInfo();
      final email = userInfo['email'];

      if (email == null || email.isEmpty) {
        throw Exception("Email not found in user session.");
      }

      final fetchedAppointments = await ApiService.getAppointments(email);
      final now = DateTime.now();

      today.clear();
      upcoming.clear();
      past.clear();

      for (var appt in fetchedAppointments) {
        final dateStr = appt['appointment_date'];
        final dateTime = DateTime.tryParse(dateStr ?? '');
        if (dateTime == null) continue;

        final isSameDay = dateTime.year == now.year &&
            dateTime.month == now.month &&
            dateTime.day == now.day;

        if (dateTime.isBefore(now) && !isSameDay) {
          past.add(appt);
        } else if (isSameDay) {
          today.add(appt);
        } else {
          upcoming.add(appt);
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to load appointments: $e')),
      );
    }
  }

  Future<void> _showAppointmentDetails(Map<String, dynamic> appointment) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final course = appointment['course_name'] ?? 'Unknown Course';
    final fullName = appointment['professor_name'] ?? 'Unknown Professor';
    final date = DateTime.tryParse(appointment['appointment_date'] ?? '');
    final formatted = date != null
        ? DateFormat.yMMMMd().add_jm().format(date)
        : 'Invalid Date';

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (context) => Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course,
                style: TextStyle(
                    fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
            SizedBox(height: screenWidth * 0.02),
            Text("Professor: $fullName"),
            SizedBox(height: screenWidth * 0.02),
            Text("Scheduled for: $formatted"),
            if (appointment.containsKey('location'))
              Text("Location: ${appointment['location']}",
                  style: TextStyle(fontSize: screenWidth * 0.04)),
            if (appointment.containsKey('notes'))
              Text("Notes: ${appointment['notes']}",
                  style: TextStyle(fontSize: screenWidth * 0.04)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(Map<String, dynamic> appointment) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content:
            const Text("Are you sure you want to cancel this appointment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      try {
        final appointmentId = appointment['_id'] ?? appointment['id'];
        if (appointmentId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ No appointment ID found.")),
          );
          return;
        }

        await ApiService.cancelAppointment(appointmentId);
        await _loadAppointments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Appointment cancelled")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to cancel appointment: $e")),
        );
      }
    }
  }

  Widget _buildSection(
    String title,
    List<Map<String, dynamic>> appointments, {
    Color? cardColor = Colors.white,
    bool showCancel = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (appointments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
          child: Text(
            title,
            style: TextStyle(
                fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
          ),
        ),
        ...appointments.map((appointment) {
          final courseName = appointment['course_name'] ?? 'Unknown Course';
          final fullName = appointment['professor_name'] ?? 'Unknown Professor';

          String formattedDate = 'Unknown Time';
          try {
            final dateTime = DateTime.parse(appointment['appointment_date']);
            formattedDate = DateFormat.yMMMMd().add_jm().format(dateTime);
          } catch (e) {
            print('❌ Invalid date format: ${appointment['appointment_date']}');
          }

          return Card(
            color: cardColor,
            margin: EdgeInsets.only(bottom: screenWidth * 0.03),
            child: ListTile(
              leading: Icon(Icons.event_note, size: screenWidth * 0.07),
              title: Text(
                courseName,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
              ),
              subtitle: Text("With: $fullName\nAt: $formattedDate",
                  style: TextStyle(fontSize: screenWidth * 0.035)),
              onTap: () => _showAppointmentDetails(appointment),
              trailing: showCancel
                  ? IconButton(
                      icon: Icon(Icons.cancel,
                          color: Colors.red, size: screenWidth * 0.07),
                      onPressed: () => _confirmCancel(appointment),
                    )
                  : null,
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
          title: Text("My Appointments",
              style: TextStyle(fontSize: screenWidth * 0.05))),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection("\ud83d\uddd5 Today", today,
                        cardColor: Colors.blue.shade50, showCancel: true),
                    _buildSection("\u23ed Upcoming", upcoming,
                        cardColor: Colors.green.shade50, showCancel: true),
                    _buildSection("\u23ea Past", past,
                        cardColor: Colors.grey.shade200),
                    if (today.isEmpty && upcoming.isEmpty && past.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: screenWidth * 0.05),
                          child: Text("No appointments found",
                              style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
