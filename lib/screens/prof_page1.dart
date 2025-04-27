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

  final Map<String, String> courseImages = {
    'Mathematics': 'assets/math.jpg',
    'Science': 'assets/science.jpg',
    'English': 'assets/english.jpg',
    'History': 'assets/history.jpg',
    'Art': 'assets/art.jpg',
    'Other': 'assets/other.jpg',
  };

  String _matchCategory(String courseName) {
    final name = courseName.toLowerCase();

    if (name.contains('math') ||
        name.contains('algebra') ||
        name.contains('geometry')) {
      return 'Mathematics';
    } else if (name.contains('sci') ||
        name.contains('bio') ||
        name.contains('chem') ||
        name.contains('physics')) {
      return 'Science';
    } else if (name.contains('english') ||
        name.contains('lit') ||
        name.contains('grammar')) {
      return 'English';
    } else if (name.contains('history') ||
        name.contains('civics') ||
        name.contains('gov')) {
      return 'History';
    } else if (name.contains('art') ||
        name.contains('design') ||
        name.contains('drawing')) {
      return 'Art';
    } else {
      return 'Other';
    }
  }

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
    final category = _matchCategory(courseName);
    return courseImages[category] ?? courseImages['Other']!;
  }

  Future<void> _createClassDialog(BuildContext context) async {
    final classNameController = TextEditingController();
    final descriptionController = TextEditingController();

    final screenWidth = MediaQuery.of(context).size.width;

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
              SizedBox(height: screenWidth * 0.02),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03, vertical: screenWidth * 0.02),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Classes',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: screenWidth * 0.06)),
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
                      icon: Icon(Icons.calendar_today_rounded,
                          color: Colors.green, size: screenWidth * 0.06),
                      label: Text("My Appointments",
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: screenWidth * 0.04)),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, size: screenWidth * 0.07),
                      onPressed: () => _createClassDialog(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: TextField(
              decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).canvasColor,
                  hintText: 'Search Classes',
                  prefixIcon: Icon(Icons.search,
                      color: Colors.teal, size: screenWidth * 0.065),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  )),
              onChanged: (value) {
                searchQuery = value;
                _applyFilter();
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(screenWidth * 0.03),
              itemCount: filteredClasses.length,
              itemBuilder: (context, index) {
                final cls = filteredClasses[index];
                final iconPath = _getCourseIcon(cls['course_name']);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundImage: AssetImage(iconPath),
                        radius: screenWidth * 0.07),
                    title: Text(cls['course_name'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.045)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Instructor: ${cls['professor_name']}",
                            style: TextStyle(fontSize: screenWidth * 0.035)),
                        if (professorEmail != null &&
                            cls['professor_email'] == professorEmail)
                          Text(
                            "Class Code: ${cls['course_id']}",
                            style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                color: Colors.grey[600]),
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
                      icon: Icon(Icons.delete,
                          color: Colors.red, size: screenWidth * 0.06),
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
