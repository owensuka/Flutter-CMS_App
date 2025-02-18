import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cms_app/admin.dart';
import 'package:cms_app/screens/homescreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Splash Screen Widget
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to AuthWrapper after 5 seconds
    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define font size relative to screen width
    final textSizeSmall = screenWidth * 0.03; // Small text size
    final textSizeLarge = screenWidth * 0.05; // Large text size

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Logo.png',
              width: screenWidth * 0.5, // Responsive logo width
              height: screenHeight * 0.25, // Responsive logo height
            ),
            SizedBox(height: screenHeight * 0.03), // Responsive spacing
            Text(
              'Developed by-',
              style: GoogleFonts.sofadiOne(
                fontSize: textSizeSmall, // Adaptive font size
                color: const Color.fromARGB(255, 1, 23, 60),
              ),
            ),
            Text(
              'Lalchhanchhuaha',
              style: GoogleFonts.kanit(
                fontSize: textSizeLarge, // Adaptive font size
                color: const Color.fromARGB(255, 1, 23, 60),
              ),
            ),
            Text(
              'Zion Ramdinthara',
              style: GoogleFonts.kanit(
                fontSize: textSizeLarge, // Adaptive font size
                color: const Color.fromARGB(255, 1, 23, 60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Auth Wrapper Widget to navigate to respective screens
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(),
          );
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<String>(
            future: _getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(),
                );
              } else if (roleSnapshot.hasData) {
                final role = roleSnapshot.data!;
                switch (role) {
                  case 'admin':
                    return const AdminHomePage();
                  case 'student':
                  case 'teacher':
                    return const HomePage();
                  default:
                    return const MainScreen();
                }
              } else {
                return const MainScreen();
              }
            },
          );
        } else {
          return const MainScreen();
        }
      },
    );
  }

  Future<String> _getUserRole(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = userDoc.data()?['role'] ?? 'unknown';
      return role;
    } catch (e) {
      return 'unknown';
    }
  }
}

// Main Screen with adaptive buttons, text, and icons
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String selectedRole = '';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // ignore: unused_local_variable
    final textSizeSmall = screenWidth * 0.04;
    final textSizeMedium = screenWidth * 0.05;
    // ignore: unused_local_variable
    final textSizeLarge = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Logo.png',
              width: screenWidth * 0.5, // Responsive width for logo
              height: screenHeight * 0.25, // Responsive height for logo
            ),
            SizedBox(height: screenHeight * 0.07), // Responsive spacing
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05), // Responsive padding
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color.fromARGB(255, 1, 23, 60), width: 2),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(255, 240, 240, 240),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRoleIcon(
                    context,
                    icon: Icons.school,
                    label: 'Student',
                    role: 'student',
                    textSize: textSizeMedium,
                    screenWidth: screenWidth,
                  ),
                  _buildRoleIcon(
                    context,
                    icon: Icons.person,
                    label: 'Teacher',
                    role: 'teacher',
                    textSize: textSizeMedium,
                    screenWidth: screenWidth,
                  ),
                  _buildRoleIcon(
                    context,
                    icon: Icons.admin_panel_settings,
                    label: 'Admin',
                    role: 'admin',
                    textSize: textSizeMedium,
                    screenWidth: screenWidth,
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.07), // Responsive spacing
            ElevatedButton(
              onPressed: () {
                if (selectedRole.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(role: selectedRole),
                    ),
                  );
                } else {
                  _showErrorDialog(context, 'Please select a role.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 23, 60),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.3,
                  vertical: screenHeight * 0.02,
                ),
                textStyle: TextStyle(fontSize: textSizeMedium),
              ),
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            ElevatedButton(
              onPressed: () => _launchAdmissionURL(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 23, 60),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.25,
                  vertical: screenHeight * 0.02,
                ),
                textStyle: TextStyle(fontSize: textSizeMedium),
              ),
              child: const Text(
                'Admission',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleIcon(BuildContext context,
      {required IconData icon,
      required String label,
      required String role,
      required double textSize,
      required double screenWidth}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: screenWidth * 0.1,
            color: selectedRole == role
                ? const Color.fromARGB(255, 227, 71, 5)
                : const Color.fromARGB(255, 1, 23, 60),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            label,
            style: TextStyle(
              color: selectedRole == role
                  ? const Color.fromARGB(255, 227, 71, 5)
                  : const Color.fromARGB(255, 1, 23, 60),
              fontSize: textSize,
            ),
          ),
        ],
      ),
    );
  }

  void _launchAdmissionURL(BuildContext context) async {
    const url = 'https://forms.gle/v5TSnmXWwvxy7EpMA';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showErrorDialog(context, 'Could not launch $url');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
