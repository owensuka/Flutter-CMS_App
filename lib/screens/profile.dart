// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      final fileName = 'profile_images/${user.uid}.jpg';
      final ref =
          firebase_storage.FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(_imageFile!);

      final downloadUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'avatar_url': downloadUrl,
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _updateUserData(String field, String value) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({field: value});
    }
  }

  Future<void> _showEditDialog(String field, String currentValue) async {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Enter new value',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await _updateUserData(field, controller.text);
                  if (mounted) {
                    setState(() {}); // Refresh the widget state
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Field cannot be empty')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFullScreenImage(String imageUrl) async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: Image.network(imageUrl),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileField(String label, String? value, String field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color.fromARGB(42, 52, 171, 245), width: 2.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.only(left: 30, top: 5, bottom: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '$label: ${value ?? 'Not provided'}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showEditDialog(field, value ?? '');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField(String userName) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            userName,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditDialog('name', userName);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 52, 171, 245),
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text('Profile'),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String role = userData['role'] ?? 'student';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    _showFullScreenImage(
                        userData['avatar_url'] ?? 'assets/images/avatar.png');
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (userData['avatar_url'] != null
                                ? NetworkImage(userData['avatar_url'])
                                : const AssetImage('assets/images/avatar.png')
                                    as ImageProvider),
                      ),
                      GestureDetector(
                        onTap: _pickImage, // Trigger image picker on tap
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildUsernameField(userData['name'] ?? 'Unknown'),
                const SizedBox(height: 20),
                if (role == 'student') ...[
                  _buildProfileField("Class", userData['class'], 'class'),
                  _buildProfileField(
                      "Roll Number", userData['roll_no'], 'roll_no'),
                  _buildProfileField(
                      "Parent's Name", userData['parent_name'], 'parent_name'),
                ] else if (role == 'teacher') ...[
                  _buildProfileField("Qualification", userData['qualification'],
                      'qualification'),
                ],
                _buildProfileField(
                    "Phone Number", userData['phone_number'], 'phone_number'),
                _buildProfileField("Address", userData['address'], 'address'),
              ],
            ),
          );
        },
      ),
    );
  }
}
