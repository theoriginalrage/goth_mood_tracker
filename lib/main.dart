import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String> appVersion() async {
  final info = await PackageInfo.fromPlatform();
  return "${info.version}+${info.buildNumber}"; // e.g., 0.2.1+42
}

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
}

/// ---------------------- APP ----------------------

class GothApp extends StatefulWidget {
  const GothApp({super.key});

  @override
  State<GothApp> createState() => _GothAppState();
}

class _GothAppState extends State<GothApp> {
  final store = MoodStore();

  @override
  void initState() {
    super.initState();
    store.load();
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
          home: HomeScreen(store: store),
        );
      },
    );
  }
}

/// ---------------------- THEME ----------------------
/// Avoid `const` inside here so non-const constructors (e.g. BorderRadius.circular)
/// don’t trigger “constant expression expected” errors on older SDKs.
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
  const HomeScreen({super.key, required this.store});

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
              hintText: 'Optional note (e.g., “rain sounded like applause for my mistakes”)',
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

    if (items.isEmpty) {
      return const Center(
        child: Text('No entries yet. Go feel something bleak.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = items[i];
        return Card(
          child: ListTile(
            leading: Text(e.mood.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(e.mood.label),
            subtitle: Text(
              _niceDate(e.at) + (e.note == null ? '' : '\n${e.note}'),
              maxLines: 4,
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
          const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Theme is locked to “eternal darkness.” Obviously.'),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete All Entries?'),
                  content: const Text('The void will reclaim your history. This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Erase')),
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

