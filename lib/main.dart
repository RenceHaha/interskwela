import 'package:flutter/material.dart';
import 'package:interskwela/student/page.dart';
import 'login_page.dart';
import 'admin/page.dart';
import 'teacher/page.dart';
import 'themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:jwt_decoder/jwt_decoder.dart'; // Import jwt_decoder

Future<void> main() async {
  // 1. Ensure Flutter bindings are initialized so we can use async code in main
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Check Shared Preferences for Token
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final role = prefs.getString('role');

  String initialRoute = '/login';

  // 3. Validate Token
  if (token != null && token.isNotEmpty) {
    try {
      // If token is NOT expired, skip login
      if (!JwtDecoder.isExpired(token)) {
        switch (role) {
          case 'admin':
            initialRoute = '/admin/home';
            break;
          case 'teacher':
            initialRoute = '/teacher/home';
            break;
          case 'student':
            initialRoute = '/student/home';
            break;
          default:
            initialRoute = '/login';
        }
      } else {
        // Token expired, clean up just in case
        prefs.clear();
      }
    } catch (e) {
      // If token is malformed, default to login
      print("Error decoding token: $e");
      initialRoute = '/login';
    }
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute; // Field to hold the dynamic route

  // Update constructor to require initialRoute
  const MyApp({
    required this.initialRoute,
    super.key
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute, // Use the computed route
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginPage(),
        '/admin/home': (context) => const AdminPage(),
        '/teacher/home': (context) => const TeacherPage(),
        '/student/home': (context) => const StudentPage()
      },
    );
  }
}