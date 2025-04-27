import 'package:flutter/material.dart';
import 'auth_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meetme/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.web,
  );
  runApp(const MeetMeApp());
}

class MeetMeApp extends StatelessWidget {
  const MeetMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meet Me',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 77, 11, 21),
        secondaryHeaderColor: const Color.fromARGB(255, 140, 22, 39),
        hintColor: const Color.fromARGB(255, 82, 82, 82),
        scaffoldBackgroundColor: const Color.fromARGB(255, 235, 235, 235),
        shadowColor: const Color.fromARGB(255, 10, 10, 10),
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: const LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  LoadingScreenState createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _userController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isSignUp = false;
  bool _isProfessor = false;
  bool _isStudent = false;

  void _resetTextFields() {
    _emailController.clear();
    _passController.clear();
    _userController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Theme.of(context).scaffoldBackgroundColor),
          Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.26),
            child: Center(
              child: Image.asset(
                'assets/logo-png.png',
                width: screenWidth * 0.85,
                height: screenHeight * 0.35,
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.06,
            minChildSize: 0.06,
            maxChildSize: 0.5,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).secondaryHeaderColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      const SizedBox(height: 30),
                      Text(
                        _isSignUp ? 'Create Account' : 'Sign In',
                        style: TextStyle(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_isSignUp && !_isProfessor && !_isStudent) ...[
                        _buildBackButton(context),
                        const SizedBox(height: 20),
                        _buildTitle(context),
                        const SizedBox(height: 30),
                        _buildUserTypeButton(context, 'Professor',
                            () => _isProfessor = true, screenWidth),
                        const SizedBox(height: 20),
                        _buildUserTypeButton(context, 'Student',
                            () => _isStudent = true, screenWidth),
                      ] else ...[
                        _buildTextFields(context, screenWidth),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSignUp = false;
          _resetTextFields();
        });
      },
      child: Row(
        children: [
          Icon(Icons.arrow_back_ios,
              color: Theme.of(context).scaffoldBackgroundColor),
          Text(
            'Back',
            style: TextStyle(
              color: Theme.of(context).scaffoldBackgroundColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Center(
      child: Text(
        'Are you a Professor or a Student?',
        style: TextStyle(
          color: Theme.of(context).scaffoldBackgroundColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildUserTypeButton(BuildContext context, String label,
      VoidCallback onPressed, double screenWidth) {
    return Center(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: SizedBox(
          width: screenWidth * 0.8,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              setState(onPressed);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).shadowColor,
                fontSize: 24,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFields(BuildContext context, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField(_emailController, Icons.email_outlined, 'Email', context),
        const SizedBox(height: 10),
        if (_isSignUp)
          _textField(
              _userController, Icons.person_2_outlined, 'User Name', context),
        const SizedBox(height: 10),
        _passwordField(context),
        const SizedBox(height: 25),
        _continueButton(context, screenWidth),
        const SizedBox(height: 15),
        _toggleSignInSignUp(context),
        const SizedBox(height: 5),
        if (!_isSignUp)
          Text(
            'Forget Password?',
            style: TextStyle(
              color: Theme.of(context).scaffoldBackgroundColor,
              fontSize: 15,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _textField(TextEditingController controller, IconData icon,
      String hint, BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: Theme.of(context).scaffoldBackgroundColor,
        fontSize: 18,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon:
            Icon(icon, color: Theme.of(context).scaffoldBackgroundColor),
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).scaffoldBackgroundColor,
          fontSize: 18,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            width: 1,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            width: 1,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }

  Widget _passwordField(BuildContext context) {
    return TextField(
      controller: _passController,
      obscureText: !_isPasswordVisible,
      style: TextStyle(
        color: Theme.of(context).scaffoldBackgroundColor,
        fontSize: 18,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline,
            color: Theme.of(context).scaffoldBackgroundColor),
        hintText: 'Password',
        hintStyle: TextStyle(
          color: Theme.of(context).scaffoldBackgroundColor,
          fontSize: 18,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            width: 1,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            width: 1,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }

  Widget _continueButton(BuildContext context, double screenWidth) {
    return Center(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: SizedBox(
          width: screenWidth * 0.8,
          height: 55,
          child: ElevatedButton(
            onPressed: () async {
              final success = await AuthController.handleSignUpOrLogin(
                email: _emailController.text.trim(),
                username: _userController.text.trim(),
                password: _passController.text.trim(),
                isSignUp: _isSignUp,
                isProfessor: _isProfessor,
                isStudent: _isStudent,
                context: context,
              );
              if (success && _isSignUp) {
                setState(() {
                  _isSignUp = false;
                  _isProfessor = false;
                  _isStudent = false;
                  _resetTextFields();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                color: Theme.of(context).shadowColor,
                fontSize: 24,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleSignInSignUp(BuildContext context) {
    return Row(
      children: [
        Text(
          _isSignUp ? 'Already have an account?' : 'Don’t have an account?',
          style: TextStyle(
            color: Theme.of(context).shadowColor,
            fontSize: 15,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 5),
        InkWell(
          onTap: () {
            setState(() {
              _isSignUp = !_isSignUp;
              _isProfessor = false;
              _isStudent = false;
              _resetTextFields();
            });
          },
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: TextStyle(
              color: Theme.of(context).scaffoldBackgroundColor,
              fontSize: 15,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
