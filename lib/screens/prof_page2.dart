import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:meetme/api_service.dart';

class ProfessorPage2 extends StatefulWidget {
  const ProfessorPage2({super.key});

  @override
  State<ProfessorPage2> createState() => _ProfessorPage2State();
}

class _ProfessorPage2State extends State<ProfessorPage2> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> professorClasses = [];
  List<Map<String, dynamic>> availableSlots = [];
  String? selectedCourseId;
  String? professorEmail;

  @override
  void initState() {
    super.initState();
    _loadProfessorClasses();
  }

  Future<void> _loadProfessorClasses() async {
    final userInfo = await ApiService.getUserInfo();
    final email = userInfo['email'];
    professorEmail = email;
    final classes = await ApiService.getClasses();
    setState(() {
      professorClasses =
          classes.where((cls) => cls['professor_email'] == email).toList();
    });
  }

  Future<void> _loadAvailableSlots() async {
    if (selectedCourseId == null || professorEmail == null) return;

    final all = await ApiService.getAvailableSlots(
      professorEmail: professorEmail!,
      courseId: selectedCourseId!,
      date: selectedDate.toIso8601String().split('T').first,
    );

    setState(() {
      availableSlots = all.where((slot) {
        return slot.containsKey('date') && slot['date'] != null;
      }).toList();
    });
  }

  Future<void> _addAvailableSlot(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;

    if (selectedCourseId == null || professorEmail == null) return;

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Select Time Slot',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: screenWidth * 0.05,
                  color: Theme.of(context).shadowColor)),
          content: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(15, (index) {
              final hour = 10 + (index ~/ 2);
              final minute = (index % 2) * 30;
              final slotTime = DateTime(selectedDate.year, selectedDate.month,
                  selectedDate.day, hour, minute);
              final formattedTime =
                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

              final isPast = isToday && slotTime.isBefore(now);

              return ElevatedButton(
                onPressed: isPast
                    ? null
                    : () async {
                        try {
                          await ApiService.saveAvailableSlot(
                            professorEmail: professorEmail!,
                            courseId: selectedCourseId!,
                            date:
                                selectedDate.toIso8601String().split('T').first,
                            time: formattedTime,
                          );

                          if (Navigator.canPop(context)) Navigator.pop(context);
                          await _loadAvailableSlots();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('✅ Slot added successfully')),
                          );
                        } catch (e) {
                          if (Navigator.canPop(context)) Navigator.pop(context);

                          String errorMessage = "❌ Failed to save slot";
                          if (e.toString().contains(
                              "Slot already exists for another class")) {
                            errorMessage =
                                "⚠️ This time slot is already used in another class. Choose a different time.";
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage)),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPast
                      ? Colors.grey.shade300
                      : Theme.of(context).primaryColor,
                ),
                child: Text(formattedTime,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: screenWidth * 0.035,
                        color: isPast ? Colors.grey : Colors.white)),
              );
            }),
          ),
        );
      },
    );
  }

  Future<void> _deleteSlot(Map<String, dynamic> slot) async {
    final professorEmailToUse = slot['professor_email'] ?? professorEmail;
    final courseIdToUse = slot['course_id'] ?? selectedCourseId;
    final dateToUse = slot['date'];
    final timeToUse = slot['time'];

    if (professorEmailToUse == null ||
        courseIdToUse == null ||
        dateToUse == null ||
        timeToUse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot deletion failed: Missing values')),
      );
      return;
    }

    try {
      await ApiService.deleteAvailableSlot(
        professorEmail: professorEmailToUse,
        courseId: courseIdToUse,
        date: dateToUse,
        time: timeToUse,
      );
      await _loadAvailableSlots();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete slot: $e')),
      );
    }
  }

  List<Widget> _buildGroupedSlots() {
    final screenWidth = MediaQuery.of(context).size.width;

    List<Map<String, dynamic>> parseAndSort(List<Map<String, dynamic>> slots) {
      return slots
        ..sort((a, b) {
          final t1 = a['time']!;
          final t2 = b['time']!;
          return DateTime.parse("1970-01-01T$t1:00")
              .compareTo(DateTime.parse("1970-01-01T$t2:00"));
        });
    }

    final amSlots = parseAndSort(availableSlots.where((s) {
      final time = s['time'];
      if (time == null) return false;
      final hour = int.tryParse(time.split(':').first) ?? 0;
      return hour < 12;
    }).toList());

    final pmSlots = parseAndSort(availableSlots.where((s) {
      final time = s['time'];
      if (time == null) return false;
      final hour = int.tryParse(time.split(':').first) ?? 0;
      return hour >= 12;
    }).toList());

    Widget buildGroup(String label, List<Map<String, dynamic>> slots) {
      if (slots.isEmpty) return const SizedBox();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: screenWidth * 0.01, horizontal: screenWidth * 0.04),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045)),
          ),
          ...slots.map((slot) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    slot['time'] ?? 'Unknown',
                    style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w500),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete,
                        color: Colors.redAccent, size: screenWidth * 0.06),
                    onPressed: () => _deleteSlot(slot),
                  ),
                ),
              ))
        ],
      );
    }

    return [
      buildGroup("Morning (AM)", amSlots),
      buildGroup("Afternoon (PM)", pmSlots),
    ];
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
            DatePicker(
              DateTime.now(),
              height: 100,
              width: screenWidth * 0.15,
              initialSelectedDate: selectedDate,
              selectionColor: Theme.of(context).primaryColor,
              selectedTextColor: Theme.of(context).scaffoldBackgroundColor,
              onDateChange: (date) async {
                setState(() => selectedDate = date);
                if (selectedCourseId != null) {
                  await _loadAvailableSlots();
                }
              },
            ),
            const SizedBox(height: 10),
            Text('Manage Available Slots',
                style: TextStyle(
                    fontSize: screenWidth * 0.05, fontWeight: FontWeight.w500)),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(screenWidth * 0.03),
                itemCount: professorClasses.length,
                itemBuilder: (context, index) {
                  final cls = professorClasses[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        cls['course_name'],
                        style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).shadowColor),
                      ),
                      subtitle: Text(
                        'Code: ${cls['course_id']}',
                        style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Theme.of(context).hintColor),
                      ),
                      onTap: () async {
                        setState(() => selectedCourseId = cls['course_id']);
                        await _loadAvailableSlots();
                      },
                    ),
                  );
                },
              ),
            ),
            if (selectedCourseId != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenWidth * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Class:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.045),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      professorClasses.firstWhere((cls) =>
                          cls['course_id'] == selectedCourseId)['course_name'],
                      style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: Theme.of(context).shadowColor),
                    ),
                    Text(
                      'Code: $selectedCourseId',
                      style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF560017),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenWidth * 0.03),
                        ),
                        onPressed: () => _addAvailableSlot(context),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Slot"),
                      ),
                    ),
                  ],
                ),
              ),
              availableSlots.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: const Text('No slots available for this day'),
                    )
                  : Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03),
                        children: _buildGroupedSlots(),
                      ),
                    ),
            ],
            SizedBox(height: screenWidth * 0.04),
          ],
        ),
      ),
    );
  }
}
