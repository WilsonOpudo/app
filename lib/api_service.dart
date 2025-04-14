import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000'; // Local testing
  //static const String baseUrl = 'http://10.0.2.2:8000'; // andriod emulator
  //static const String baseUrl = 'http://192.168.12.223:8000'; //iphone web
  //static const String baseUrl = 'http://10.80.82.55:8000';

  static WebSocketChannel? _channel;

  static WebSocketChannel connectToChat(String userId) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:8000/ws/chat/$userId'),
    );
    return _channel!;
  }

  static void sendMessage(String senderId, String receiverId, String message) {
    if (_channel != null) {
      final data = {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
      };
      _channel!.sink.add(jsonEncode(data));
    }
  }

  static void disconnectChat() {
    _channel?.sink.close();
    _channel = null;
  }

  static Future<List<Map<String, dynamic>>> getChatHistory(
      String user1, String user2) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/history?user1=$user1&user2=$user2'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch chat history: ${response.body}');
    }
  }

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
    required String professorEmail,
    String? description, // <- Add this
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'course_id': courseId,
        'course_name': courseName,
        'professor_name': professorName,
        'professor_email': professorEmail,
        'description': description ?? '', // <- Send this too
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
        'student_name': studentName,
        'student_email': studentEmail,
        'course_id': courseId,
        'course_name': courseName,
        'professor_name': professorName,
        'appointment_date': dateTime.toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create appointment: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getAppointments(
      String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/appointments/student/$email'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load appointments: ${response.body}');
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

  static Future<String> getProfessorEmailFromCourse(String courseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/professor-email/from-course/$courseId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['email'];
    } else {
      throw Exception('Failed to fetch professor email');
    }
  }

  static Future<Map<String, dynamic>> getUserByUsername(String username) async {
    final encodedUsername = Uri.encodeComponent(username);
    final response = await http.get(
      Uri.parse('$baseUrl/users/username/$encodedUsername'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('User not found: ${response.body}');
    }
  }

  // ✅ Create Available Slot (Professor)
  static Future<void> addAvailableSlot({
    required String professorEmail,
    required String courseId,
    required String date, // YYYY-MM-DD
    required String time, // HH:MM (24-hour)
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/slots'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'professor_email': professorEmail,
        'course_id': courseId,
        'date': date,
        'time': time,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add slot: ${response.body}');
    }
  }

// ✅ Get Slots for a Course
  static Future<List<Map<String, dynamic>>> getAvailableSlots({
    required String professorEmail,
    required String courseId,
    required String date,
  }) async {
    final encodedEmail = Uri.encodeComponent(professorEmail);
    final response = await http.get(Uri.parse(
      '$baseUrl/available-slots?professor_email=$encodedEmail&course_id=$courseId&date=$date',
    ));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch available slots: ${response.body}');
    }
  }

  static Future<void> saveAvailableSlot({
    required String professorEmail,
    required String courseId,
    required String date,
    required String time,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/available-slots'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'professor_email': professorEmail,
        'course_id': courseId,
        'date': date,
        'time': time,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save available slot: ${response.body}');
    }
  }

  // Delete an available slot
  static Future<void> deleteAvailableSlot({
    required String professorEmail,
    required String courseId,
    required String date,
    required String time,
  }) async {
    final uri = Uri.parse(
        '$baseUrl/available-slots?professor_email=$professorEmail&course_id=$courseId&date=$date&time=$time');

    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete slot: ${response.body}');
    }
  }

  static Future<void> cancelAppointment(String appointmentId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to cancel appointment: ${response.body}");
    }
  }

  static Future<List<Map<String, dynamic>>> getProfessorAppointments(
      String courseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/appointments/professor/$courseId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch appointments: ${response.body}');
    }
  }

  static Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDateTime,
    required String courseId,
    required String studentEmail,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/appointments/$appointmentId/reschedule'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'new_datetime': newDateTime.toIso8601String(),
        'course_id': courseId,
        'student_email': studentEmail,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to reschedule appointment: ${response.body}");
    }
  }

  static Future<String> getAppointmentStatus(String appointmentId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/appointments/status/$appointmentId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] ?? 'unknown';
    } else {
      throw Exception('Failed to get status');
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentsInClass(
      String courseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/classes/$courseId/students'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to fetch students for class $courseId: ${response.body}');
    }
  }
}
