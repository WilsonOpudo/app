import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000'; // Local testing

  // You can still save email/role if needed
  static Future<void> saveUserInfo(String email, String role,
      [String? username]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('role', role);
    if (username != null) {
      await prefs.setString('username', username);
    }
  }

  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('email'),
      'role': prefs.getString('role'),
      'username': prefs.getString('username'), // added
    };
  }

  static Future<void> createAccount(
      String email, String username, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
        "role": role,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create account: ${response.body}');
    }
  }

  static Future<Map<String, String>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userEmail = data['email'];
      final role = data['role'];
      final username = data['username']; // ✅ This must come from backend

      // ✅ Save to SharedPreferences
      await saveUserInfo(userEmail, role, username);

      return {
        "email": userEmail,
        "role": role,
        "username": username,
      };
    } else {
      throw Exception('Failed to log in: ${response.body}');
    }
  }

  static Future<void> createClass({
    required String courseId,
    required String courseName,
    required String professorName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'course_id': courseId,
        'course_name': courseName,
        'professor_name': professorName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create class: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getClasses() async {
    final response = await http.get(Uri.parse('$baseUrl/classes'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch classes: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getClassById(String courseId) async {
    final response = await http.get(Uri.parse('$baseUrl/classes/$courseId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch class: ${response.body}');
    }
  }

  static Future<void> enrollInClass({
    required String courseId,
    required String studentEmail,
    required String studentUsername, // ✅ make sure you're using stored username
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/enrollments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'course_id': courseId,
        'student_email': studentEmail,
        'student_username': studentUsername, // ✅ crucial
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to enroll in class: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getEnrolledClasses(
      String studentEmail) async {
    final response =
        await http.get(Uri.parse('$baseUrl/enrollments/student/$studentEmail'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch enrolled classes: ${response.body}');
    }
  }

  static Future<void> createAppointment({
    required String studentName,
    required String studentEmail,
    required String courseId,
    required String courseName,
    required String professorName,
    required DateTime dateTime,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'studentName': studentName,
        'studentEmail': studentEmail,
        'courseId': courseId,
        'courseName': courseName,
        'professorName': professorName,
        'appointment_date': dateTime.toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create appointment: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getAppointments() async {
    final response = await http.get(Uri.parse('$baseUrl/appointments'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch appointments: ${response.body}');
    }
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/appointments/$appointmentId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete appointment: ${response.body}');
    }
  }

  static Future<void> deleteClass(String courseId) async {
    final response = await http.delete(Uri.parse('$baseUrl/classes/$courseId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete class: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentsForClass(
      String courseId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/classes/$courseId/students'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch students: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getUserByEmail(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$email'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  static Future<void> submitProfessorDetails({
    required String email,
    required String fullName,
    required String department,
    required String officeLocation,
    required String officeHours, // ✅ required
    String? bio,
    String? phone,
    String? profileImageUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/professors/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'department': department,
        'office_location': officeLocation,
        'office_hours': officeHours, // ✅ required field
        'bio': bio ?? '',
        'phone': phone ?? '',
        'profile_image_url': profileImageUrl ?? '',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit professor details: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getProfessorDetails(String email) async {
    final encodedEmail = Uri.encodeComponent(email); // 🔑 Handles '@' -> '%40'
    final response = await http.get(
      Uri.parse('$baseUrl/professors/profile/$encodedEmail'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch professor details: ${response.body}');
    }
  }
}
