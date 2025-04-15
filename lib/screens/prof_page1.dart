import 'dart:math';
import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';
import 'package:meetme/screens/classes.dart';
import 'professorappointments.dart';

class ProfessorPage1 extends StatefulWidget {
  const ProfessorPage1({super.key});

  @override
  State<ProfessorPage1> createState() => _ProfessorPage1State();
}

class _ProfessorPage1State extends State<ProfessorPage1> {
  List<Map<String, dynamic>> createdClasses = [];
  List<Map<String, dynamic>> filteredClasses = [];
  String? professorEmail;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadProfessorClasses();
  }

  Future<void> _loadProfessorClasses() async {
    final info = await ApiService.getUserInfo();
    professorEmail = info['email'];

    if (professorEmail != null) {
      final allClasses = await ApiService.getClasses();
      createdClasses = allClasses
          .where((cls) => cls['professor_email'] == professorEmail)
          .toList();
      _applyFilter();
    }
  }

  void _applyFilter() {
    setState(() {
      filteredClasses = createdClasses
          .where((cls) => cls['course_name']
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    });
  }

  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(4, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  String _getCourseIcon(String courseName) {
    final name = courseName.toLowerCase();
    if (name.contains('math')) return 'assets/math.jpg';
    if (name.contains('science')) return 'assets/science.jpg';
    if (name.contains('english')) return 'assets/english.jpg';
    if (name.contains('history')) return 'assets/history.jpg';
    if (name.contains('art')) return 'assets/art.jpg';
    return 'assets/other.jpg';
  }

  Future<void> _createClassDialog(BuildContext context) async {
    final classNameController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: classNameController,
                  decoration: const InputDecoration(labelText: 'Class Name')),
              const SizedBox(height: 10),
              TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Create Class'),
            onPressed: () async {
              final name = classNameController.text.trim();
              final desc = descriptionController.text.trim();
              final code = _generateClassCode();

              if (name.isNotEmpty) {
                final userInfo = await ApiService.getUserInfo();
                final username = userInfo['username'];
                final email = userInfo['email'];

                await ApiService.createClass(
                  courseId: code,
                  courseName: name,
                  professorName: username!,
                  professorEmail: email!,
                  description: desc,
                );

                setState(() {
                  createdClasses.add({
                    'course_id': code,
                    'course_name': name,
                    'description': desc,
                    'professor_name': username,
                    'professor_email': email,
                  });
                  _applyFilter();
                });

                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass(int index, Map<String, dynamic> cls) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteClass(cls['course_id']);
        createdClasses.removeWhere((c) => c['course_id'] == cls['course_id']);
        _applyFilter();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete class: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Classes',
                    style: Theme.of(context).textTheme.titleLarge),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ProfessorAppointmentsPage()),
                        );
                      },
                      icon: const Icon(Icons.calendar_today_rounded,
                          color: Colors.green),
                      label: const Text("My Appointments",
                          style: TextStyle(color: Colors.green)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 26),
                      onPressed: () => _createClassDialog(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search Classes',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: (value) {
                searchQuery = value;
                _applyFilter();
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredClasses.length,
              itemBuilder: (context, index) {
                final cls = filteredClasses[index];
                final iconPath = _getCourseIcon(cls['course_name']);
                return Card(
                  child: ListTile(
                    leading:
                        CircleAvatar(backgroundImage: AssetImage(iconPath)),
                    title: Text(cls['course_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Instructor: ${cls['professor_name']}"),
                        if (professorEmail != null &&
                            cls['professor_email'] == professorEmail)
                          Text(
                            "Class Code: ${cls['course_id']}",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassStudentsPage(
                            courseId: cls['course_id'],
                            courseName: cls['course_name'],
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteClass(index, cls),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
