import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_notes_app/Screens/SignUpPage.dart';
import 'package:my_notes_app/Screens/notesScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      theme: _buildTheme(_isDarkMode),
      home: AuthWrapper(toggleTheme: toggleTheme, isDarkMode: _isDarkMode),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme(bool isDarkMode) {
    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      fontFamily: 'Roboto',
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.blueGrey[700] : Colors.blue[700],
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: isDarkMode ? Colors.blueGrey : Colors.blue,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ).copyWith(
          secondary: isDarkMode ? Colors.blueGrey[400] : Colors.blueAccent),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const AuthWrapper(
      {Key? key, required this.toggleTheme, required this.isDarkMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return Homescreen();
          }

          return NotesScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode);
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
