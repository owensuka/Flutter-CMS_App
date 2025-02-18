// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cms_app/main.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  // ignore: unused_field
  String _errorMessage = '';
  bool _isStudentChecked = true;
  bool _isTeacherChecked = false;

  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  bool _isUploading = false;

  Future<List<String>> _fetchCombinedImages() async {
    List<String> combinedImageUrls = [];

    try {
      // Fetch student images
      DocumentSnapshot studentDoc =
          await _firestore.collection('image_pickers').doc('students').get();
      if (studentDoc.exists) {
        combinedImageUrls
            .addAll(List<String>.from(studentDoc['image_urls'] ?? []));
      }

      // Fetch teacher images
      DocumentSnapshot teacherDoc =
          await _firestore.collection('image_pickers').doc('teachers').get();
      if (teacherDoc.exists) {
        combinedImageUrls
            .addAll(List<String>.from(teacherDoc['image_urls'] ?? []));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch images: $e')),
      );
    }

    return combinedImageUrls;
  }

  Future<void> _deleteImage(String imageUrl, String s) async {
    try {
      // Delete the image from Firebase Storage
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      // Update the students document
      DocumentSnapshot studentDoc =
          await _firestore.collection('image_pickers').doc('students').get();
      if (studentDoc.exists) {
        List<String> studentImageUrls =
            List<String>.from(studentDoc['image_urls'] ?? []);
        if (studentImageUrls.contains(imageUrl)) {
          studentImageUrls.remove(imageUrl);
          await _firestore.collection('image_pickers').doc('students').update({
            'image_urls': studentImageUrls,
          });
        }
      }

      // Update the teachers document
      DocumentSnapshot teacherDoc =
          await _firestore.collection('image_pickers').doc('teachers').get();
      if (teacherDoc.exists) {
        List<String> teacherImageUrls =
            List<String>.from(teacherDoc['image_urls'] ?? []);
        if (teacherImageUrls.contains(imageUrl)) {
          teacherImageUrls.remove(imageUrl);
          await _firestore.collection('image_pickers').doc('teachers').update({
            'image_urls': teacherImageUrls,
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully')),
      );

      // Trigger a rebuild to refresh the UI
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete image: $e')),
      );
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Map<String, dynamic> userData;

      if (_isStudentChecked) {
        userData = {
          'email': _emailController.text.trim(),
          'role': 'student',
          'name': 'null',
          'address': 'null',
          'phone_number': 'null',
          'class': 'null',
          'roll_no': 'null',
          'parent_name': 'null',
          'avatar_url': 'null',
          'qualification': 'null', // Make sure it's null for students
        };
      } else if (_isTeacherChecked) {
        userData = {
          'email': _emailController.text.trim(),
          'role': 'teacher',
          'name': 'null',
          'address': 'null',
          'phone_number': 'null',
          'qualification': 'null',
          'avatar_url': 'null',
          // Fields specific to teachers
        };
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      _emailController.clear();
      _passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const MainScreen()), // Update this to your MainScreen or entry point
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                },
                child: const Text('Exit'),
              ),
            ],
          ),
        )) ??
        false;
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    // ignore: unnecessary_null_comparison
    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _uploadImages() async {
    setState(() {
      _isUploading = true;
    });

    List<String> newDownloadUrls = [];
    for (File image in _images) {
      try {
        // Compress the image
        final compressedImage = await FlutterImageCompress.compressWithFile(
          image.path,
          minWidth: 800,
          minHeight: 600,
          quality: 80,
        );

        // Create a temporary file to store the compressed image
        final tempFile = File('${image.path}_compressed');
        await tempFile.writeAsBytes(compressedImage!);

        // Upload the compressed image
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        TaskSnapshot uploadTask = await _storage
            .ref()
            .child('image_pickers/students/$fileName')
            .putFile(tempFile);

        String downloadUrl = await uploadTask.ref.getDownloadURL();
        newDownloadUrls.add(downloadUrl);

        // Delete the temporary file
        await tempFile.delete();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }
    }

    // Fetch existing student image URLs and append new ones
    DocumentSnapshot studentDoc =
        await _firestore.collection('image_pickers').doc('students').get();
    List<String> existingStudentImageUrls =
        List<String>.from(studentDoc['image_urls'] ?? []);
    existingStudentImageUrls.addAll(newDownloadUrls);

    // Fetch existing teacher image URLs and append new ones
    DocumentSnapshot teacherDoc =
        await _firestore.collection('image_pickers').doc('teachers').get();
    List<String> existingTeacherImageUrls =
        List<String>.from(teacherDoc['image_urls'] ?? []);
    existingTeacherImageUrls.addAll(newDownloadUrls);

    // Update Firestore with the new image URLs for both students and teachers
    await _firestore.collection('image_pickers').doc('students').update({
      'image_urls': existingStudentImageUrls,
    });

    await _firestore.collection('image_pickers').doc('teachers').update({
      'image_urls': existingTeacherImageUrls,
    });

    setState(() {
      _isUploading = false;
      _images.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Images uploaded successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      // ignore: deprecated_member_use
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _isStudentChecked,
                          onChanged: (value) {
                            setState(() {
                              _isStudentChecked = value ?? false;
                              _isTeacherChecked = !(_isStudentChecked);
                            });
                          },
                        ),
                        const Text('Student'),
                        Checkbox(
                          value: _isTeacherChecked,
                          onChanged: (value) {
                            setState(() {
                              _isTeacherChecked = value ?? false;
                              _isStudentChecked = !(_isTeacherChecked);
                            });
                          },
                        ),
                        const Text('Teacher'),
                      ],
                    ),
                    if (_isLoading) const CircularProgressIndicator(),
                    if (!_isLoading)
                      ElevatedButton(
                        onPressed: _createUser,
                        child: const Text('Create User'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImages,
                child: const Text('Pick Images'),
              ),
              const SizedBox(height: 20),
              if (_images.isNotEmpty)
                ElevatedButton(
                  onPressed: _uploadImages,
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Upload Images'),
                ),
              const SizedBox(height: 20),
              FutureBuilder<List<String>>(
                future: _fetchCombinedImages(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No images available');
                  }
                  return CarouselSlider(
                    options: CarouselOptions(height: 400.0),
                    items: snapshot.data!.map((imageUrl) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(imageUrl, fit: BoxFit.cover),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _deleteImage(imageUrl, 'students'),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
