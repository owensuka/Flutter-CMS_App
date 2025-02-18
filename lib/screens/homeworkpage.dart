import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  _HomeworkPageState createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _userClass;
  String? _userRole;
  String? _selectedClass;
  bool _isLoading = true;
  List<Map<String, dynamic>> _homeworkList = [];
  final List<String> _classes = ['1', '2', '3', '4', '5', '6', '7', '8'];

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
          print('User document data: ${userDoc.data()}'); // Debugging print

          setState(() {
            var data = userDoc.data() as Map<String, dynamic>;
            _userClass = data['class'];
            _userRole = data['role'];
            print('User class: $_userClass');
            print('User role: $_userRole'); // Debugging print
            _selectedClass = _userClass; // Set default class for teachers
            _fetchHomework();
          });
        } else {
          print('User document does not exist');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('User not authenticated');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchHomework() async {
    if (_selectedClass != null) {
      try {
        DocumentSnapshot homeworkDoc =
            await _firestore.collection('homework').doc(_selectedClass!).get();

        print('Fetching homework for class $_selectedClass');

        if (homeworkDoc.exists) {
          var homeworkData = homeworkDoc.data() as Map<String, dynamic>;
          var homeworkList = homeworkData['homework'] as List<dynamic>?;

          print('Homework data: $homeworkData');

          setState(() {
            _homeworkList = homeworkList != null
                ? homeworkList
                    .map((item) => item as Map<String, dynamic>)
                    .toList()
                : [];
            _isLoading = false;
          });
        } else {
          print('No homework document found for class $_selectedClass');
          setState(() {
            _homeworkList = [];
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching homework: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('Selected class is null');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addHomework() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController dueDateController = TextEditingController();
    String? selectedClass;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Homework'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedClass,
                hint: const Text('Select Class'),
                items: _classes.map((classId) {
                  return DropdownMenuItem<String>(
                    value: classId,
                    child: Text('Class $classId'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedClass = value;
                    _selectedClass = value; // Update the selected class
                  });
                },
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: dueDateController,
                decoration: const InputDecoration(labelText: 'Due Date'),
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
                    descriptionController.text.isNotEmpty &&
                    dueDateController.text.isNotEmpty &&
                    selectedClass != null) {
                  try {
                    DocumentReference homeworkRef =
                        _firestore.collection('homework').doc(selectedClass!);

                    await _firestore.runTransaction((transaction) async {
                      DocumentSnapshot snapshot =
                          await transaction.get(homeworkRef);

                      if (!snapshot.exists) {
                        await homeworkRef.set({'homework': []});
                      }

                      List<dynamic> homeworkList = (snapshot.data()
                              as Map<String, dynamic>)['homework'] ??
                          [];
                      homeworkList.add({
                        'id': DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(), // Unique ID
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'due_date': dueDateController.text,
                      });

                      transaction
                          .update(homeworkRef, {'homework': homeworkList});
                    });

                    Navigator.of(context).pop();
                    _fetchHomework(); // Refresh the homework list
                  } catch (e) {
                    print('Error adding homework: $e');
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

  Future<void> _deleteHomework(String homeworkId) async {
    if (_selectedClass != null) {
      try {
        DocumentReference homeworkRef =
            _firestore.collection('homework').doc(_selectedClass!);

        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(homeworkRef);

          if (snapshot.exists) {
            List<dynamic> homeworkList =
                (snapshot.data() as Map<String, dynamic>)['homework'] ?? [];
            homeworkList.removeWhere((item) => item['id'] == homeworkId);

            transaction.update(homeworkRef, {'homework': homeworkList});
          }
        });

        _fetchHomework(); // Refresh the homework list
      } catch (e) {
        print('Error deleting homework: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('User role: $_userRole'); // Debugging print

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework'),
        actions: _userRole == 'teacher'
            ? [
                DropdownButton<String>(
                  value: _selectedClass,
                  hint: const Text('Select Class'),
                  items: _classes.map((classId) {
                    return DropdownMenuItem<String>(
                      value: classId,
                      child: Text('Class $classId'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                      _fetchHomework(); // Fetch homework for the selected class
                    });
                  },
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center()
          : _homeworkList.isEmpty
              ? const Center(child: Text('No homework available'))
              : ListView.builder(
                  itemCount: _homeworkList.length,
                  itemBuilder: (context, index) {
                    final homework = _homeworkList[index];
                    final homeworkId =
                        homework['id'] ?? 'unknown_id'; // Ensure this ID exists

                    return ListTile(
                      title: Text(homework['title'] ?? 'No Title'),
                      subtitle:
                          Text(homework['description'] ?? 'No Description'),
                      trailing: _userRole == 'teacher'
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _deleteHomework(homeworkId);
                              },
                            )
                          : null,
                    );
                  },
                ),
      floatingActionButton: _userRole == 'teacher'
          ? FloatingActionButton(
              onPressed: _addHomework,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
