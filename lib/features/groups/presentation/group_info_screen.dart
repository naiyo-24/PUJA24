import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/groups_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

final groupMembersProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, groupId) async {
  final apiService = ref.watch(groupsApiServiceProvider);
  return apiService.fetchGroupMembers(groupId);
});

final groupInfoDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, groupId) async {
  final apiService = ref.watch(groupsApiServiceProvider);
  return apiService.fetchGroupDetails(groupId);
});

class GroupInfoScreen extends ConsumerStatefulWidget {
  final String groupId;
  
  const GroupInfoScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen> {
  String? _currentUserId;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('user_id');
    });
  }

  void _removeMember(String memberId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $name from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(groupsApiServiceProvider).removeMember(widget.groupId, memberId);
              if (success && mounted) {
                ref.invalidate(groupMembersProvider(widget.groupId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name removed from group'), backgroundColor: AppColors.errorRed),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to remove member'), backgroundColor: AppColors.errorRed),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  void _addMember(String joinCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.charcoal : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 24.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Share this invite code or scan the QR to join the group:', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: QrImageView(
                  data: joinCode,
                  version: QrVersions.auto,
                  size: 180.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.pujaRed,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  joinCode,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Share code logic
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied!')));
                  },
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text('Share Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pujaRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditGroupDialog(String currentName, String currentEmoji) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    final TextEditingController emojiController = TextEditingController(text: currentEmoji);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(labelText: 'Emoji', hintText: 'Enter a single emoji'),
              maxLength: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
              maxLength: 50,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmoji = emojiController.text.trim();
              
              if (newName.isNotEmpty && newEmoji.isNotEmpty) {
                Navigator.pop(context);
                final success = await ref.read(groupsApiServiceProvider).editGroup(
                  widget.groupId,
                  name: newName,
                  emoji: newEmoji,
                );
                
                if (success && mounted) {
                  ref.invalidate(groupInfoDetailsProvider(widget.groupId));
                  ref.invalidate(myGroupsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group updated!'), backgroundColor: Colors.green),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update group'), backgroundColor: AppColors.errorRed),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.pujaRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupAsync = ref.watch(groupInfoDetailsProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

    return PopScope(
      canPop: !_isSearching,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchQuery = '';
          });
        }
      },
      child: Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }

          String emoji = '🥁';
          Color color = const Color(0xFFE53935);
          if (group['picture_url'] != null && group['picture_url'].toString().startsWith('{')) {
            try {
              final picData = jsonDecode(group['picture_url']);
              emoji = picData['emoji'] ?? emoji;
              if (picData['colorHex'] != null) {
                color = Color(int.parse(picData['colorHex'].replaceAll('#', '0xFF')));
              }
            } catch (e) {}
          }
          final String name = group['name'] ?? 'Group';
          final String joinCode = group['join_code'] ?? 'UNKNOWN';
          final String adminId = group['admin_id'] ?? '';
          final isAdmin = _currentUserId == adminId;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupMembersProvider(widget.groupId));
              ref.invalidate(groupInfoDetailsProvider(widget.groupId));
              // Small delay to let UI show the spinner
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.pujaRed,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverAppBar(
                  expandedHeight: 280.0,
                  pinned: true,
                  stretch: true,
                  backgroundColor: color,
                  elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () {
                    if (_isSearching) {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                      });
                    } else {
                      context.pop();
                    }
                  },
                ),
                actions: [
                  if (isAdmin)
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                        onPressed: () => _showEditGroupDialog(name, emoji),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withRed((color.red * 0.7).toInt()).withGreen((color.green * 0.7).toInt()).withBlue((color.blue * 0.7).toInt())
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Decorative circles in background
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 64, height: 1),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 26, 
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            membersAsync.when(
                              data: (members) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${members.length} participants',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              loading: () => const SizedBox(),
                              error: (_, __) => const SizedBox(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action buttons
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(Icons.person_add_rounded, 'Add', isDark, color, () => _addMember(joinCode)),
                            _buildActionButton(Icons.search_rounded, 'Search', isDark, color, () {
                              setState(() {
                                _isSearching = !_isSearching;
                                if (!_isSearching) _searchQuery = '';
                              });
                            }),
                            _buildActionButton(Icons.qr_code_rounded, 'Share QR', isDark, color, () => _addMember(joinCode)),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Members List
                      membersAsync.when(
                        data: (members) {
                          final isAdmin = _currentUserId == adminId;

                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: color.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20.0),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.05),
                                      border: Border(bottom: BorderSide(color: color.withOpacity(0.1))),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.people_alt_rounded, color: color, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${members.length} Members', 
                                          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Search Bar
                                  if (_isSearching)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                                      child: TextField(
                                        autofocus: true,
                                        onChanged: (val) {
                                          setState(() {
                                            _searchQuery = val;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Search members...',
                                          prefixIcon: const Icon(Icons.search),
                                          filled: true,
                                          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    ),
                                    
                                  // Member list
                                  Builder(
                                    builder: (context) {
                                      final filteredMembers = members.where((m) {
                                        final name = (m['full_name'] ?? '').toString().toLowerCase();
                                        return name.contains(_searchQuery.toLowerCase());
                                      }).toList();

                                      if (filteredMembers.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.all(32.0),
                                          child: Center(
                                            child: Text('No members found', style: TextStyle(color: Colors.grey[500])),
                                          ),
                                        );
                                      }

                                      return ListView.separated(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: filteredMembers.length,
                                        separatorBuilder: (context, index) => Divider(height: 1, indent: 76, color: isDark ? Colors.grey[800] : Colors.grey[100]),
                                        itemBuilder: (context, index) {
                                          final member = filteredMembers[index];
                                      final bool isMemberAdmin = member['user_id'] == adminId;
                                      final bool isMe = member['user_id'] == _currentUserId;
                                      final String memberName = member['full_name'] ?? 'Unknown User';
                                      final String memberPhone = member['phone_number'] ?? 'No phone number';
                                      final memberEmail = member['email'] ?? '';
                                      final String? profileImage = member['profile_image_url'];
                                      
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        leading: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                          backgroundImage: profileImage != null && profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                                          child: profileImage != null && profileImage.isNotEmpty ? null : Text(
                                            memberName.isNotEmpty ? memberName[0].toUpperCase() : '?', 
                                            style: TextStyle(
                                              color: isDark ? Colors.white : Colors.black87, 
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                memberName + (isMe ? ' (You)' : ''), 
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isMemberAdmin) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)]),
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: [
                                                    BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                                                  ],
                                                ),
                                                child: const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                              ),
                                            ]
                                          ],
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            memberEmail.isNotEmpty ? memberEmail : memberPhone,
                                            style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        trailing: (isAdmin && !isMemberAdmin) 
                                          ? IconButton(
                                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.grey),
                                              onPressed: () => _removeMember(member['user_id'], memberName),
                                            )
                                          : null,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => const Center(child: Text('Error loading members')),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Exit / Delete Group Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD32F2F), Color(0xFFF44336)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD32F2F).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final isUserAdmin = _currentUserId == adminId;
                              final action = isUserAdmin ? 'Delete' : 'Exit';
                              
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Text('$action Group', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  content: Text('Are you sure you want to ${action.toLowerCase()} this group? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.errorRed,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text(action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && mounted) {
                                 final success = isUserAdmin 
                                      ? await ref.read(groupsApiServiceProvider).deleteGroup(widget.groupId)
                                      : await ref.read(groupsApiServiceProvider).exitGroup(widget.groupId);
                                      
                                 if (success && mounted) {
                                   ref.invalidate(myGroupsProvider);
                                   try { await ref.read(myGroupsProvider.future); } catch (_) {}
                                   context.go('/explore');
                                 } else if (mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to ${action.toLowerCase()} group'), backgroundColor: AppColors.errorRed),
                                   );
                                 }
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _currentUserId == adminId ? Icons.delete_forever_rounded : Icons.exit_to_app_rounded, 
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _currentUserId == adminId ? 'Delete Group' : 'Exit Group', 
                                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Error loading group details')),
      ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, bool isDark, Color brandColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brandColor.withOpacity(0.15), brandColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: brandColor.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(icon, color: brandColor, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label, 
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}
