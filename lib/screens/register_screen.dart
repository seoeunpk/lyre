import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String password) {
    if (password.length <= 6) return "Password must be more than 6 characters.";
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(password)) {
      return "Password can only contain English letters and numbers.";
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return "Password must include at least one letter.";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must include at least one number.";
    }
    return null;
  }

  void register() async {
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    final err = _validatePassword(password);
    if (err != null) {
      setState(() => errorMessage = err);
      return;
    }

    if (password != confirm) {
      setState(() => errorMessage = "Passwords do not match.");
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    final error = await AuthService().signUp(
      nameController.text.trim(),
      emailController.text.trim(),
      password,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        loading = false;
        errorMessage = error;
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Join LYRE",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),


              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: _inputDecoration(label: "Name"),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: _inputDecoration(label: "Email"),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: _inputDecoration(label: "Password"),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: _inputDecoration(label: "Confirm Password"),
                onSubmitted: (_) => register(),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: loading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label}) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: AppColors.grey),
      filled: true,
      fillColor: AppColors.lightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.pink, width: 2),
      ),
    );
  }
}