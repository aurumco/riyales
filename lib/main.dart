import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black, // Changed to black
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.varelaRound(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const StatsScreen(),
    const TimerScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_getAppBarTitle()),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_square),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.timer),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Fitness';
      case 1:
        return 'Stats';
      case 2:
        return 'Timer';
      case 3:
        return 'Settings';
      default:
        return 'Fitness';
    }
  }
}

// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late SharedPreferences _prefs;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalCaloriesBurned = 0;
  int _totalWorkoutMinutes = 0;
  List<Map<String, dynamic>> _todayActivities = [];

  // ** Customizable Settings **
  final double _addButtonIconSize = 22; // Size of the add button icon
  final double _currentStreakIconSize = 32; // Size of the current streak icon
  final double _cardBorderRadius = 20; // Border radius of the cards
  final double _cardTitleFontSize = 18; // Font size for card titles
  final double _cardTextFontSize = 16; // Font size for card text
  final double _cardContentSpacing = 5; // Spacing between title and content in cards
  final double _cardIconPadding = 5; // Padding for the icon in cards
  final List<Color> _weekGradientColors = [
    const Color.fromARGB(255, 15, 238, 138),
    const Color.fromARGB(255, 98, 220, 201)
  ]; // Gradient colors for week card
  final List<Color> _monthGradientColors = [
    const Color.fromARGB(255, 255, 66, 79),
    const Color.fromARGB(255, 255, 112, 150)
  ]; // Gradient colors for month card
  final AlignmentGeometry _gradientBegin = Alignment.topLeft; // Gradient begin alignment
  final AlignmentGeometry _gradientEnd = Alignment.bottomRight; // Gradient end alignment

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentStreak = _prefs.getInt('currentStreak') ?? 0;
      _bestStreak = _prefs.getInt('bestStreak') ?? 0;
      _totalCaloriesBurned = _prefs.getInt('totalCaloriesBurned') ?? 0;
      _totalWorkoutMinutes = _prefs.getInt('totalWorkoutMinutes') ?? 0;
      _todayActivities =
          _getTodayActivities(_prefs.getStringList('workoutHistory') ?? []);
    });
  }

  List<Map<String, dynamic>> _getTodayActivities(List<String> history) {
    List<Map<String, dynamic>> activities = [];
    final today = DateTime.now();
    final formattedToday = DateFormat('yyyy-MM-dd').format(today);
    for (final workout in history) {
      final parts = workout.split(' | ');
      if (parts.length == 4 && parts[1] == formattedToday) {
        activities.add({
          'name': parts[0],
          'duration': int.tryParse(parts[2].split(' ')[0]) ?? 0,
          'calories': int.tryParse(parts[3].split(' ')[0]) ?? 0,
          'icon': _getWorkoutIcon(parts[0]),
        });
      }
    }
    return activities;
  }

  IconData _getWorkoutIcon(String workoutName) {
    switch (workoutName) {
      case 'Running':
        return CupertinoIcons.bolt_horizontal_circle_fill;
      case 'Yoga':
        return CupertinoIcons.person_2_fill;
      case 'Cycling':
        return CupertinoIcons.speedometer;
      case 'Strength':
        return CupertinoIcons.square_stack_3d_up_fill;
      case 'Walking':
        return CupertinoIcons.person_2_fill;
      case 'Swimming':
        return CupertinoIcons.drop_fill;
      case 'Boxing':
        return CupertinoIcons.hand_raised_fill;
      case 'Hiking':
        return CupertinoIcons.tree;
      case 'Pilates':
        return CupertinoIcons.person_fill;
      case 'Dance':
        return CupertinoIcons.music_note_2;
      case 'Aerobics':
        return CupertinoIcons.heart_fill;
      case 'Weights':
        return CupertinoIcons.hammer_fill;
      default:
        return CupertinoIcons.question;
    }
  }

  void _showAddWorkoutBottomSheet() {
    Map<String, dynamic> selectedWorkout = {};
    int duration = 0;
    int calories = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Workout',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _buildWorkoutOption(
                          setModalState,
                          'Running',
                          CupertinoIcons.bolt_horizontal_circle_fill,
                          const [Color(0xFF4e54c8), Color(0xFF8f94fb)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Yoga',
                          CupertinoIcons.person_2_fill,
                          const [Color(0xFFf64f59), Color(0xFFc471ed)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Cycling',
                          CupertinoIcons.speedometer,
                          const [Color(0xFF00b09b), Color(0xFF96c93d)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Strength',
                          CupertinoIcons.square_stack_3d_up_fill,
                          const [Color(0xFFfe8c00), Color(0xFFf83600)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Walking',
                          CupertinoIcons.person_2_fill,
                          const [Color(0xFF544a7d), Color(0xFFffd452)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Swimming',
                          CupertinoIcons.drop_fill,
                          const [Color(0xFF43cea2), Color(0xFF185a9d)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Boxing',
                          CupertinoIcons.hand_raised_fill,
                          const [Color(0xFFee0979), Color(0xFFff6a00)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Hiking',
                          CupertinoIcons.tree,
                          const [Color(0xFF4cb8c4), Color(0xFF3cd3ad)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Pilates',
                          CupertinoIcons.person_fill,
                          const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Dance',
                          CupertinoIcons.music_note_2,
                          const [Color(0xFFf79d00), Color(0xFF64f38c)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Aerobics',
                          CupertinoIcons.heart_fill,
                          const [Color(0xFFff4e50), Color(0xFFf9d423)],
                          selectedWorkout,
                        ),
                        _buildWorkoutOption(
                          setModalState,
                          'Weights',
                          CupertinoIcons.hammer_fill,
                          const [Color(0xFF005AA7), Color(0xFFFFFDE4)],
                          selectedWorkout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => duration = int.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Calories Burned',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => calories = int.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (selectedWorkout.isNotEmpty) {
                            _addWorkout(
                                selectedWorkout['name'], duration, calories);
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        child: const Text('Add',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkoutOption(
    StateSetter setModalState,
    String name,
    IconData icon,
    List<Color> gradientColors,
    Map<String, dynamic> selectedWorkout,
  ) {
    return GestureDetector(
      onTap: () {
        setModalState(() {
          selectedWorkout.clear();
          selectedWorkout['name'] = name;
          selectedWorkout['icon'] = icon;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selectedWorkout['name'] == name
                ? gradientColors
                : [const Color(0xFF222222), const Color(0xFF222222)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 8),
            Text(name),
          ],
        ),
      ),
    );
  }

  void _addWorkout(String name, int duration, int calories) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<String> workoutHistory = _prefs.getStringList('workoutHistory') ?? [];
    workoutHistory.add('$name | $formattedDate | $duration min | $calories kcal');
    _prefs.setStringList('workoutHistory', workoutHistory);

    setState(() {
      _todayActivities = _getTodayActivities(workoutHistory);
      _totalCaloriesBurned += calories;
      _totalWorkoutMinutes += duration;
      _prefs.setInt('totalCaloriesBurned', _totalCaloriesBurned);
      _prefs.setInt('totalWorkoutMinutes', _totalWorkoutMinutes);
    });
  }

  void _removeWorkout(int index) {
    final removedActivity = _todayActivities.removeAt(index);
    List<String> workoutHistory = _prefs.getStringList('workoutHistory') ?? [];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Find and remove the workout from history
    for (int i = 0; i < workoutHistory.length; i++) {
      final parts = workoutHistory[i].split(' | ');
      if (parts.length == 4 &&
          parts[0] == removedActivity['name'] &&
          parts[1] == today &&
          parts[2] == '${removedActivity['duration']} min' &&
          parts[3] == '${removedActivity['calories']} kcal') {
        workoutHistory.removeAt(i);
        break;
      }
    }

    _prefs.setStringList('workoutHistory', workoutHistory);

    setState(() {
      _totalCaloriesBurned -= (removedActivity['calories'] as int);
      _totalWorkoutMinutes -= (removedActivity['duration'] as int);
      _prefs.setInt('totalCaloriesBurned', _totalCaloriesBurned);
      _prefs.setInt('totalWorkoutMinutes', _totalWorkoutMinutes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Logo
                // Replace with your app logo
                // Image.asset('assets/images/app_logo.png', height: 40),
                const SizedBox(height: 20),

                // Streak Card
                _buildGradientCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Streak',
                              style: TextStyle(
                                fontSize: _cardTitleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: _cardContentSpacing),
                            Text(
                              '$_currentStreak Days',
                              style: TextStyle(fontSize: _cardTextFontSize),
                            ),
                            SizedBox(height: _cardContentSpacing),
                            Text(
                              'Best Streak: $_bestStreak Days',
                              style: TextStyle(fontSize: _cardTextFontSize),
                            ),
                          ],
                        ),
                      ),
                      // Replace with a suitable icon
                      Padding(
                        padding: EdgeInsets.only(top: _cardIconPadding), // Add top padding to the icon
                        child: Icon(CupertinoIcons.flame_fill,
                            size: _currentStreakIconSize, color: Colors.white),
                      ),
                    ],
                  ),
                  gradient: const LinearGradient(
                    colors: [Color.fromARGB(255, 99, 81, 255), Color.fromARGB(255, 120, 140, 255)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                const SizedBox(height: 20),

                // This Week Summary Card
                _buildGradientCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This Week Summary',
                              style: TextStyle(
                                fontSize: _cardTitleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: _cardContentSpacing),
                            Text(
                              'Calories Burned: ${_calculateWeeklyCalories()} kcal',
                              style: TextStyle(fontSize: _cardTextFontSize),
                            ),
                            SizedBox(height: _cardContentSpacing),
                            Text(
                              'Workout Time: ${formatWorkoutTime(_calculateWeeklyMinutes())}',
                              style: TextStyle(fontSize: _cardTextFontSize),
                            ),
                          ],
                        ),
                      ),
                      // Replace with a suitable icon
                      Padding(
                        padding: EdgeInsets.only(top: _cardIconPadding), // Add top padding to the icon
                        child: Icon(CupertinoIcons.circle_grid_hex_fill,
                            size: _currentStreakIconSize, color: Colors.white),
                      ),
                    ],
                  ),
                  gradient: LinearGradient(
                    colors: _weekGradientColors,
                    begin: _gradientBegin,
                    end: _gradientEnd,
                  ),
                ),
                const SizedBox(height: 20),

                // Monthly Summary Card
                _buildGradientCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This Month Summary',
                              style: TextStyle(
                                fontSize: _cardTitleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: _cardContentSpacing),
                            Text(
                              'Calories Burned: $_totalCaloriesBurned kcal',
                              style: TextStyle(fontSize: _cardTextFontSize),
                            ),
                            SizedBox(height: _cardContentSpacing),
                            Text(
                              'Workout Time: ${formatWorkoutTime(_totalWorkoutMinutes)}',
                              style: TextStyle(fontSize: _cardTextFontSize),
                            ),
                          ],
                        ),
                      ),
                      // Replace with a suitable icon
                      Padding(
                        padding: EdgeInsets.only(top: _cardIconPadding), // Add top padding to the icon
                        child: Icon(CupertinoIcons.rocket_fill,
                            size: _currentStreakIconSize, color: Colors.white),
                      ),
                    ],
                  ),
                  gradient: LinearGradient(
                    colors: _monthGradientColors,
                    begin: _gradientBegin,
                    end: _gradientEnd,
                  ),
                ),
                const SizedBox(height: 20),

                // Today's Activity
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        " Today's Activity",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: _showAddWorkoutBottomSheet,
                        child: Icon(CupertinoIcons.add, size: _addButtonIconSize),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActivityList(),
              ],
            ),
          ),
          // Positioned(
          //   bottom: _addButtonBottomPadding,
          //   right: 20,
          //   child: FloatingActionButton(
          //     onPressed: _showAddWorkoutBottomSheet,
          //     backgroundColor: Colors.white,
          //     child: Icon(Icons.add,
          //         color: Colors.black, size: _addButtonIconSize),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildGradientCard(
      {required Widget child, required LinearGradient gradient}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: child,
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _todayActivities.length,
      itemBuilder: (context, index) {
        final activity = _todayActivities[index];
        return GestureDetector(
          onLongPress: () {
            _removeWorkout(index);
          },
          child: Card(
            color: const Color(0xFF222222),
            child: ListTile(
              leading: Icon(activity['icon'], size: 30),
              title: Text(activity['name']),
              subtitle: Text('${activity['duration']} min'),
              trailing: Text('${activity['calories']} kcal'),
            ),
          ),
        );
      },
    );
  }

  int _calculateWeeklyCalories() {
    int weeklyCalories = 0;
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    for (final workout in (_prefs.getStringList('workoutHistory') ?? [])) {
      final parts = workout.split(' | ');
      if (parts.length == 4) {
        final date = DateFormat('yyyy-MM-dd').parse(parts[1]);
        if (date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            date.isBefore(today.add(const Duration(days: 1)))) {
          weeklyCalories += int.tryParse(parts[3].split(' ')[0]) ?? 0;
        }
      }
    }
    return weeklyCalories;
  }

  int _calculateWeeklyMinutes() {
    int weeklyMinutes = 0;
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    for (final workout in (_prefs.getStringList('workoutHistory') ?? [])) {
      final parts = workout.split(' | ');
      if (parts.length == 4) {
        final date = DateFormat('yyyy-MM-dd').parse(parts[1]);
        if (date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            date.isBefore(today.add(const Duration(days: 1)))) {
          weeklyMinutes += int.tryParse(parts[2].split(' ')[0]) ?? 0;
        }
      }
    }
    return weeklyMinutes;
  }

  String formatWorkoutTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '$minutes min';
    }
  }
}

// Stats Screen
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  StatsScreenState createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen> {
  late SharedPreferences _prefs;
  List<String> _workoutHistory = [];
  Map<String, int> _weeklyCalories = {};
  Map<String, int> _weeklyWorkoutMinutes = {};
  Map<String, int> _monthlyCalories = {};
  Map<String, int> _monthlyWorkoutMinutes = {};

  // ** Customizable Settings **
  final double _factIconSize = 24; // Size of the fact icons
  final Color _factIconColor = Colors.white; // Color of the fact icons

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _workoutHistory = _prefs.getStringList('workoutHistory') ?? [];
      _calculateWeeklyData();
      _calculateMonthlyData();
    });
  }

  void _calculateWeeklyData() {
    _weeklyCalories = {};
    _weeklyWorkoutMinutes = {};
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      _weeklyCalories[formattedDate] = 0;
      _weeklyWorkoutMinutes[formattedDate] = 0;
    }

    for (final workout in _workoutHistory) {
      final parts = workout.split(' | ');
      if (parts.length == 4) {
        final date = parts[1];
        final minutes = int.tryParse(parts[2].split(' ')[0]) ?? 0;
        final calories = int.tryParse(parts[3].split(' ')[0]) ?? 0;

        if (_weeklyCalories.containsKey(date)) {
          _weeklyCalories[date] = _weeklyCalories[date]! + calories;
          _weeklyWorkoutMinutes[date] = _weeklyWorkoutMinutes[date]! + minutes;
        }
      }
    }
  }

  void _calculateMonthlyData() {
    _monthlyCalories = {};
    _monthlyWorkoutMinutes = {};
    final today = DateTime.now();
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0);

    // Calculate the number of weeks in the current month
    int weeksInMonth = ((monthEnd.day - monthStart.day) / 7).ceil();

    // Initialize the maps with week numbers
    for (int i = 1; i <= weeksInMonth; i++) {
      _monthlyCalories['W$i'] = 0;
      _monthlyWorkoutMinutes['W$i'] = 0;
    }

    for (final workout in _workoutHistory) {
      final parts = workout.split(' | ');
      if (parts.length == 4) {
        final date = DateTime.parse(parts[1]);
        final minutes = int.tryParse(parts[2].split(' ')[0]) ?? 0;
        final calories = int.tryParse(parts[3].split(' ')[0]) ?? 0;

        // Check if the workout falls within the current month
        if (date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            date.isBefore(monthEnd.add(const Duration(days: 1)))) {
          // Determine the week number for the workout
          int weekNumber = ((date.day - monthStart.day) / 7).ceil() + 1;
          String weekKey = 'W$weekNumber';

          // Update the monthly calories and minutes for the corresponding week
          _monthlyCalories[weekKey] = (_monthlyCalories[weekKey] ?? 0) + calories;
          _monthlyWorkoutMinutes[weekKey] = (_monthlyWorkoutMinutes[weekKey] ?? 0) + minutes;
        }
      }
    }
  }

  String _getMostFrequentWorkout() {
    Map<String, int> workoutFrequency = {};
    for (final workout in _workoutHistory) {
      final parts = workout.split(' | ');
      if (parts.length == 4) {
        final name = parts[0];
        workoutFrequency[name] = (workoutFrequency[name] ?? 0) + 1;
      }
    }

    String mostFrequent = '';
    int maxFrequency = 0;
    workoutFrequency.forEach((workout, frequency) {
      if (frequency > maxFrequency) {
        mostFrequent = workout;
        maxFrequency = frequency;
      }
    });

    return mostFrequent.isNotEmpty ? mostFrequent : 'None';
  }

  int _getMaxCaloriesBurned() {
    int maxCalories = 0;
    for (final workout in _workoutHistory) {
      final parts = workout.split(' | ');
      if (parts.length == 4) {
        final calories = int.tryParse(parts[3].split(' ')[0]) ?? 0;
        if (calories > maxCalories) {
          maxCalories = calories;
        }
      }
    }
    return maxCalories;
  }

  int _getMaxWorkoutDuration() {
    int maxDuration = 0;
    for (final workout in _workoutHistory) {
      final parts = workout.split(' | ');
      if (parts.length == 4) {
        final duration = int.tryParse(parts[2].split(' ')[0]) ?? 0;
        if (duration > maxDuration) {
          maxDuration = duration;
        }
      }
    }
    return maxDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Calories Burned',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCaloriesChart(_weeklyCalories, Colors.lightBlueAccent),
            const SizedBox(height: 32),
            const Text(
              'Weekly Workout Minutes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildWorkoutMinutesChart(
                _weeklyWorkoutMinutes, Colors.lightGreenAccent),
            const SizedBox(height: 32),
            const Text(
              'Monthly Calories Burned',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCaloriesChart(_monthlyCalories, Colors.orangeAccent, isMonthly: true),
            const SizedBox(height: 32),
            const Text(
              'Monthly Workout Minutes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildWorkoutMinutesChart(
                _monthlyWorkoutMinutes, Colors.purpleAccent, isMonthly: true),
            const SizedBox(height: 32),
            const Text(
              'Workout Facts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildWorkoutFacts(),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesChart(Map<String, int> data, Color barColor, {bool isMonthly = false}) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values
                  .reduce((curr, next) => curr > next ? curr : next)
                  .toDouble() +
              100,
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String label;
                if (data == _weeklyCalories || data == _weeklyWorkoutMinutes) {
                  label = DateFormat('EEE').format(
                      DateTime.parse(data.keys.elementAt(groupIndex)));
                } else {
                  label = data.keys.elementAt(groupIndex);
                }
                return BarTooltipItem(
                  '$label\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${rod.toY.toInt()} ${data == _weeklyCalories || data == _monthlyCalories ? "kcal" : "min"}',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  String label;
                  if (isMonthly) {
                    label = data.keys.elementAt(index);
                  } else {
                    label = DateFormat('EEE').format(
                        DateTime.parse(data.keys.elementAt(index)));
                  }
                  if (index >= 0 && index < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  } else {
                    return const Text('');
                  }
                },
                reservedSize: 38,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: data.entries
              .map(
                (entry) => BarChartGroupData(
                  x: data.keys.toList().indexOf(entry.key),
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: barColor,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Widget _buildWorkoutMinutesChart(Map<String, int> data, Color barColor, {bool isMonthly = false}) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values
                  .reduce((curr, next) => curr > next ? curr : next)
                  .toDouble() +
              30,
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String label;
                if (data == _weeklyCalories || data == _weeklyWorkoutMinutes) {
                  label = DateFormat('EEE').format(
                      DateTime.parse(data.keys.elementAt(groupIndex)));
                } else {
                  label = data.keys.elementAt(groupIndex);
                }
                return BarTooltipItem(
                  '$label\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${rod.toY.toInt()} min',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  String label;
                  if (isMonthly) {
                    label = data.keys.elementAt(index);
                  } else {
                    label = DateFormat('EEE').format(
                        DateTime.parse(data.keys.elementAt(index)));
                  }
                  if (index >= 0 && index < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  } else {
                    return const Text('');
                  }
                },
                reservedSize: 38,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: data.entries
              .map(
                (entry) => BarChartGroupData(
                  x: data.keys.toList().indexOf(entry.key),
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: barColor,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Widget _buildWorkoutFacts() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: const Color(0xFF222222),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFactRow(
                  CupertinoIcons.star_fill,
                  'Most Frequent Workout',
                  _getMostFrequentWorkout(),
                  _factIconColor,
                  _factIconSize),
              const SizedBox(height: 16),
              _buildFactRow(
                  CupertinoIcons.flame_fill,
                  'Max Calories Burned',
                  '${_getMaxCaloriesBurned()} kcal',
                  _factIconColor,
                  _factIconSize),
              const SizedBox(height: 16),
              _buildFactRow(
                  CupertinoIcons.time,
                  'Max Workout Duration',
                  '${_getMaxWorkoutDuration()} min',
                  _factIconColor,
                  _factIconSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactRow(
      IconData icon, String title, String value, Color color, double size) {
    return Row(
      children: [
        Icon(icon, size: size, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
//Timer Screen
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  TimerScreenState createState() => TimerScreenState();
}

class TimerScreenState extends State<TimerScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Duration _duration = const Duration();
  bool _isRunning = false;

  // ** Customizable Settings **
  final double _timerButtonSpacing = 24; // Spacing between timer buttons
  final double _circularIndicatorRadius = 120; // Radius of the circular indicator
  final double _circularIndicatorLineWidth = 7; // Line width of the circular indicator
  final Color _resetButtonColor = const Color.fromARGB(255, 255, 31, 49); // Color for the reset button
  final double _iconButtonSize = 39; // Size for the icon buttons
  final Color _startButtonRestColor =
      const Color.fromARGB(255, 26, 220, 97); // Color for the start button when not running
  final Color _startButtonRunningColor =
      const Color.fromARGB(255, 255, 41, 70); // Color for the start button when running
// Color for the resume button
  final double _buttonVerticalPadding = 40; // Vertical padding around the buttons

  void _setDuration(Duration duration) {
    setState(() {
      _duration = duration;
      _stopwatch.reset();
    });
  }

  void _startStopTimer() {
    setState(() {
      if (_isRunning) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
        _updateTimer();
      }
      _isRunning = !_isRunning;
    });
  }

  void _resetTimer() {
    setState(() {
      _stopwatch.reset();
      _duration = const Duration();
      _isRunning = false;
    });
  }

  void _updateTimer() {
    if (_stopwatch.isRunning) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_stopwatch.isRunning) {
          setState(() {
            if (_stopwatch.elapsed >= _duration) {
              _stopwatch.stop();
              _isRunning = false;
              _showTimerCompleteDialog();
            }
          });
          _updateTimer();
        }
      });
    }
  }

  void _showTimerCompleteDialog() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Vibrate 3 times with a 500ms pause between each vibration
    // for (int i = 0; i < 3; i++) {
    //   if (await Vibration.hasVibrator() ?? false) {
    //     Vibration.vibrate(duration: 100);
    //   }
    //   await Future.delayed(const Duration(milliseconds: 500));
    // }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: const Text('Timer Complete'),
          content: const Text('The timer has finished.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircularPercentIndicator(
              radius: _circularIndicatorRadius,
              lineWidth: _circularIndicatorLineWidth,
              animation: false,
              percent: _stopwatch.elapsed >= _duration
                  ? 0
                  : 1 - (_stopwatch.elapsed.inSeconds / _duration.inSeconds),
              center: Text(
                _formatTime(_duration - _stopwatch.elapsed),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 40.0),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: Colors.red,
              backgroundColor: Colors.grey,
            ),
            const SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(vertical: _buttonVerticalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: _iconButtonSize,
                    onPressed: _startStopTimer,
                    icon:
                        Icon(_isRunning ? Icons.pause_circle : Icons.play_circle),
                    color: _isRunning
                        ? _startButtonRunningColor
                        : _startButtonRestColor,
                  ),
                  SizedBox(width: _timerButtonSpacing),
                  IconButton(
                    iconSize: _iconButtonSize,
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.stop_circle),
                    color: _resetButtonColor,
                  ),
                  SizedBox(width: _timerButtonSpacing),
                  IconButton(
                    iconSize: _iconButtonSize,
                    onPressed: () {
                      _showDurationPickerDialog();
                    },
                    icon: const Icon(Icons.access_time),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDurationPickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) {
        Duration tempDuration = _duration;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: 250,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.ms,
                      initialTimerDuration: tempDuration,
                      onTimerDurationChanged: (Duration newDuration) {
                        setModalState(() {
                          tempDuration = newDuration;
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          _setDuration(tempDuration);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Set',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _notificationsEnabled = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? false;
      _selectedLanguage = _prefs.getString('selectedLanguage') ?? 'English';
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await _prefs.setString('selectedLanguage', _selectedLanguage);
  }

  void _exportData() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    // Use the Downloads directory for saving the file
    Directory? directory = await getDownloadsDirectory();

    if (directory != null) {
      final file = File('${directory.path}/fitness_data.json');

      final data = {
        'workoutHistory': _prefs.getStringList('workoutHistory') ?? [],
        'currentStreak': _prefs.getInt('currentStreak') ?? 0,
        'totalCaloriesBurned': _prefs.getInt('totalCaloriesBurned') ?? 0,
        'totalWorkoutMinutes': _prefs.getInt('totalWorkoutMinutes') ?? 0,
        'userName': _prefs.getString('userName') ?? 'User',
        'userAge': _prefs.getInt('userAge') ?? 25,
        'userHeight': _prefs.getDouble('userHeight') ?? 175.0,
        'userWeight': _prefs.getDouble('userWeight') ?? 70.0,
        'notificationsEnabled': _prefs.getBool('notificationsEnabled') ?? false,
        'selectedLanguage': _prefs.getString('selectedLanguage') ?? 'English',
      };

      final String jsonData = jsonEncode(data);

      await file.writeAsString(jsonData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported to ${file.path}'),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get the Downloads directory.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFF222222),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                          _saveSettings();
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    trailing: Text(_selectedLanguage),
                    onTap: () {
                      // Show language selection dialog
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF222222),
                            title: const Text('Select Language'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('English'),
                                  onTap: () {
                                    setState(() {
                                      _selectedLanguage = 'English';
                                      _saveSettings();
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                                ListTile(
                                  title: const Text('فارسی'),
                                  onTap: () {
                                    setState(() {
                                      _selectedLanguage = 'فارسی';
                                      _saveSettings();
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 21),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _exportData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 72, 255),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Export Data as JSON',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
