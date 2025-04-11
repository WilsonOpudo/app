import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';
import 'package:meetme/screens/stu_page1.dart';

class ProfessorClassDetailsPage extends StatefulWidget {
  final String courseId;
  final VoidCallback onNavigateToAppointments;

  const ProfessorClassDetailsPage({
    super.key,
    required this.courseId,
    required this.onNavigateToAppointments,
  });

  @override
  State<ProfessorClassDetailsPage> createState() =>
      _ProfessorClassDetailsPageState();
}

class _ProfessorClassDetailsPageState extends State<ProfessorClassDetailsPage> {
  Map<String, dynamic>? professorProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfessorProfile();
  }

  Future<void> _loadProfessorProfile() async {
    try {
      final classData = await ApiService.getClassById(widget.courseId);
      final professorEmail = classData['professor_email'];

      if (professorEmail == null || professorEmail.isEmpty) {
        throw Exception("professor_email missing from class");
      }

      final profile = await ApiService.getProfessorDetails(professorEmail);

      setState(() {
        professorProfile = profile;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load professor profile: $e")),
      );
    }
  }

  Widget _buildInfoCard(String label, String? value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          value?.trim().isNotEmpty == true ? value! : 'Not provided',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Professor Profile"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).shadowColor,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (professorProfile?["profile_image_url"]
                                ?.isNotEmpty ==
                            true)
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(
                                professorProfile!["profile_image_url"],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const Text(
                          "Professor Profile",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "This page displays your professor's information. You can also book a new appointment.",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                            "Full Name", professorProfile?["full_name"]),
                        _buildInfoCard(
                            "Department", professorProfile?["department"]),
                        _buildInfoCard("Office Location",
                            professorProfile?["office_location"]),
                        _buildInfoCard(
                            "Office Hours", professorProfile?["office_hours"]),
                        _buildInfoCard("Phone", professorProfile?["phone"]),
                        _buildInfoCard("Bio", professorProfile?["bio"]),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close profile page first
                      Future.delayed(Duration.zero, () {
                        AppNavigation.jumpToPage
                            ?.call(1); // Go to StudentPage2 (appointments)
                      });
                    },
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: const Text("New Appointment"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
