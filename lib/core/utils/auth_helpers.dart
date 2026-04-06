import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

class AuthHelpers {
  /// Check if user is authenticated, show login dialog if not
  /// Returns true if authenticated, false if not
  static Future<bool> requireAuth(
    BuildContext context, {
    String? message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return true;
    }

    if (!context.mounted) return false;

    // Show login required dialog
    final shouldLogin = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoginRequiredDialog(message: message),
    );

    if (shouldLogin == true) {
      if (!context.mounted) return false;

      // Navigate to login screen
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      // Check again if user logged in
      return FirebaseAuth.instance.currentUser != null;
    }

    return false;
  }
}

class _LoginRequiredDialog extends StatelessWidget {
  final String? message;

  const _LoginRequiredDialog({this.message});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.login_rounded,
                      color: AppTheme.secondaryColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تسجيل الدخول مطلوب',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                message ?? 'يجب تسجيل الدخول أولاً للقيام بهذا الإجراء',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'هل تريد تسجيل الدخول الآن؟',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondaryColor,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'ليس الآن',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
