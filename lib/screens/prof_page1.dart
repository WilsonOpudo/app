import 'dart:math';
import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';
import 'package:meetme/screens/classes.dart'; // <--- Make sure this is the correct path
import 'professorappointments.dart';

class ProfessorPage1 extends StatefulWidget {
  const ProfessorPage1({super.key});

  @override
  State<ProfessorPage1> createState() => _ProfessorPage1State();
}

class _ProfessorPage1State extends State<ProfessorPage1> {
  List<Map<String, dynamic>> createdClasses = [];
  String? professorEmail;

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
      setState(() {
        createdClasses = allClasses
            .where((cls) => cls['professor_email'] == professorEmail)
            .toList();
      });
    }
  }

  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(4, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<void> _createClassDialog(BuildContext context) async {
    final classNameController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Create New Class',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).shadowColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: classNameController,
                decoration: InputDecoration(
                  labelText: 'Class Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel',
                style:
                    TextStyle(color: Theme.of(context).secondaryHeaderColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Create Class'),
            onPressed: () async {
              final name = classNameController.text.trim();
              final desc = descriptionController.text.trim();
              final code = _generateClassCode();

              if (name.isNotEmpty) {
                try {
                  final userInfo = await ApiService.getUserInfo();
                  final username = userInfo['username'];
                  final email = userInfo['email'];

                  await ApiService.createClass(
                    courseId: code,
                    courseName: name,
                    professorName: username!,
                    professorEmail: email!,
                  );

                  setState(() {
                    createdClasses.add({
                      'course_id': code,
                      'course_name': name,
                      'description': desc,
                      'professor_name': username,
                      'professor_email': email,
                    });
                  });

                  Navigator.of(context).pop();

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Class Created!'),
                      content:
                          Text('Share this code with students to join: $code'),
                      actions: [
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating class: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Classes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).shadowColor,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.event_note, size: 24),
                        color: Colors.teal,
                        tooltip: "View Appointments",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfessorAppointmentsPage(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.add_rounded,
                            color: Theme.of(context).shadowColor, size: 25),
                        onPressed: () => _createClassDialog(context),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Classes',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).hintColor,
                    fontFamily: 'Poppins',
                  ),
                  prefixIcon:
                      Icon(Icons.search, color: Theme.of(context).shadowColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                onChanged: (value) {
                  // Optional filtering
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: createdClasses.length,
                itemBuilder: (context, index) {
                  final cls = createdClasses[index];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).shadowColor,
                        radius: 24,
                        backgroundImage:
                            const AssetImage('assets/logo-transparent-png.png'),
                      ),
                      title: Text(
                        cls['course_name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).shadowColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cls['professor_name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (cls['description'] != null)
                            Text(
                              cls['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Class Code: ${cls['course_id']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
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
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text(
                                  'Are you sure you want to delete this class?'),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await ApiService.deleteClass(cls['course_id']);
                              setState(() {
                                createdClasses.removeAt(index);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Class deleted successfully')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to delete class: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
