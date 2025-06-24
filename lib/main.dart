import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:sell_n_buy_updated/admin/admin_page.dart';
import 'package:sell_n_buy_updated/features/authentication/login_page.dart';
import 'package:sell_n_buy_updated/features/home/homepage.dart';
import 'package:sell_n_buy_updated/services/auth_service.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';
import 'package:sell_n_buy_updated/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase already initialized: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[300],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 7, 33, 62),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 7, 33, 62),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<User?>(
      builder: (context, user, child) {
        print('AuthWrapper: User is ${user != null ? 'logged in' : 'not logged in'}');
        
        if (user != null) {
          print('Navigating to Homepage');
          return Homepage();
        }
        
        print('Showing LoginPage');
        return LoginPage();
      },
    );
  }
}
