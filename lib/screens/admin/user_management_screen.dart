import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/enums/user_role.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/loading_widget.dart';

/// User management screen for admin to view and modify user roles.
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.allUsers.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline,
              title: 'Tidak ada pengguna',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: userProvider.allUsers.length,
            itemBuilder: (context, index) {
              final user = userProvider.allUsers[index];
              return _UserCard(
                user: user,
                onRoleChanged: (role) => _updateRole(context, user, role),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateRole(BuildContext context, UserModel user, UserRole role) async {
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.updateUserRole(user.id, role);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Role berhasil diubah' : 'Gagal mengubah role',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

/// User card widget.
class _UserCard extends StatelessWidget {
  final UserModel user;
  final void Function(UserRole) onRoleChanged;

  const _UserCard({
    required this.user,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.role),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.displayName,
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: UserRole.values.map((role) {
                final isSelected = user.role == role;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: isSelected ? null : () => _showConfirmDialog(context, role),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? _getRoleColor(role) : null,
                        foregroundColor: isSelected ? Colors.white : _getRoleColor(role),
                        side: BorderSide(color: _getRoleColor(role)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        role.displayName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return AppColors.info;
      case UserRole.therapist:
        return AppColors.primary;
      case UserRole.admin:
        return AppColors.warning;
    }
  }

  void _showConfirmDialog(BuildContext context, UserRole newRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Role'),
        content: Text(
          'Ubah role ${user.name} menjadi ${newRole.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRoleChanged(newRole);
            },
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
  }
}
