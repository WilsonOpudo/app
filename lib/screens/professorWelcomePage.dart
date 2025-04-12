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
    'Mathematics': 'assets/math.jpg',
    'Science': 'assets/science.jpg',
    'English': 'assets/english.jpg',
    'History': 'assets/history.jpg',
    'Art': 'assets/art.jpg',
    'Other': 'assets/other.jpg',
  };

  final Map<String, List<String>> categoryKeywords = {
    'Mathematics': ['math', 'algebra', 'calculus', 'geometry', 'trigonometry'],
    'Science': ['science', 'biology', 'physics', 'chemistry', 'computer'],
    'English': ['english', 'literature', 'grammar', 'writing', 'language'],
    'History': ['history', 'geography', 'civics'],
    'Art': ['art', 'drawing', 'painting', 'music', 'theatre'],
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

  String _categorize(String name) {
    final lower = name.toLowerCase();
    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return 'Other';
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory() {
    final grouped = {
      for (final cat in courseImages.keys) cat: <Map<String, dynamic>>[]
    };

    for (final cls in createdClasses) {
      final category = _categorize(cls['course_name']);
      grouped[category]?.add(cls);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory();

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
                itemCount: courseImages.length,
                itemBuilder: (context, index) {
                  final category = courseImages.keys.elementAt(index);
                  final classes = grouped[category] ?? [];
                  final imgPath = courseImages[category]!;

                  return GestureDetector(
                    onTap: () {
                      if (classes.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseGroupPage(
                              courseName: category,
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
                                      Colors.black.withOpacity(0.3),
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
                                category,
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
                                  ),
                                )
                              else
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

  const CourseGroupPage({
    super.key,
    required this.courseName,
    required this.matchingClasses,
  });

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
