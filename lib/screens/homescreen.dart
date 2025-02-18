import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cms_app/main.dart';
import 'package:cms_app/screens/eventpage.dart';
import 'package:cms_app/screens/homeworkpage.dart';
import 'package:cms_app/screens/noticepage.dart';
import 'package:cms_app/screens/profile.dart';
import 'package:cms_app/screens/resultspage.dart';
import 'package:cms_app/screens/settings_page.dart';
import 'package:cms_app/screens/studentsprofile.dart';
import 'package:cms_app/screens/teachersprofilepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sample image URLs for the carousel
  final List<String> imgList = [
    'https://via.placeholder.com/800x400?text=Image+1',
    'https://via.placeholder.com/800x400?text=Image+2',
    'https://via.placeholder.com/800x400?text=Image+3',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload images
    precacheImage(const AssetImage('assets/images/homework.png'), context);
    precacheImage(const AssetImage('assets/images/notice.png'), context);
    precacheImage(const AssetImage('assets/images/events.png'), context);
    precacheImage(const AssetImage('assets/images/teachers.png'), context);
    precacheImage(const AssetImage('assets/images/students.png'), context);
    precacheImage(const AssetImage('assets/images/result.png'), context);
  }

  Future<List<String>> _fetchImageUrls() async {
    try {
      final document = await FirebaseFirestore.instance
          .collection('image_pickers')
          .doc('students')
          .get();
      if (document.exists) {
        final data = document.data();
        if (data != null && data['image_urls'] != null) {
          return List<String>.from(data['image_urls']);
        }
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching images: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user is logged in')),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 150,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(top: 0.0, bottom: 90),
          child: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ),
        flexibleSpace: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center();
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('No data found'));
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String role = userData['role'] ??
                'student'; // Default to student if role is missing

            return Container(
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 70, left: 40),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: userData['avatar_url'] != null &&
                                userData['avatar_url'].isNotEmpty
                            ? CachedNetworkImageProvider(userData['avatar_url'])
                            : const AssetImage('assets/images/me.jpg')
                                as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userData['name'] ?? 'Name',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          role == 'teacher'
                              ? Text(
                                  'Phone: ${userData['phone_number'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16),
                                )
                              : Text(
                                  'Class: ${userData['class'] ?? 'N/A'} Roll no: ${userData['roll_no'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                          const SizedBox(height: 4),
                          Text(
                            'Address: ${userData['address'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      drawer: Drawer(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center();
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('No data found'));
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;

            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: userData['avatar_url'] != null &&
                                  userData['avatar_url'].isNotEmpty
                              ? CachedNetworkImageProvider(
                                  userData['avatar_url'])
                              : const AssetImage('assets/images/me.jpg')
                                  as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userData['name'] ?? 'Name',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userData['email'] ?? 'email@example.com',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Homework'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeworkPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notice'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NoticePage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Event'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CalendarPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('Teachers'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TeachersProfilesPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Students'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const StudentProfilesPage()));
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Change Password'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Logout'),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const MainScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Carousel Slider
          FutureBuilder<List<String>>(
            future: _fetchImageUrls(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center();
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final imageUrls = snapshot.data ?? imgList;
              return Container(
                margin: const EdgeInsets.only(
                    top: 20), // Gap between app bar and slider
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 200, // Adjust height as needed
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.8,
                  ),
                  items: imageUrls.map((url) {
                    return Builder(
                      builder: (BuildContext context) {
                        return CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit
                              .cover, // Ensure image fits within the carousel
                          width: MediaQuery.of(context).size.width,
                        );
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 20), // Gap between slider and grid
          // GridView
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('home_data')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center();
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.hasData) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 items per row
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1, // Adjust aspect ratio for better fit
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return buildGridItem(
                            context,
                            'Homework',
                            'assets/images/homework.png',
                            const HomeworkPage(),
                          );
                        case 1:
                          return buildGridItem(
                            context,
                            'Notice',
                            'assets/images/notice.png',
                            const NoticePage(),
                          );
                        case 2:
                          return buildGridItem(
                            context,
                            'Events',
                            'assets/images/events.png',
                            const CalendarPage(),
                          );
                        case 3:
                          return buildGridItem(
                            context,
                            'Teachers',
                            'assets/images/teachers.png',
                            const TeachersProfilesPage(),
                          );
                        case 4:
                          return buildGridItem(
                            context,
                            'Students',
                            'assets/images/students.png',
                            const StudentProfilesPage(),
                          );
                        case 5:
                          return buildGridItem(
                            context,
                            'Results',
                            'assets/images/result.png',
                            const ResultsPage(),
                          );
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  );
                }
                return const Center(child: Text('No data available'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGridItem(
      BuildContext context, String title, String assetPath, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(208, 255, 255, 255),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              height: 50,
              width: 45,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
