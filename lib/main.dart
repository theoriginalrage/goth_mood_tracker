import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // for RenderRepaintBoundary
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GothApp());
}

/// ---------------------- DATA MODELS ----------------------

enum GothMood {
  peterSteeleBassline,   // calm but gloomy
  graveyardShift,        // exhausted
  coffinNap,             // depressed but chill
  ratsInTheWalls,        // angry/paranoid
  eternalNight,          // content in the darkness
  stormInTheVeins,       // anxious/static
}

extension GothMoodX on GothMood {
  String get label {
    switch (this) {
      case GothMood.peterSteeleBassline:
        return 'Peter Steele Bassline';
      case GothMood.graveyardShift:
        return 'Graveyard Shift';
      case GothMood.coffinNap:
        return 'Coffin Nap';
      case GothMood.ratsInTheWalls:
        return 'Rats in the Walls';
      case GothMood.eternalNight:
        return 'Eternal Night';
      case GothMood.stormInTheVeins:
        return 'Storm in the Veins';
    }
  }

  String get emoji {
    switch (this) {
      case GothMood.peterSteeleBassline:
        return '🎸';
      case GothMood.graveyardShift:
        return '🕯️';
      case GothMood.coffinNap:
        return '⚰️';
      case GothMood.ratsInTheWalls:
        return '🐀';
      case GothMood.eternalNight:
        return '🌑';
      case GothMood.stormInTheVeins:
        return '🌩️';
    }
  }
}

class MoodEntry {
  final GothMood mood;
  final DateTime at;
  final String? note;

  MoodEntry({required this.mood, required this.at, this.note});

  Map<String, dynamic> toJson() => {
        'mood': mood.name,
        'at': at.toIso8601String(),
        'note': note,
      };

  static MoodEntry fromJson(Map<String, dynamic> j) => MoodEntry(
        mood: GothMood.values.firstWhere((m) => m.name == (j['mood'] as String)),
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
        note: j['note'] as String?,
      );
}

/// ---------------------- STORAGE ----------------------

class MoodStore extends ChangeNotifier {
  static const _key = 'goth_mood_entries';
  final List<MoodEntry> _entries = [];

  List<MoodEntry> get entries =>
      List.unmodifiable(_entries..sort((a, b) => b.at.compareTo(a.at)));

  MoodEntry? get latest => entries.isEmpty ? null : entries.first;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _entries
      ..clear()
      ..addAll(raw
          .map((s) => jsonDecode(s))
          .whereType<Map<String, dynamic>>()
          .map(MoodEntry.fromJson));
    notifyListeners();
  }

  Future<void> add(GothMood mood, {String? note}) async {
    _entries.add(MoodEntry(mood: mood, at: DateTime.now(), note: note));
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _entries.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, list);
  }

  /// Returns (currentStreak, bestStreak)
  (int, int) computeStreaks() {
    if (_entries.isEmpty) return (0, 0);

    // Unique local dates, newest first
    final dates = _entries
        .map((e) => _asYmd(e.at.toLocal()))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // desc

    // Build a sorted list of DateTime (midnight local) for iteration
    final days = dates.map((s) => DateTime.parse(s)).toList();

    int best = 0;
    int curr = 0;

    // current streak: only continuous from the latest day backwards
    {
      curr = 1;
      for (int i = 1; i < days.length; i++) {
        final prev = days[i - 1];
        final d = days[i];
        if (_isPrevDay(prev, d)) {
          curr++;
        } else {
          break;
        }
      }
    }

    // best streak: scan all runs
    {
      int run = 1;
      for (int i = 1; i < days.length; i++) {
        final prev = days[i - 1];
        final d = days[i];
        if (_isPrevDay(prev, d)) {
          run++;
        } else {
          if (run > best) best = run;
          run = 1;
        }
      }
      if (run > best) best = run;
    }

    return (curr, best);
  }

  // Normalize to yyyy-mm-dd (local)
  String _asYmd(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }

  // true if d is exactly one day before prev
  bool _isPrevDay(DateTime prev, DateTime d) {
    final prevMinusOne = DateTime(prev.year, prev.month, prev.day)
        .subtract(const Duration(days: 1));
    final dd = DateTime(d.year, d.month, d.day);
    return dd.year == prevMinusOne.year &&
        dd.month == prevMinusOne.month &&
        dd.day == prevMinusOne.day;
  }
}

/// ---------------------- APP ----------------------

class GothApp extends StatefulWidget {
  const GothApp({super.key});

  @override
  State<GothApp> createState() => _GothAppState();
}

class _GothAppState extends State<GothApp> {
  final store = MoodStore();

  // key to capture the whole screen content
  final GlobalKey repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    store.load();
  }

  Future<void> _shareScreenshot() async {
    try {
      final ctx = repaintKey.currentContext;
      if (ctx == null) return;
      final boundary =
          ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final latest = store.latest;
      final caption = latest == null
          ? 'Goth Mood Tracker'
          : 'Goth Mood: ${latest.mood.emoji} ${latest.mood.label}'
            '${latest.note == null ? '' : '\nNote: ${latest.note}'}';

      await Share.shareXFiles(
        [
          XFile.fromData(
            pngBytes,
            name: 'goth_mood_${DateTime.now().millisecondsSinceEpoch}.png',
            mimeType: 'image/png',
          ),
        ],
        text: caption,
        subject: 'Goth Mood',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sharing failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Goth Mood',
          theme: _darkTheme,
          home: RepaintBoundary( // everything inside becomes the screenshot
            key: repaintKey,
            child: HomeScreen(
              store: store,
              onShare: _shareScreenshot,
            ),
          ),
        );
      },
    );
  }
}

/// ---------------------- THEME ----------------------

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0E0D12), // near-black
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF8A1638), // wine/blood
    secondary: Color(0xFF5C1E5E), // deep purple
    surface: Color(0xFF14131A),
  ),
  textTheme: TextTheme(
    headlineMedium: const TextStyle(fontWeight: FontWeight.w700),
    bodyMedium: const TextStyle(color: Color(0xFFE6E6E6)),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF16141C),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1B1922),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2A2731)),
    ),
  ),
);

/// ---------------------- SCREENS ----------------------

class HomeScreen extends StatefulWidget {
  final MoodStore store;
  final VoidCallback onShare;
  const HomeScreen({super.key, required this.store, required this.onShare});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _LogMoodTab(store: widget.store),
      _HistoryTab(store: widget.store),
      _SettingsTab(store: widget.store),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goth Mood Tracker'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Share screenshot',
            onPressed: widget.onShare,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: tabs[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bloodtype), label: 'Log'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _LogMoodTab extends StatefulWidget {
  final MoodStore store;
  const _LogMoodTab({required this.store});

  @override
  State<_LogMoodTab> createState() => _LogMoodTabState();
}

class _LogMoodTabState extends State<_LogMoodTab> {
  final noteCtrl = TextEditingController();

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moods = GothMood.values;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Text(
            'How bleak are we today?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final m in moods)
                _MoodButton(
                  mood: m,
                  onTap: () async {
                    final note = noteCtrl.text.trim();
                    await widget.store.add(m, note: note.isEmpty ? null : note);
                    if (mounted) {
                      _snarkToast(context, m);
                      noteCtrl.clear();
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText:
                  'Optional note (e.g., “rain sounded like applause for my mistakes”)',
            ),
          ),
        ],
      ),
    );
  }

  void _snarkToast(BuildContext context, GothMood mood) {
    final lines = [
      'Another day, another beautiful abyss.',
      'Misery loves company. You brought snacks.',
      'Congrats — you logged feelings *again*. Punk.',
      'The void is proud of you. In its own way.',
      'Vitamin D called. You sent it to voicemail.',
    ];
    final msg =
        '${mood.emoji} ${mood.label} — ${lines[DateTime.now().second % lines.length]}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final MoodStore store;
  const _HistoryTab({required this.store});

  @override
  Widget build(BuildContext context) {
    final items = store.entries;
    final (curr, best) = store.computeStreaks();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: (items.isEmpty ? 1 : items.length + 1),
      itemBuilder: (_, i) {
        // First item: streak header card
        if (i == 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.whatshot), // subtle, matches theme
                  const SizedBox(width: 10),
                  Text(
                    'Streak: $curr day${curr == 1 ? '' : 's'} • Best: $best',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }

        // No entries? show the empty message after the streak card
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(child: Text('No entries yet. Go feel something bleak.')),
          );
        }

        final e = items[i - 1];
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Card(
            child: ListTile(
              leading: Text(e.mood.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(e.mood.label),
              subtitle: Text(
                _niceDate(e.at) + (e.note == null ? '' : '\n${e.note}'),
                maxLines: 4,
              ),
            ),
          ),
        );
      },
    );
  }

  String _niceDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _SettingsTab extends StatelessWidget {
  final MoodStore store;
  const _SettingsTab({required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Theme is locked to “eternal darkness.” Obviously.'),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete All Entries?'),
                  content: const Text(
                      'The void will reclaim your history. This cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Erase')),
                  ],
                ),
              );
              if (ok == true) {
                await store.clearAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emptied into the abyss.')),
                  );
                }
              }
            },
            child: const Text('Erase All Data'),
          ),
          const SizedBox(height: 12),
          const Text('v0.1.0 — “First Coffin”'),
        ],
      ),
    );
  }
}

/// ---------------------- UI BITS ----------------------

class _MoodButton extends StatelessWidget {
  final GothMood mood;
  final VoidCallback onTap;
  const _MoodButton({required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 170,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1821),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2731)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                mood.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

