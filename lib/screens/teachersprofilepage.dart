import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeachersProfilesPage extends StatefulWidget {
  const TeachersProfilesPage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _TeachersProfilesPageState createState() => _TeachersProfilesPageState();
}

class _TeachersProfilesPageState extends State<TeachersProfilesPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Profiles'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search teachers...',
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

       
       
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'teacher')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filtering based on search query
                var teachers = snapshot.data!.docs.where((teacher) {
                  var data = teacher.data() as Map<String, dynamic>;
                  String name = data['name']?.toString().toLowerCase() ?? '';
                  return name.contains(searchQuery);
                }).toList();

                if (teachers.isEmpty) {
                  return const Center(child: Text('No teachers found.'));
                }

                return ListView.builder(
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    var teacher = teachers[index];
                    var data = teacher.data() as Map<String, dynamic>;

                    // Ensure default values if fields are null
                    String imageUrl = data['avatar_url'] as String? ?? '';
                    String name = data['name'] as String? ?? 'Unknown';
                    String address = data['address'] as String? ??
                        'N/A'; // You might need to adjust this field based on your data
                    String teacherphone = data['phone_number'] as String? ??
                        'N/A'; // Adjust according to your data

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : const AssetImage('assets/images/avatar.png')
                                as ImageProvider,
                      ),
                      title: Text(name),
                      subtitle: Text(
                        'Address: $address, Ph.no: $teacherphone', // Adjust according to your data
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
