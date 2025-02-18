import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentProfilesPage extends StatefulWidget {
  const StudentProfilesPage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _StudentProfilesPageState createState() => _StudentProfilesPageState();
}

class _StudentProfilesPageState extends State<StudentProfilesPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profiles'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase(); // Update search query
                });
              },
            ),
          ),

          // Student profiles list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filtering based on search query
                var students = snapshot.data!.docs.where((student) {
                  var data = student.data() as Map<String, dynamic>;
                  String name = data['name']?.toString().toLowerCase() ?? '';
                  return name.contains(searchQuery);
                }).toList();

                if (students.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var student = students[index];
                    var data = student.data() as Map<String, dynamic>;

                    // Ensure default values if fields are null
                    String imageUrl = data['avatar_url'] as String? ?? '';
                    String name = data['name'] as String? ?? 'Unknown';
                    String studentClass = data['class'] as String? ?? 'N/A';
                    String rollNo = data['roll_no'] as String? ?? 'N/A';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : const AssetImage('assets/images/avatar.png')
                                as ImageProvider,
                      ),
                      title: Text(name),
                      subtitle: Text(
                        'Class: $studentClass, Roll No: $rollNo',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
