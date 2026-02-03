import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';

/// Profile screen for viewing and editing user information.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _occupationController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _ageController.text = user.age?.toString() ?? '';
      _occupationController.text = user.occupation ?? '';
      _addressController.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

    if (authProvider.user == null) return;

    userProvider.setUser(authProvider.user);

    final success = await userProvider.updateProfile(
      userId: authProvider.user!.id,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text),
      occupation: _occupationController.text.trim().isEmpty 
          ? null 
          : _occupationController.text.trim(),
      address: _addressController.text.trim().isEmpty 
          ? null 
          : _addressController.text.trim(),
    );

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        await authProvider.refreshUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.profileUpdated),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (userProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        automaticallyImplyLeading: false,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _loadUserData(); // Reset form
              },
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: userProvider.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.name.isNotEmpty == true 
                        ? user!.name[0].toUpperCase() 
                        : 'U',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role.displayName ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 32),

                // Form fields
                CustomTextField(
                  controller: _nameController,
                  labelText: AppStrings.name,
                  validator: Validators.required,
                  enabled: _isEditing,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _ageController,
                  labelText: AppStrings.age,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.age,
                  enabled: _isEditing,
                  prefixIcon: const Icon(Icons.cake_outlined),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _occupationController,
                  labelText: AppStrings.occupation,
                  enabled: _isEditing,
                  prefixIcon: const Icon(Icons.work_outline),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _addressController,
                  labelText: AppStrings.address,
                  maxLines: 3,
                  enabled: _isEditing,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                const SizedBox(height: 32),

                // Save button
                if (_isEditing)
                  FullWidthButton(
                    text: AppStrings.saveChanges,
                    onPressed: _saveProfile,
                    isLoading: userProvider.isLoading,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
