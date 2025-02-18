import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notice_detail_page.dart'; // Import the new detail page

class NoticePage extends StatefulWidget {
  const NoticePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NoticePageState createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _userRole;
  bool _isLoading = true;
  List<Map<String, dynamic>> _noticeList = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _userRole = userDoc['role'];
            _fetchNotices();
          });
        } else {
          throw Exception('User document does not exist');
        }
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNotices() async {
    try {
      QuerySnapshot noticesSnapshot =
          await _firestore.collection('notices').get();

      setState(() {
        _noticeList = noticesSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching notices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNotice() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Notice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: imageUrlController,
                decoration:
                    const InputDecoration(labelText: 'Image URL (optional)'),
              ),
            ],
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
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  try {
                    await _firestore.collection('notices').add({
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'image_url': imageUrlController.text.isNotEmpty
                          ? imageUrlController.text
                          : null,
                    });

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                    _fetchNotices(); // Refresh the notice list
                  } catch (e) {
                    // ignore: avoid_print
                    print('Error adding notice: $e');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
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

  Future<void> _deleteNotice(String noticeId) async {
    try {
      await _firestore.collection('notices').doc(noticeId).delete();
      _fetchNotices(); // Refresh the notice list
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting notice: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _noticeList.isEmpty
              ? const Center(child: Text('No notices available'))
              : ListView.builder(
                  itemCount: _noticeList.length,
                  itemBuilder: (context, index) {
                    final notice = _noticeList[index];
                    final noticeId = notice['id'] ??
                        'unknown_id'; // Unique ID should be present

                    return ListTile(
                      title: Text(notice['title'] ?? 'No Title'),
                      subtitle: Text(notice['description'] ?? 'No Description'),
                      trailing: _userRole == 'teacher'
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _deleteNotice(noticeId);
                              },
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoticeDetailPage(
                              notice: notice,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: _userRole == 'teacher'
          ? FloatingActionButton(
              onPressed: _addNotice,
              // ignore: sort_child_properties_last
              child: const Icon(Icons.add),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }
}
