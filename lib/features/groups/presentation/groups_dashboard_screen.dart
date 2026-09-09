import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../data/groups_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupsDashboardScreen extends ConsumerStatefulWidget {
  const GroupsDashboardScreen({super.key});

  @override
  ConsumerState<GroupsDashboardScreen> createState() => _GroupsDashboardScreenState();
}

class _GroupsDashboardScreenState extends ConsumerState<GroupsDashboardScreen> {
  // Groups are now fetched via API

  void _showCreateJoinBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.charcoal : Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  'Let\'s go pandal hopping!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 22),
                ),
                const SizedBox(height: 24),
                _buildActionCard(
                  title: 'Create a New Group',
                  subtitle: 'Invite your friends and plan an itinerary together',
                  icon: Icons.group_add_rounded,
                  color: AppColors.pujaRed,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/groups/create');
                  },
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  title: 'Join with Code / QR',
                  subtitle: 'Enter a 6-digit code or scan an invite QR',
                  icon: Icons.qr_code_scanner_rounded,
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/groups/join');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          border: Border.all(color: color.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Background colors for the screen
    final bgColor1 = isDark ? const Color(0xFF121212) : const Color(0xFFFBF8F1);
    final bgColor2 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2ECE0);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor1, bgColor2],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 8.0),
                child: Text(
                  'My Groups',
                  style: GoogleFonts.playfairDisplay(
                    textStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.pujaRed,
                  onRefresh: () async {
                    ref.invalidate(myGroupsProvider);
                    try {
                      await ref.read(myGroupsProvider.future);
                    } catch (_) {}
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8).copyWith(bottom: 120),
            sliver: Consumer(
              builder: (context, ref, child) {
                final groupsAsync = ref.watch(myGroupsProvider);

                return groupsAsync.when(
                  data: (groups) {
                    if (groups.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_off_rounded, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No Groups Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Text('Create or join a group to start planning!', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final group = groups[index];
                          
                          String? groupEmoji = group['emoji'];
                          String? groupColorHex = group['colorHex'];
                          
                          if (group['picture_url'] != null && group['picture_url'].toString().startsWith('{')) {
                            try {
                              final picData = jsonDecode(group['picture_url']);
                              groupEmoji = picData['emoji'];
                              groupColorHex = picData['colorHex'];
                            } catch (e) {}
                          }

                          Color groupColor = AppColors.pujaRed;
                          if (groupColorHex != null) {
                            try {
                              groupColor = Color(int.parse(groupColorHex.replaceAll('#', '0xFF')));
                            } catch (e) {}
                          }
                          // Re-map backend keys to match UI expectations
                          final uiGroup = {
                            'id': group['id'],
                            'name': group['name'] ?? 'Unnamed',
                            'members': group['member_count'] ?? group['members']?.length ?? 1,
                            'emoji': groupEmoji ?? '🔥',
                            'color': groupColor,
                            'nextStop': group['nextStop'] ?? 'No plan yet',
                            'admin_id': group['admin_id'],
                          };
                          
                          return _buildGroupCard(uiGroup, isDark);
                        },
                        childCount: groups.length,
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.pujaRed)),
                  ),
                  error: (error, stack) => SliverFillRemaining(
                    child: Center(child: Text('Error loading groups: $error')),
                  ),
                );
                },
              ),
            ),
          ],
        ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0), // increased to 120 to definitively clear the bottom nav
        child: FloatingActionButton.extended(
          onPressed: _showCreateJoinBottomSheet,
          label: const Text('New Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          backgroundColor: AppColors.pujaRed,
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.pujaRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, size: 64, color: AppColors.pujaRed),
            ),
            const SizedBox(height: 24),
            const Text(
              'No groups yet!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a group to plan pandal hopping, share live locations, and chat with your friends.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, bool isDark) {
    final Color groupColor = group['color'];
    final bool isDarkColor = groupColor.computeLuminance() < 0.5;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: groupColor.withOpacity(isDark ? 0.2 : 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: groupColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            context.push('/groups/details/${group['id']}');
          },
          onLongPress: () {
            _showGroupOptions(group, isDark);
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Circular Emoji Avatar with Glow
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        groupColor.withOpacity(0.7),
                        groupColor,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(group['emoji'], style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(width: 20),
                
                // Group Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['name'],
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w800, 
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      
                      // Members Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? groupColor.withOpacity(0.2) : groupColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_alt_rounded, size: 14, color: isDark ? groupColor.withOpacity(0.9) : groupColor),
                            const SizedBox(width: 6),
                            Text(
                              '${group['members']} Members',
                              style: TextStyle(
                                color: isDark ? groupColor.withOpacity(0.9) : groupColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Next Stop row
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Next: ${group['nextStop']}',
                              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                // Chevron
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey[400] : Colors.grey[500], size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupOptions(Map<String, dynamic> group, bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    
    // Decode user_id locally
    String currentUserId = '';
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final map = jsonDecode(decoded);
        currentUserId = map['sub']?.toString() ?? '';
      }
    } catch (e) {}

    final bool isAdmin = group['admin_id'] == currentUserId;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: isDark ? AppColors.charcoal : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              Text(group['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive Group'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group archived')));
                },
              ),
              
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                  title: const Text('Delete Group', style: TextStyle(color: AppColors.errorRed)),
                  onTap: () async {
                    Navigator.pop(context);
                    final api = ref.read(groupsApiServiceProvider);
                    final success = await api.deleteGroup(group['id']);
                    if (success) {
                      ref.invalidate(myGroupsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group deleted')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete group')));
                    }
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: AppColors.errorRed),
                  title: const Text('Exit Group', style: TextStyle(color: AppColors.errorRed)),
                  onTap: () async {
                    Navigator.pop(context);
                    final api = ref.read(groupsApiServiceProvider);
                    final success = await api.leaveGroup(group['id']);
                    if (success) {
                      ref.invalidate(myGroupsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You left the group')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to leave group')));
                    }
                  },
                ),
            ],
          ),
        ),
        );
      },
    );
  }
}

