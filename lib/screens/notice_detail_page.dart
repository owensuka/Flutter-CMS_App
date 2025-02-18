import 'package:flutter/material.dart';

class NoticeDetailPage extends StatelessWidget {
  final Map<String, dynamic> notice;

  const NoticeDetailPage({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(notice['title'] ?? 'Notice Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notice['image_url'] != null)
              Image.network(
                notice['image_url'],
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red);
                },
              ),
            const SizedBox(height: 16.0),
            Text(
              'Title: ${notice['title'] ?? 'No Title'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Description: ${notice['description'] ?? 'No Description'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
