import 'package:flutter/material.dart';
import 'api_service.dart';
import 'student_pages.dart';
import 'professor_pages.dart';

class AuthController {
  static Future<bool> handleSignUpOrLogin({
    required String email,
    required String username,
    required String password,
    required bool isSignUp,
    required bool isProfessor,
    required bool isStudent,
    required BuildContext context,
  }) async {
    try {
      if (isSignUp) {
        // Validate role selection
        if (!isProfessor && !isStudent) {
          _showSnackBar(context, "Please select a role before signing up.");
          return false;
        }

        // Validate fields
        if (email.isEmpty || username.isEmpty || password.isEmpty) {
          _showSnackBar(context, "Please fill in all sign-up fields.");
          return false;
        }

        if (!_isValidEmail(email)) {
          _showSnackBar(context, "Please enter a valid email.");
          return false;
        }
        if (username.length < 5 || username.length > 20) {
          _showSnackBar(context, "Username must be 5–20 characters.");
          return false;
        }
        if (!_isValidPassword(password)) {
          _showSnackBar(context, "Password is incorrect (min 4 characters).");
          return false;
        }

        final role = isProfessor ? "professor" : "student";
        await ApiService.createAccount(email, username, password, role);
        _showSnackBar(context, "Account created! Please sign in.");
        return true;
      } else {
        // Login flow
        if (email.isEmpty || password.isEmpty) {
          _showSnackBar(context, "Please fill in all login fields.");
          return false;
        }

        if (!_isValidEmail(email)) {
          _showSnackBar(context, "Please enter a valid email.");
          return false;
        }

        if (!_isValidPassword(password)) {
          _showSnackBar(context, "Password is incorrect (min 4 characters).");
          return false;
        }

        await ApiService.login(email, password);

        final userInfo = await ApiService.getUserInfo();
        final role = userInfo['role'];

        if (role == "student") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentHomePage()),
          );
        } else if (role == "professor") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfessorHomePage()),
          );
        } else {
          _showSnackBar(context, "Unknown user role.");
          return false;
        }

        return true;
      }
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains("user not found") || message.contains("not found")) {
        _showSnackBar(context, "User not found.");
      } else if (message.contains("invalid credentials")) {
        _showSnackBar(context, "Incorrect email or password.");
      } else {
        _showSnackBar(context, "Error: ${e.toString()}");
      }
      return false;
    }
  }

  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool _isValidPassword(String password) {
    return password.length >= 4;
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 11, 11, 11),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
