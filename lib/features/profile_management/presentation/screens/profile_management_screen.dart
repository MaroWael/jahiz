import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jahiz/core/constants/app_colors.dart';
import 'package:jahiz/features/profile_management/presentation/controllers/profile_management_controller.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  static const List<String> _levelOptions = <String>['junior', 'mid', 'senior'];

  final ProfileManagementController _controller = ProfileManagementController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _stackController = TextEditingController();

  String _email = '';
  String? _selectedLevel;
  List<String> _techStack = <String>[];

  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isFormValid {
    return _roleController.text.trim().isNotEmpty &&
        (_selectedLevel?.trim().isNotEmpty ?? false) &&
        _techStack.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _roleController.dispose();
    _stackController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _controller.loadCurrentProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _email = data.email;
        _roleController.text = data.role;
        _selectedLevel = _levelOptions.contains(data.level) ? data.level : null;
        _techStack = List<String>.from(data.techStack);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      _showSnackBar('Unable to load profile data.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isNetworkSyncFailure(Object error) {
    if (error is FirebaseException) {
      const connectivityCodes = <String>{
        'unavailable',
        'network-request-failed',
        'deadline-exceeded',
      };
      return connectivityCodes.contains(error.code);
    }
    return false;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_isFormValid || _selectedLevel == null) {
      _showSnackBar('Role, level, and tech stack are required.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _controller.updateProfile(
        role: _roleController.text.trim(),
        level: _selectedLevel!,
        techStack: _techStack,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('Profile updated successfully.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (_isNetworkSyncFailure(error)) {
        _showSnackBar('Check your internet connection');
      } else {
        _showSnackBar('Failed to update profile. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addStackItem() {
    final value = _stackController.text.trim();
    if (value.isEmpty) {
      return;
    }

    final exists = _techStack.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    if (exists) {
      _showSnackBar('This stack item is already added.');
      return;
    }

    setState(() {
      _techStack = <String>[..._techStack, value];
      _stackController.clear();
    });
  }

  void _removeStackItem(String value) {
    setState(() {
      _techStack = _techStack.where((item) => item != value).toList();
    });
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildReadOnlyField(
                    label: 'Email',
                    value: _email.isEmpty ? 'No email available' : _email,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _roleController,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      hintText: 'e.g., Flutter Developer',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Experience Level',
                    ),
                    items: _levelOptions
                        .map(
                          (level) => DropdownMenuItem<String>(
                            value: level,
                            child: Text(_displayLevel(level)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedLevel = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stackController,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _addStackItem(),
                          decoration: const InputDecoration(
                            labelText: 'Tech Stack',
                            hintText: 'Add one item',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addStackItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_techStack.isEmpty)
                    const Text(
                      'Add at least one stack item.',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _techStack
                          .map(
                            (item) => Chip(
                              label: Text(item),
                              onDeleted: () => _removeStackItem(item),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _displayLevel(String level) {
    if (level.isEmpty) {
      return level;
    }
    return '${level[0].toUpperCase()}${level.substring(1)}';
  }
}
