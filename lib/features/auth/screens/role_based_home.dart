import 'package:flutter/material.dart';
import 'package:workers_hub/core/services/auth_service.dart';
import 'package:workers_hub/features/auth/screens/role_selection_screen.dart';
import 'package:workers_hub/features/home/screens/worker_home_screen.dart';
import 'package:workers_hub/features/home/screens/contractor_home_screen.dart';

class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      // Shold typically not happen if we are here, but safe fallback
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<String?>(
      future: AuthService().getUserRole(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error loading profile')),
          );
        }

        final role = snapshot.data;

        if (role == 'worker') {
          return const WorkerHomeScreen();
        } else if (role == 'contractor') {
          return const ContractorHomeScreen();
        } else {
          // 'new' or null, or any other unknown role
          return const RoleSelectionScreen();
        }
      },
    );
  }
}
