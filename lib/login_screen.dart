import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms_app/screens/homescreen.dart';
import 'package:cms_app/admin.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isPasswordVisible = false;

  final String _adminEmail = 'admin@example.com';
  final String _adminPassword = 'adminpassword';

  String? _emailError;
  String? _passwordError;

  Future<void> _login() async {
    setState(() {
      _emailError =
          _emailController.text.isEmpty ? 'Please fill up email' : null;
      _passwordError =
          _passwordController.text.isEmpty ? 'Please fill up password' : null;
    });

    if (_emailError != null || _passwordError != null) return;

    try {
      if (_emailController.text == _adminEmail &&
          _passwordController.text == _adminPassword) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      String role = userDoc['role'];

      if (role == widget.role) {
        if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminHomePage()),
          );
        } else if (role == 'student' || role == 'teacher') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          _showErrorDialog('Role not recognized.');
        }
      } else {
        _showErrorDialog('Role mismatch.');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'user-not-found') {
        _showErrorDialog('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        _showErrorDialog('Wrong password provided.');
      } else {
        _showErrorDialog('An error occurred. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;

      _showErrorDialog('An unexpected error occurred. Please try again.');
    } finally {
      setState(() {});
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog('Please enter your email address.');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text);
      _showSuccessDialog('Password reset email sent. Please check your inbox.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        _showErrorDialog('The email address is not valid.');
      } else if (e.code == 'user-not-found') {
        _showErrorDialog('No user found for that email.');
      } else {
        _showErrorDialog('An error occurred. Please try again.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate dynamic font sizes and padding
    final textSizeTitle = screenWidth * 0.05;
    final textSizeField = screenWidth * 0.04;
    final buttonHeight = screenHeight * 0.07;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(fontSize: textSizeTitle),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            top: screenHeight * 0.02,
                            bottom: screenHeight * 0.05),
                        child: Text(
                          'Login as ${widget.role[0].toUpperCase() + widget.role.substring(1)}',
                          style: TextStyle(
                            fontSize: textSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 1, 23, 60),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          iconColor: const Color.fromARGB(255, 1, 23, 60),
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04),
                          errorText: _emailError,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: textSizeField),
                      ),
                      const SizedBox(height: 8.0),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: textSizeField,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          errorText: _passwordError,
                        ),
                        style: TextStyle(fontSize: textSizeField),
                      ),
                      const SizedBox(height: 24.0),
                      SizedBox(
                        width: constraints.maxWidth,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 1, 23, 60),
                            padding: EdgeInsets.symmetric(
                                vertical: buttonHeight * 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                                fontSize: textSizeField, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: _resetPassword,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(fontSize: textSizeField),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
