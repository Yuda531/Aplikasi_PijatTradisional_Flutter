import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/navigation/role_based_navigator.dart';
import 'login_screen.dart';

/// Wrapper that routes users based on authentication state.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _previousUserId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth state
        if (authProvider.isLoading && authProvider.firebaseUser == null) {
          return const Scaffold(
            body: LoadingWidget(message: 'Memuat...'),
          );
        }

        // Not logged in - show login screen
        if (authProvider.firebaseUser == null) {
          // Clear booking data when user logs out
          if (_previousUserId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<BookingProvider>().clearAllData();
            });
            _previousUserId = null;
          }
          return const LoginScreen();
        }

        // Logged in but user data not loaded yet
        if (authProvider.user == null) {
          return const Scaffold(
            body: LoadingWidget(message: 'Memuat profil...'),
          );
        }

        // Track user changes and clear booking data when user changes
        final currentUserId = authProvider.user!.id;
        if (_previousUserId != null && _previousUserId != currentUserId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<BookingProvider>().clearAllData();
          });
        }
        _previousUserId = currentUserId;

        // Logged in with user data - route based on role
        return RoleBasedNavigator(role: authProvider.user!.role);
      },
    );
  }
}
