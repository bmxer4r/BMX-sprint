import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() => runApp(BMXSprintApp());

class BMXSprintApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMX Sprint',
      theme: ThemeData(primarySwatch: Colors.orange, brightness: Brightness.dark),
      home: TimerPage(),
    );
  }
}

class TimerPage extends StatefulWidget {
  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer? _timer;
  int _secondsRemaining = 300; // 5 min warmup
  bool _isWarmup = true;
  int _currentSprint = 0;
  bool _isSprinting = false;
  bool _isActive = false;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(const InitializationSettings(android: androidInit));
  }

  void _vibrateWatch(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'bmx_sprint_01', 'Sprint Training',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    await _notifications.show(0, title, body, const NotificationDetails(android: androidDetails));
  }

  void _toggleTimer() {
    if (_isActive) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
    setState(() => _isActive = !_isActive);
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          // Waarschuwing 3 seconden voor de sprint start
          if (!_isWarmup && !_isSprinting && _secondsRemaining <= 3 && _secondsRemaining > 0) {
            _vibrateWatch("Klaarmaken!", "$_secondsRemaining...");
          }
        } else {
          _managePhases();
        }
      });
    });
  }

  void _managePhases() {
    if (_isWarmup) {
      _isWarmup = false;
      _startNextSprint();
    } else if (_isSprinting) {
      _startRest();
    } else {
      if (_currentSprint < 10) {
        _startNextSprint();
      } else {
        _timer?.cancel();
        _isActive = false;
        _vibrateWatch("Klaar!", "Training voltooid.");
      }
    }
  }

  void _startNextSprint() {
    _isSprinting = true;
    _currentSprint++;
    _secondsRemaining = 10;
    _vibrateWatch("GO GO GO!", "Sprint $_currentSprint start nu!");
  }

  void _startRest() {
    _isSprinting = false;
    _secondsRemaining = 50;
    _vibrateWatch("RUST", "Goed gedaan. Herstel 50 seconden.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: _isSprinting ? Colors.redAccent : (_isWarmup ? Colors.blueGrey : Colors.green),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isWarmup ? "WARMING-UP" : (_isSprinting ? "SPRINT $_currentSprint / 10" : "RUST"),
                style: TextStyle(fontSize: 30, color: Colors.white)),
            Text("${(_secondsRemaining ~/ 60)}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                style: TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 50),
            FloatingActionButton.large(
              onPressed: _toggleTimer,
              backgroundColor: Colors.white,
              child: Icon(_isActive ? Icons.pause : Icons.play_arrow, size: 50, color: Colors.black),
            )
          ],
        ),
      ),
    );
  }
}
