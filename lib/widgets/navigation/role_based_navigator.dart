import 'package:flutter/material.dart';
import '../../models/enums/user_role.dart';
import '../../screens/customer/customer_home_screen.dart';
import '../../screens/therapist/therapist_home_screen.dart';
import '../../screens/admin/admin_home_screen.dart';

/// Navigator that routes to the appropriate home screen based on user role.
class RoleBasedNavigator extends StatelessWidget {
  final UserRole role;

  const RoleBasedNavigator({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.customer:
        return const CustomerHomeScreen();
      case UserRole.therapist:
        return const TherapistHomeScreen();
      case UserRole.admin:
        return const AdminHomeScreen();
    }
  }
}
