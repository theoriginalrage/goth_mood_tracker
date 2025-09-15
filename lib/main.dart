import 'package:flutter/material.dart';
import 'share_service.dart'; // make sure this exists

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goth Mood Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MoodPage(),
    );
  }
}

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  final TextEditingController _moodController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? savedMood;
  String? savedNote;

  void _saveMood() {
    setState(() {
      savedMood = _moodController.text;
      savedNote = _noteController.text;
    });
    _moodController.clear();
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goth Mood Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _moodController,
              decoration: const InputDecoration(labelText: 'Mood'),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveMood,
              child: const Text('Save'),
            ),
            const SizedBox(height: 16),
            if (savedMood != null && savedNote != null)
              Shareable(
                child: Card(
                  child: ListTile(
                    title: Text('Mood: $savedMood'),
                    subtitle: Text('Note: $savedNote'),
                  ),
                ),
              ),
            if (savedMood != null && savedNote != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.ios_share),
                    onPressed: () =>
                        shareGeneric(text: 'My Goth Mood streak 👇'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Share to Instagram Stories',
                    icon: const Icon(Icons.camera_alt_outlined),
                    onPressed: () => shareToInstagramStories(
                      attributionUrl: 'https://pixelpanic.shop',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

