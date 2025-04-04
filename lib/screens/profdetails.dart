import 'package:flutter/material.dart';
import 'package:meetme/api_service.dart';

class ProfDetailsPage extends StatefulWidget {
  const ProfDetailsPage({super.key});

  @override
  State<ProfDetailsPage> createState() => _ProfDetailsPageState();
}

class _ProfDetailsPageState extends State<ProfDetailsPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController officeLocationController =
      TextEditingController();
  final TextEditingController officeHoursController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController profileImageUrlController =
      TextEditingController();

  bool isSubmitting = false;
  bool isLoading = true;
  bool isEditing = false;

  Map<String, String> _originalData = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _restoreOriginalData() {
    fullNameController.text = _originalData['fullName'] ?? '';
    departmentController.text = _originalData['department'] ?? '';
    officeLocationController.text = _originalData['officeLocation'] ?? '';
    officeHoursController.text = _originalData['officeHours'] ?? '';
    bioController.text = _originalData['bio'] ?? '';
    phoneController.text = _originalData['phone'] ?? '';
    profileImageUrlController.text = _originalData['profileImageUrl'] ?? '';
  }

  Future<void> _loadProfileData() async {
    try {
      final userInfo = await ApiService.getUserInfo();
      final email = userInfo['email'];

      if (email == null || email.isEmpty) {
        throw Exception("No email found in user info");
      }

      final profile = await ApiService.getProfessorDetails(email);
      print("📦 PROFILE LOADED FROM API: $profile"); // ✅ Add this line

      setState(() {
        fullNameController.text = profile['full_name'] ?? '';
        departmentController.text = profile['department'] ?? '';
        officeLocationController.text = profile['office_location'] ?? '';
        officeHoursController.text = profile['office_hours'] ?? '';
        bioController.text = profile['bio'] ?? '';
        phoneController.text = profile['phone'] ?? '';
        profileImageUrlController.text = profile['profile_image_url'] ?? '';

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load profile: $e")),
      );
    }
  }

  Future<void> _submitDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final userInfo = await ApiService.getUserInfo();
      final email = userInfo['email'];

      await ApiService.submitProfessorDetails(
        email: email!,
        fullName: fullNameController.text.trim(),
        department: departmentController.text.trim(),
        officeLocation: officeLocationController.text.trim(),
        officeHours: officeHoursController.text.trim(),
        bio: bioController.text.trim(),
        phone: phoneController.text.trim(),
        profileImageUrl: profileImageUrlController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved successfully!")),
      );

      setState(() {
        isEditing = false;
        _originalData = {
          'fullName': fullNameController.text,
          'department': departmentController.text,
          'officeLocation': officeLocationController.text,
          'officeHours': officeHoursController.text,
          'bio': bioController.text,
          'phone': phoneController.text,
          'profileImageUrl': profileImageUrlController.text,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e")),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Widget _buildViewCard(String label, String? value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          value?.isNotEmpty == true ? value! : 'Not provided',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Profile"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).shadowColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isEditing ? _buildEditForm() : _buildViewProfile(),
            ),
    );
  }

  Widget _buildViewProfile() {
    return SingleChildScrollView(
      key: const ValueKey('view'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (profileImageUrlController.text.isNotEmpty)
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(profileImageUrlController.text),
            ),
          const SizedBox(height: 20),
          _buildViewCard('Full Name', fullNameController.text),
          _buildViewCard('Department', departmentController.text),
          _buildViewCard('Office Location', officeLocationController.text),
          _buildViewCard('Office Hours', officeHoursController.text),
          _buildViewCard('Bio', bioController.text),
          _buildViewCard('Phone', phoneController.text),
          _buildViewCard('Image URL', profileImageUrlController.text),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => isEditing = true),
              child: const Text("Edit Profile"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      key: const ValueKey('edit'),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(fullNameController, 'Full Name'),
            _buildTextField(departmentController, 'Department'),
            _buildTextField(officeLocationController, 'Office Location'),
            _buildTextField(officeHoursController, 'Office Hours'),
            _buildTextField(bioController, 'Bio', isOptional: true),
            _buildTextField(phoneController, 'Phone Number', isOptional: true),
            _buildTextField(profileImageUrlController, 'Profile Image URL',
                isOptional: true),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submitDetails,
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Save"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _restoreOriginalData();
                      setState(() => isEditing = false);
                    },
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) =>
            !isOptional && (value == null || value.trim().isEmpty)
                ? "Required"
                : null,
      ),
    );
  }
}
