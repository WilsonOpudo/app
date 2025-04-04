import 'package:flutter/material.dart';
import 'api_service.dart';
import 'student_pages.dart'; // Replace with your actual professor/student screens if needed
import 'professor_pages.dart';

class AuthController {
  static Future<void> handleSignUpOrLogin({
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
          _showError(context, "Please select a role before signing up.");
          return;
        }

        // Get role string
        final role = isProfessor ? "professor" : "student";

        // Validate fields
        if (email.isEmpty || username.isEmpty || password.isEmpty) {
          _showError(context, "Please fill in all sign-up fields.");
          return;
        }

        await ApiService.createAccount(email, username, password, role);

        // After sign-up, go to login screen (switch _isSignUp in your state)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created! Please sign in.")),
        );
      } else {
        // Validate fields
        if (email.isEmpty || password.isEmpty) {
          _showError(context, "Please fill in all login fields.");
          return;
        }

        await ApiService.login(email, password);

        final userInfo = await ApiService.getUserInfo();
        final role = userInfo['role'];

        if (role == "student") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (role == "professor") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const ProfessorHomePage()), // replace with ProfessorPage
          );
        } else {
          _showError(context, "Unknown user role.");
        }
      }
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  static void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
