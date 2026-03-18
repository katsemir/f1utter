import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesManager.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final prefs = PreferencesManager.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: prefs,
      builder: (_, __) {
        return MaterialApp(
          themeMode: prefs.themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const HomeScreen(),
        );
      },
    );
  }
}

class PreferencesManager extends ChangeNotifier {
  static PreferencesManager? _instance;
  static SharedPreferences? _prefs;

  static PreferencesManager get instance => _instance!;

  PreferencesManager._();

  static Future<PreferencesManager> getInstance() async {
    if (_instance == null) {
      _instance = PreferencesManager._();
      _prefs = await SharedPreferences.getInstance();
      _instance!._load();
    }
    return _instance!;
  }

  String name = '';
  String email = '';
  int age = 18;
  String registerDate = '';

  ThemeMode themeMode = ThemeMode.system;
  double fontSize = 16;
  String language = 'en';
  bool compact = false;

  bool push = true;
  bool emailNotif = true;
  bool sound = true;
  int reminder = 5;

  List<String> categories = [];

  void _load() {
    try {
      name = _prefs?.getString('name') ?? '';
      email = _prefs?.getString('email') ?? '';
      age = _prefs?.getInt('age') ?? 18;
      registerDate = _prefs?.getString('date') ?? '';

      themeMode = ThemeMode.values[_prefs?.getInt('theme') ?? 0];
      fontSize = _prefs?.getDouble('font') ?? 16;
      language = _prefs?.getString('lang') ?? 'en';
      compact = _prefs?.getBool('compact') ?? false;

      push = _prefs?.getBool('push') ?? true;
      emailNotif = _prefs?.getBool('emailNotif') ?? true;
      sound = _prefs?.getBool('sound') ?? true;
      reminder = _prefs?.getInt('reminder') ?? 5;

      categories = _prefs?.getStringList('categories') ?? [];
    } catch (e) {
      debugPrint("Load error: $e");
    }
  }

  Future<void> save() async {
    try {
      await _prefs?.setString('name', name);
      await _prefs?.setString('email', email);
      await _prefs?.setInt('age', age);
      await _prefs?.setString('date', registerDate);

      await _prefs?.setInt('theme', themeMode.index);
      await _prefs?.setDouble('font', fontSize);
      await _prefs?.setString('lang', language);
      await _prefs?.setBool('compact', compact);

      await _prefs?.setBool('push', push);
      await _prefs?.setBool('emailNotif', emailNotif);
      await _prefs?.setBool('sound', sound);
      await _prefs?.setInt('reminder', reminder);

      await _prefs?.setStringList('categories', categories);

      notifyListeners();
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  Future<void> reset() async {
    try {
      await _prefs?.clear();
      _load();
      notifyListeners();
    } catch (e) {
      debugPrint("Reset error: $e");
    }
  }

  String exportJson() {
    final data = {
      "name": name,
      "email": email,
      "age": age,
      "date": registerDate,
      "theme": themeMode.toString(),
      "font": fontSize,
      "language": language,
      "compact": compact,
      "push": push,
      "emailNotif": emailNotif,
      "sound": sound,
      "reminder": reminder,
      "categories": categories,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final prefs = PreferencesManager.instance;
  final categoryController = TextEditingController();

  void saveWithSnack() async {
    await prefs.save();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preferences Manager"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await prefs.reset();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              final json = prefs.exportJson();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Export JSON"),
                  content: SingleChildScrollView(child: Text(json)),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: prefs,
        builder: (_, __) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              const Text("Profile", style: TextStyle(fontSize: 20)),
              TextField(
                decoration: const InputDecoration(labelText: "Name"),
                controller: TextEditingController(text: prefs.name),
                onChanged: (v) {
                  prefs.name = v;
                  saveWithSnack();
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Email"),
                controller: TextEditingController(text: prefs.email),
                onChanged: (v) {
                  prefs.email = v;
                  saveWithSnack();
                },
              ),

              Row(
                children: [
                  const Text("Age: "),
                  Expanded(
                    child: Slider(
                      min: 12,
                      max: 80,
                      value: prefs.age.toDouble(),
                      onChanged: (v) {
                        prefs.age = v.toInt();
                        saveWithSnack();
                      },
                    ),
                  ),
                  Text("${prefs.age}")
                ],
              ),

              const Divider(),

              const Text("Theme"),
              DropdownButton<ThemeMode>(
                value: prefs.themeMode,
                items: ThemeMode.values.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e.toString()),
                  );
                }).toList(),
                onChanged: (v) {
                  prefs.themeMode = v!;
                  saveWithSnack();
                },
              ),

              const Text("Font Size"),
              Slider(
                min: 12,
                max: 24,
                value: prefs.fontSize,
                onChanged: (v) {
                  prefs.fontSize = v;
                  saveWithSnack();
                },
              ),

              DropdownButton<String>(
                value: prefs.language,
                items: ['en', 'ua', 'nl']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  prefs.language = v!;
                  saveWithSnack();
                },
              ),

              SwitchListTile(
                title: const Text("Compact mode"),
                value: prefs.compact,
                onChanged: (v) {
                  prefs.compact = v;
                  saveWithSnack();
                },
              ),

              const Divider(),

              const Text("Notifications"),
              SwitchListTile(
                title: const Text("Push"),
                value: prefs.push,
                onChanged: (v) {
                  prefs.push = v;
                  saveWithSnack();
                },
              ),
              SwitchListTile(
                title: const Text("Email"),
                value: prefs.emailNotif,
                onChanged: (v) {
                  prefs.emailNotif = v;
                  saveWithSnack();
                },
              ),
              SwitchListTile(
                title: const Text("Sound"),
                value: prefs.sound,
                onChanged: (v) {
                  prefs.sound = v;
                  saveWithSnack();
                },
              ),

              Row(
                children: [
                  const Text("Reminder: "),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: 60,
                      value: prefs.reminder.toDouble(),
                      onChanged: (v) {
                        prefs.reminder = v.toInt();
                        saveWithSnack();
                      },
                    ),
                  ),
                  Text("${prefs.reminder}")
                ],
              ),

              const Divider(),

              const Text("Categories"),
              Wrap(
                spacing: 8,
                children: prefs.categories
                    .map((e) => Chip(
                  label: Text(e),
                  onDeleted: () {
                    prefs.categories.remove(e);
                    saveWithSnack();
                  },
                ))
                    .toList(),
              ),

              TextField(
                controller: categoryController,
                decoration:
                const InputDecoration(labelText: "Add category"),
                onSubmitted: (v) {
                  prefs.categories.add(v);
                  categoryController.clear();
                  saveWithSnack();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}