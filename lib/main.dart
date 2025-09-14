import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'ads_service.dart';
import 'history_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await AdsService.init();
  runApp(const GothMoodApp());
}

Future<String> appVersion() async {
  final info = await PackageInfo.fromPlatform();
  return "${info.version}+${info.buildNumber}";
}

class GothMoodApp extends StatelessWidget {
  const GothMoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'Goth Mood Tracker',
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: const Color(0xFF6E2D7B),
          secondary: const Color(0xFF6E2D7B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        textTheme: base.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const _RootNav(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _RootNav extends StatefulWidget {
  const _RootNav({super.key});
  @override
  State<_RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<_RootNav> {
  int _idx = 0;
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const LogScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_idx]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bloodtype_outlined), selectedIcon: Icon(Icons.bloodtype), label: 'Log'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// --------------------------- LOG SCREEN ---------------------------

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});
  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _note = TextEditingController();
  final _moods = const [
    ('🎸', 'Peter Steele Bassline'),
    ('🕯️', 'Graveyard Shift'),
    ('⚰️', 'Coffin Nap'),
    ('🐀', 'Rats in the Walls'),
    ('🌑', 'Eternal Night'),
    ('⛈️', 'Storm in the Veins'),
  ];

  Future<void> _save(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc().toIso8601String();
    final list = prefs.getStringList('entries') ?? <String>[];
    final note = _note.text.trim();
    final entry = jsonEncode({'ts': now, 'mood': mood, 'note': note.isEmpty ? null : note});
    list.insert(0, entry);
    await prefs.setStringList('entries', list);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Your darkness has been noted: $mood'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () => _shareLatest(entry),
        ),
      ),
    );
    _note.clear();

    // Gate interstitial every 3 saves
    await AdsService.onSave();
  }

  Future<void> _shareLatest(String rawEntry) async {
    // Simple share text; you can upgrade to an image card later
    final e = jsonDecode(rawEntry) as Map<String, dynamic>;
    final ts = DateTime.parse(e['ts'] as String).toLocal();
    final when =
        '${ts.year.toString().padLeft(4, '0')}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} '
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    final text = 'How bleak? ${e['mood']} — $when\n#GothMoodTracker';
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/goth_mood.txt')..writeAsStringSync(text);
    await Share.shareXFiles([XFile(f.path)], text: 'Goth Mood');
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Goth Mood Tracker', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('How bleak are we today?', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: _moods.map((m) {
              return SizedBox(
                width: (w - 32 - 12) / 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _save(m.$2),
                  child: Column(children: [
                    Text(m.$1, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 6),
                    Text(m.$2, textAlign: TextAlign.center),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _note,
            maxLength: 140,
            decoration: const InputDecoration(
              hintText: 'Optional note (e.g., “rain sounded like applause for my mistakes”)',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------- HISTORY SCREEN -------------------------

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('entries') ?? <String>[];
    setState(() {
      _entries = list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    });
  }

  Set<DateTime> _uniqueDays() {
    return _entries.map((e) {
      final ts = DateTime.tryParse(e['ts'] as String? ?? '')?.toUtc();
      if (ts == null) return null;
      return DateTime.utc(ts.year, ts.month, ts.day);
    }).whereType<DateTime>().toSet();
  }

  int _currentStreak(Set<DateTime> days) {
    if (days.isEmpty) return 0;
    var d = DateTime.now().toUtc();
    d = DateTime.utc(d.year, d.month, d.day);
    var s = 0;
    while (days.contains(d)) { s++; d = d.subtract(const Duration(days: 1)); }
    return s;
  }

  int _longestStreak(Set<DateTime> days) {
    if (days.isEmpty) return 0;
    var best = 0;
    for (final start in days) {
      if (days.contains(start.subtract(const Duration(days: 1)))) continue;
      var len = 0; var d = start;
      while (days.contains(d)) { len++; d = d.add(const Duration(days: 1)); }
      if (len > best) best = len;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _uniqueDays();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              _Chip(text: '🔥 Current: ${_currentStreak(days)}'),
              const SizedBox(width: 8),
              _Chip(text: '🏆 Longest: ${_longestStreak(days)}'),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final e = _entries[i];
                final ts = DateTime.tryParse(e['ts'] as String? ?? '')?.toLocal();
                final note = (e['note'] as String?)?.trim();
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1F),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e['mood'] ?? '', style: theme.textTheme.titleMedium),
                      if (ts != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${ts.year.toString().padLeft(4, '0')}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} '
                            '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ),
                      if (note != null && note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(note, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const HistoryBanner(), // ✅ banner at the bottom
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2330),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text),
    );
  }
}

// ------------------------- SETTINGS SCREEN ------------------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _eraseAll() async {
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('entries');
    setState(() => _busy = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data erased. The void is appeased.')),
      );
    }
  }

  Future<void> _exportJson() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('entries') ?? <String>[];
    final jsonStr = const JsonEncoder.withIndent('  ')
        .convert(list.map((s) => jsonDecode(s)).toList());

    final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
    final file = File('${dir.path}/goth_mood_export.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: "Goth Mood export");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to ${file.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Goth Mood Tracker', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text('Theme is locked to “eternal darkness.” Obviously.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _eraseAll,
            child: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Erase All Data'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _exportJson, child: const Text('Export JSON')),
          const Spacer(),
          FutureBuilder<String>(
            future: appVersion(),
            builder: (context, snap) {
              final v = snap.data ?? '…';
              return Text('v$v — “First Coffin”', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70));
            },
          ),
        ],
      ),
    );
  }
}

