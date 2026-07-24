import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LYRE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        textTheme: Typography.material2021().black.merge(
          const TextTheme(
            bodyLarge: TextStyle(fontWeight: FontWeight.w500),
            bodyMedium: TextStyle(fontWeight: FontWeight.w500),
            bodySmall: TextStyle(fontWeight: FontWeight.w500),
            labelLarge: TextStyle(fontWeight: FontWeight.w600),
            labelMedium: TextStyle(fontWeight: FontWeight.w500),
            labelSmall: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
      ),
      home: AuthService().currentUser != null
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
