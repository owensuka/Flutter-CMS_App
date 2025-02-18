import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? _userClass;
  String? _userRole;
  String? _selectedClass;
  bool _isLoading = true;
  bool _isUploading = false; // Track upload status
  List<Map<String, dynamic>> _resultsList = [];
  final List<String> _classes = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII'
  ];

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
            var data = userDoc.data() as Map<String, dynamic>;
            _userClass = data['class'];
            _userRole = data['role'];
            _selectedClass = _userClass;
            _fetchResults();
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
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

  Future<void> _fetchResults() async {
    if (_selectedClass != null) {
      try {
        DocumentSnapshot resultsDoc =
            await _firestore.collection('results').doc(_selectedClass!).get();

        if (resultsDoc.exists) {
          var resultsData = resultsDoc.data() as Map<String, dynamic>;
          var resultsList = resultsData['results'] as List<dynamic>?;

          setState(() {
            _resultsList = resultsList != null
                ? resultsList
                    .map((item) => item as Map<String, dynamic>)
                    .toList()
                : [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _resultsList = [];
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching results: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadResults() async {
    final TextEditingController titleController = TextEditingController();
    String? selectedClass;
    File? pickedFile;

    // Pick a PDF file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      pickedFile = File(result.files.single.path!);
    } else {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_userRole == 'teacher') ...[
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
                      _selectedClass = value;
                    });
                  },
                ),
              ],
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
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
                    selectedClass != null &&
                    pickedFile != null) {
                  setState(() {
                    _isUploading = true;
                  });

                  try {
                    String fileName =
                        DateTime.now().millisecondsSinceEpoch.toString();
                    Reference storageRef = _storage
                        .ref()
                        .child('results/${selectedClass!}/$fileName.pdf');

                    await storageRef.putFile(pickedFile);

                    String fileUrl = await storageRef.getDownloadURL();

                    DocumentReference resultsRef =
                        _firestore.collection('results').doc(selectedClass!);

                    await _firestore.runTransaction((transaction) async {
                      DocumentSnapshot snapshot =
                          await transaction.get(resultsRef);

                      if (!snapshot.exists) {
                        await resultsRef.set({'results': []});
                      }

                      List<dynamic> resultsList = (snapshot.data()
                              as Map<String, dynamic>)['results'] ??
                          [];
                      resultsList.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'title': titleController.text,
                        'file_url': fileUrl,
                      });

                      transaction.update(resultsRef, {'results': resultsList});
                    });

                    Navigator.of(context).pop();
                    _fetchResults();
                  } catch (e) {
                    print('Error uploading results: $e');
                  } finally {
                    setState(() {
                      _isUploading = false;
                    });
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteResult(String resultId) async {
    if (_selectedClass != null) {
      try {
        DocumentReference resultsRef =
            _firestore.collection('results').doc(_selectedClass!);

        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(resultsRef);

          if (snapshot.exists) {
            List<dynamic> resultsList =
                (snapshot.data() as Map<String, dynamic>)['results'] ?? [];
            resultsList.removeWhere((item) => item['id'] == resultId);

            transaction.update(resultsRef, {'results': resultsList});
          }
        });

        _fetchResults();
      } catch (e) {
        print('Error deleting result: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: _userRole == 'teacher' ? [] : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resultsList.isEmpty
              ? const Center(child: Text('No results available'))
              : ListView.builder(
                  itemCount: _resultsList.length,
                  itemBuilder: (context, index) {
                    final result = _resultsList[index];
                    final resultId = result['id'] ?? 'unknown_id';

                    return ListTile(
                      title: Text(result['title'] ?? 'No Title'),
                      subtitle: result['file_url'] != null
                          ? InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PDFViewerPage(
                                      fileUrl: result['file_url']!,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View PDF'),
                            )
                          : const Text('No URL'),
                      trailing: _userRole == 'teacher'
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _deleteResult(resultId);
                              },
                            )
                          : null,
                    );
                  },
                ),
      floatingActionButton: _userRole == 'teacher'
          ? FloatingActionButton(
              onPressed: _uploadResults,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.upload_file),
            )
          : null,
    );
  }
}

class PDFViewerPage extends StatelessWidget {
  final String fileUrl;

  const PDFViewerPage({super.key, required this.fileUrl});

  Future<String> _downloadAndSavePDF(String url) async {
    final http.Response response = await http.get(Uri.parse(url));
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/temp.pdf');
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: FutureBuilder<String>(
        future: _downloadAndSavePDF(fileUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return PDFView(
              filePath: snapshot.data!,
            );
          } else {
            return const Center(child: Text('No PDF found'));
          }
        },
      ),
    );
  }
}
