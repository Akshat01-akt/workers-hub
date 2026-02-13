import 'package:flutter/material.dart';
import 'package:workers_hub/core/services/auth_service.dart';
import 'package:workers_hub/core/theme/app_theme.dart';
import 'package:workers_hub/features/auth/screens/sign_in_screen.dart';

class ContractorHomeScreen extends StatelessWidget {
  const ContractorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Home'),
        backgroundColor: AppTheme.secondaryColor, // Distinct color
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: const Center(child: Text('Welcome Contractor! Find Workers Here.')),
    );
  }
}
