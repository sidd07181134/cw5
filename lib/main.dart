import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> with TickerProviderStateMixin {
  List<Fish> fishList = [];
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initDatabase().then((_) => _loadSettings());
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'aquarium.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE settings(id INTEGER PRIMARY KEY, fishCount INTEGER, speed REAL, color INTEGER)",
        );
      },
      version: 1,
    );
  }

  Future<void> _saveSettings() async {
    if (_database != null) {
      await _database!.insert(
        'settings',
        {
          'id': 1,
          'fishCount': fishList.length,
          'speed': selectedSpeed,
          'color': selectedColor.value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _loadSettings() async {
    if (_database != null) {
      final List<Map<String, dynamic>> settings = await _database!.query('settings', where: "id = 1");
      if (settings.isNotEmpty) {
        setState(() {
          int count = settings[0]['fishCount'];
          selectedSpeed = settings[0]['speed'];
          selectedColor = Color(settings[0]['color']);
          fishList = List.generate(count, (index) => Fish(color: selectedColor, speed: selectedSpeed, vsync: this));
        });
      }
    }
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed, vsync: this));
      });
    }
  }

  void _clearAquarium() {
    setState(() {
      fishList.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Virtual Aquarium')),
      body: Column(
        children: [
          Container(
            height: 300,
            width: 300,
            decoration: BoxDecoration(
              color: Colors.lightBlue[50], // Light background to represent water
              border: Border.all(
                color: Colors.blue, // Blue border to make the container visible
                width: 2,
              ),
            ),
            child: Stack(
              children: fishList.map((fish) => fish.buildWidget()).toList(),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _addFish, child: Text('Add Fish')),
              SizedBox(width: 10),
              ElevatedButton(onPressed: _saveSettings, child: Text('Save Settings')),
              SizedBox(width: 10),
              ElevatedButton(onPressed: _clearAquarium, child: Text('Clear Aquarium')),
            ],
          ),
          Slider(
            min: 0.5,
            max: 5.0,
            value: selectedSpeed,
            label: 'Speed: ${selectedSpeed.toStringAsFixed(1)}',
            onChanged: (value) {
              setState(() {
                selectedSpeed = value;
              });
            },
          ),
          DropdownButton<Color>(
            value: selectedColor,
            items: [
              DropdownMenuItem(child: Text('Blue'), value: Colors.blue),
              DropdownMenuItem(child: Text('Red'), value: Colors.red),
              DropdownMenuItem(child: Text('Green'), value: Colors.green),
            ],
            onChanged: (value) {
              setState(() {
                selectedColor = value ?? Colors.blue;
              });
            },
          ),
        ],
      ),
    );
  }
}

class Fish {
  final Color color;
  final double speed;
  double xPosition = Random().nextDouble() * 250;
  double yPosition = Random().nextDouble() * 250;
  double xDirection = Random().nextBool() ? 1.0 : -1.0;
  double yDirection = Random().nextBool() ? 1.0 : -1.0;
  late AnimationController _controller;

  Fish({required this.color, required this.speed, required TickerProvider vsync}) {
    _controller = AnimationController(
      duration: Duration(milliseconds: (1000 / speed).toInt()),
      vsync: vsync,
    )..addListener(() {
        _moveFish();
      })..repeat();
  }

  Widget buildWidget() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: xPosition,
          top: yPosition,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  void _moveFish() {
    xPosition += xDirection * speed;
    yPosition += yDirection * speed;

    // Ensure the fish bounces off the edges of the container
    if (xPosition <= 0 || xPosition >= 280) {
      xDirection *= -1;
    }

    if (yPosition <= 0 || yPosition >= 280) {
      yDirection *= -1;
    }
  }
}
