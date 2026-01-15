import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 500),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setResizable(false);
  });

  runApp(const FocusTimerApp());
}

class FocusTimerApp extends StatefulWidget {
  const FocusTimerApp({super.key});

  @override
  State<FocusTimerApp> createState() => _FocusTimerAppState();
}

class _FocusTimerAppState extends State<FocusTimerApp> with WindowListener {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _alwaysOnTop = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  void startTimer() {
    if (!_isRunning) {
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          pauseTimer();
          playNotificationSound();
        }
      });
    }
  }

  void pauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
        _isPaused = true;
      });
    }
  }

  void resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 25 * 60;
      _isRunning = false;
      _isPaused = false;
    });
  }

  void toggleAlwaysOnTop() {
    windowManager.setAlwaysOnTop(!_alwaysOnTop);
    setState(() {
      _alwaysOnTop = !_alwaysOnTop;
    });
  }

  void playNotificationSound() {
  }

  void minimizeWindow() {
    windowManager.minimize();
  }

  void closeWindow() {
    windowManager.close();
  }

  String get timerText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    return _remainingSeconds / (25 * 60);
  }

  Color get timerColor {
    if (_remainingSeconds <= 60 && _isRunning) {
      return Colors.red;
    } else if (_isPaused) {
      return Colors.orange;
    } else if (_isRunning) {
      return Colors.green;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onPanStart: (_) => windowManager.startDragging(),
                              child: const Center(
                                child: Text(
                                  'Focus Timer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.minimize, size: 16),
                            onPressed: minimizeWindow,
                            color: Colors.white70,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: closeWindow,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        timerColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timerText,
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 20,
                              children: [
                                _buildControlButton(
                                  icon: Icons.play_arrow_rounded,
                                  onPressed: startTimer,
                                  color: Colors.green,
                                ),
                                _buildControlButton(
                                  icon: Icons.pause_rounded,
                                  onPressed: pauseTimer,
                                  color: Colors.orange,
                                ),
                                _buildControlButton(
                                  icon: Icons.refresh_rounded,
                                  onPressed: resetTimer,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.push_pin,
                            size: 16,
                            color: _alwaysOnTop ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Always on Top',
                            style: TextStyle(
                              fontSize: 12,
                              color: _alwaysOnTop ? Colors.white : Colors.grey,
                            ),
                          ),
                          Switch(
                            value: _alwaysOnTop,
                            onChanged: (_) => toggleAlwaysOnTop(),
                            activeColor: timerColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 28, color: color),
        onPressed: onPressed,
        iconSize: 32,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
