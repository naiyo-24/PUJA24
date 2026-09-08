import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../data/groups_api_service.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _presetIcons = [
    {'emoji': '🥁', 'color': const Color(0xFFE53935)}, // Red
    {'emoji': '🪔', 'color': const Color(0xFFFB8C00)}, // Orange
    {'emoji': '🪷', 'color': const Color(0xFFD81B60)}, // Pink
    {'emoji': '🛕', 'color': const Color(0xFFFFB300)}, // Yellow-Orange
    {'emoji': '🐚', 'color': const Color(0xFF00ACC1)}, // Teal
    {'emoji': '🔱', 'color': const Color(0xFF5E35B1)}, // Purple
    {'emoji': '🌼', 'color': const Color(0xFFFDD835)}, // Yellow
    {'emoji': '🔥', 'color': const Color(0xFFFF5722)}, // Deep Orange
    {'emoji': '👑', 'color': const Color(0xFFC2185B)}, // Magenta
    {'emoji': '✨', 'color': const Color(0xFF00897B)}, // Green-Teal
  ];
  int? _selectedPresetIndex;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedPresetIndex = null;
      });
    }
  }

  void _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name'), backgroundColor: AppColors.errorRed),
      );
      return;
    }
    
    if (_selectedImage == null && _selectedPresetIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group photo or icon'), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final success = await ref.read(groupsApiServiceProvider).createGroup(
      name: _nameController.text.trim(),
      emoji: _selectedPresetIndex != null ? _presetIcons[_selectedPresetIndex!]['emoji'] : null,
      colorHex: _selectedPresetIndex != null ? '#${(_presetIcons[_selectedPresetIndex!]['color'] as Color).value.toRadixString(16).substring(2)}' : null,
      image: _selectedImage,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Refresh dashboard
        ref.invalidate(myGroupsProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create group. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.ivory,
      appBar: AppBar(
        title: const Text('Create New Group', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.charcoal : AppColors.ivory,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Saptami Squad, Family Pandal Hopping...',
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Display picture',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Preset Icons Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: _presetIcons.length,
              itemBuilder: (context, index) {
                final preset = _presetIcons[index];
                final isSelected = _selectedPresetIndex == index;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPresetIndex = index;
                      _selectedImage = null; // Clear custom image
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: preset['color'],
                      border: Border.all(
                        color: isSelected ? AppColors.pujaRed : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.pujaRed.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ] : [],
                    ),
                    child: Center(
                      child: Text(
                        preset['emoji'],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 48),
            
            // Create Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pujaRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
