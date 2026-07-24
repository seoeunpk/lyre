import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/animated_snackbar.dart';
import '../widgets/avatar_circle.dart';
import 'account_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = AuthService().currentUser;
    setState(() {
      _name = user?.displayName ?? 'No name';
      _email = user?.email ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.text, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            AvatarCircle(
              id: AuthService().currentUser?.uid ?? _name,
              name: _name == 'No name' ? '' : _name,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              _email,
              style: const TextStyle(fontSize: 14, color: AppColors.grey),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                onTap: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  );
                  if (changed == true && mounted) _loadUser();
                },
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.manage_accounts_rounded,
                    color: AppColors.text, size: 20),
                title: const Text(
                  "My Account",
                  style: TextStyle(
                      color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.grey, size: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                onTap: () async {
                  await AuthService().signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.logout_rounded, color: AppColors.text, size: 20),
                title: const Text(
                  "Log Out",
                  style: TextStyle(
                      color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.grey, size: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                onTap: () => _confirmDeleteAccount(context),
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.delete_forever_rounded,
                    color: AppColors.red, size: 20),
                title: const Text(
                  "Delete Account",
                  style: TextStyle(
                      color: AppColors.red, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.grey, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete account?",
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 16)),
        content: const Text(
          "This can't be undone.",
          style: TextStyle(color: AppColors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final error = await AuthService().deleteAccount();
    if (!context.mounted) return;

    if (error != null) {
      showAnimatedSnackBar(context, error, isError: true);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}
