import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<String>> _events = {};
  bool _isLoading = true;
  String? _userRole;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _userRole = userDoc['role'] as String?;
            _fetchEvents(); // Fetch events after getting the role
          });
        } else {
          throw Exception('User document does not exist');
        }
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      print('Error fetching user role: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEvents() async {
    try {
      QuerySnapshot eventDocs = await _firestore.collection('events').get();
      Map<DateTime, List<String>> eventsMap = {};

      for (var doc in eventDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        DateTime eventDate = (data['date'] as Timestamp).toDate();
        String eventDescription = data['description'] ?? 'No Description';

        if (!eventsMap.containsKey(eventDate)) {
          eventsMap[eventDate] = [];
        }
        eventsMap[eventDate]!.add(eventDescription);
      }

      setState(() {
        _events = eventsMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addEvent() async {
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Event Description'),
              ),
              const SizedBox(height: 16.0),
              Text(
                  'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
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
                if (descriptionController.text.isNotEmpty) {
                  try {
                    await _firestore.collection('events').add({
                      'date': Timestamp.fromDate(_selectedDate),
                      'description': descriptionController.text,
                    });

                    Navigator.of(context).pop();
                    _fetchEvents(); // Refresh the event list
                  } catch (e) {
                    print('Error adding event: $e');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter an event description')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          if (_userRole == 'teacher') // Show only for teachers
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addEvent,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _selectedDate,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
                    });
                  },
                  eventLoader: (day) {
                    return _events[day] ?? [];
                  },
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final hasEvents = _events.containsKey(day);
                      final textStyle = hasEvents
                          ? const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)
                          : const TextStyle(color: Colors.black);
                      final containerDecoration = BoxDecoration(
                        color: hasEvents
                            ? Colors.red.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6.0),
                      );

                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: containerDecoration,
                        alignment: Alignment.center,
                        child: Text(
                          day.day.toString(),
                          style: textStyle,
                        ),
                      );
                    },
                    markerBuilder: (context, day, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            width: 6.0,
                            height: 6.0,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: _events.entries
                        .where((entry) =>
                            entry.key.month == _selectedDate.month &&
                            entry.key.year == _selectedDate.year)
                        .map((entry) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('MMMM d, yyyy').format(entry.key),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                ...entry.value.map((event) => ListTile(
                                      title: Text(event),
                                    )),
                                const Divider(),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
