import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';

class ProfessorWelcomePage extends StatefulWidget {
  const ProfessorWelcomePage({super.key});

  @override
  State<ProfessorWelcomePage> createState() => _ProfessorWelcomePageState();
}

class _ProfessorWelcomePageState extends State<ProfessorWelcomePage> {
  List<Map<String, dynamic>> createdClasses = [];
  String? professorEmail;

  final Map<String, String> courseImages = {
    'Math': 'assets/math.jpg',
    'Science': 'assets/science.jpg',
    'English': 'assets/english.jpg',
    'History': 'assets/history.jpg',
    'Art': 'assets/art.jpg',
    'Other': 'assets/other.jpg',
  };

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

  List<Map<String, dynamic>> _getClassesByName(String name) {
    return createdClasses.where((cls) => cls['course_name'] == name).toList();
  }

  @override
  Widget build(BuildContext context) {
    final courseNames = courseImages.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome, Professor!'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Course Dashboard",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: courseNames.length,
                itemBuilder: (context, index) {
                  final course = courseNames[index];
                  final classes = _getClassesByName(course);
                  final imgPath =
                      courseImages[course] ?? courseImages['Other']!;

                  return GestureDetector(
                    onTap: () {
                      if (classes.isNotEmpty) {
                        // Navigate to class list page with matching course name
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseGroupPage(
                              courseName: course,
                              matchingClasses: classes,
                            ),
                          ),
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: AssetImage(imgPath),
                              fit: BoxFit.cover,
                              colorFilter: classes.isEmpty
                                  ? ColorFilter.mode(
                                      Colors.grey.withOpacity(0.4),
                                      BlendMode.darken,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (classes.isNotEmpty)
                                Text(
                                  "${classes.length} class${classes.length > 1 ? 'es' : ''}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (classes.isEmpty)
                                const Text(
                                  "No class yet",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseGroupPage extends StatelessWidget {
  final String courseName;
  final List<Map<String, dynamic>> matchingClasses;

  const CourseGroupPage(
      {super.key, required this.courseName, required this.matchingClasses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$courseName Classes")),
      body: ListView.builder(
        itemCount: matchingClasses.length,
        itemBuilder: (context, index) {
          final cls = matchingClasses[index];
          return ListTile(
            title: Text(cls['course_name']),
            subtitle: Text("Code: ${cls['course_id']}"),
          );
        },
      ),
    );
  }
}
