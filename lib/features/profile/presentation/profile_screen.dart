import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'widgets/map_location_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _profileImagePath;
  String _name = 'User Name';
  String _phone = 'Add Phone Number';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('local_profile_image_path');
    if (savedPath != null) {
      setState(() {
        _profileImagePath = savedPath;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_profile_image_path', pickedFile.path);
    }
  }

  void _showEditProfileSheet() {
    final authState = ref.read(authProvider);
    UserModel? user;
    if (authState is Authenticated) {
      user = authState.user;
    }

    final nameController = TextEditingController(text: user?.fullName ?? _name);
    final phoneController = TextEditingController(text: user?.phoneNumber ?? _phone);
    final addressController = TextEditingController(text: user?.address ?? '');
    final ageController = TextEditingController(text: user?.age?.toString() ?? '');

    String? selectedSex = user?.sex;
    if (selectedSex != 'Male' && selectedSex != 'Female' && selectedSex != 'Other') {
        selectedSex = null;
    }

    List<String> selectedPandals = List.from(user?.interestedPandals ?? []);
    final pandalOptions = [
      'North Kolkata', 'South Kolkata', 'Central',
      'Salt Lake', 'Behala', 'Howrah'
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Edit Profile',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isDark ? AppColors.pureWhite : AppColors.deepMaroon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person, color: AppColors.antiqueGold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone, color: AppColors.antiqueGold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.location_on, color: AppColors.antiqueGold),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.map, color: AppColors.pujaRed),
                          onPressed: () async {
                            final selectedAddress = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MapLocationPicker(),
                              ),
                            );
                            
                            if (selectedAddress != null) {
                              setSheetState(() {
                                addressController.text = selectedAddress;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.cake, color: AppColors.antiqueGold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedSex,
                            decoration: InputDecoration(
                              labelText: 'Sex',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.wc, color: AppColors.antiqueGold),
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) {
                              setSheetState(() {
                                selectedSex = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Interested Pandals (Areas)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.pureWhite : AppColors.deepMaroon,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pandalOptions.map((area) {
                        final isSelected = selectedPandals.contains(area);
                        return FilterChip(
                          label: Text(area),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setSheetState(() {
                              if (selected) {
                                selectedPandals.add(area);
                              } else {
                                selectedPandals.remove(area);
                              }
                            });
                          },
                          selectedColor: AppColors.antiqueGold.withOpacity(0.3),
                          checkmarkColor: AppColors.pujaRed,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Call backend update
                          await ref.read(authProvider.notifier).updateProfile(
                            fullName: nameController.text,
                            phone: phoneController.text,
                            address: addressController.text,
                            age: int.tryParse(ageController.text) ?? 0,
                            sex: selectedSex ?? 'Other',
                            interestedPandals: selectedPandals,
                          );
                          if (context.mounted) {
                            context.pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pujaRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.ivory,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildProfileHeader(theme, context),
            if (authState is Authenticated && authState.user.address != null && authState.user.address!.isNotEmpty)
              _buildAddressMapCard(authState.user.address!, theme, isDark),
            const SizedBox(height: 24),
            _buildStatsRow(theme, isDark),
            const SizedBox(height: 32),
            _buildMenuSection(context, theme, isDark),
            const SizedBox(height: 40),
            _buildLogoutButton(context, theme),
            const SizedBox(height: 16),
            _buildDeleteAccountButton(context, theme),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 104), // Padding to clear bottom nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, BuildContext context) {
    final authState = ref.watch(authProvider);
    UserModel? user;
    if (authState is Authenticated) {
      user = authState.user;
    }

    final displayName = user?.fullName ?? _name;
    final displayPhone = user?.phoneNumber ?? _phone;
    final profileUrl = user?.profileImageUrl;
    final age = user?.age;
    final sex = user?.sex;

    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: AppColors.pujaRed.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                  border: Border.all(color: Colors.white, width: 4),
                  image: _profileImagePath != null
                      ? DecorationImage(
                          image: FileImage(File(_profileImagePath!)),
                          fit: BoxFit.cover,
                        )
                      : profileUrl != null
                          ? DecorationImage(
                              image: NetworkImage(profileUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: _profileImagePath == null && profileUrl == null
                    ? const Center(
                        child: Icon(Icons.person, size: 40, color: AppColors.antiqueGold),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.pujaRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 28), // Balances the edit icon on the right
            Text(
              displayName,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showEditProfileSheet,
              child: const Icon(Icons.edit, size: 20, color: AppColors.pujaRed),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          displayPhone,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        if (age != null || sex != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.antiqueGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              [if (sex != null) sex, if (age != null) '$age yrs'].join(' • '),
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.antiqueGold, fontWeight: FontWeight.bold),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (!isDark) BoxShadow(color: AppColors.deepMaroon.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(theme, '12', 'Saved'),
            Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
            _buildStatItem(theme, '3', 'Routes'),
            Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
            _buildStatItem(theme, '8', 'Reviews'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.pujaRed),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAddressMapCard(String address, ThemeData theme, bool isDark) {
    return FutureBuilder<List<Location>>(
      future: Geocoding().locationFromAddress(address).catchError((_) => <Location>[]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.pujaRed)),
          );
        }
        
        LatLng center = const LatLng(22.5726, 88.3639); // Default Kolkata
        bool found = false;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          center = LatLng(snapshot.data!.first.latitude, snapshot.data!.first.longitude);
          found = true;
        }

        return Container(
          margin: const EdgeInsets.only(left: 24, right: 24, top: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoal : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark) BoxShadow(color: AppColors.deepMaroon.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.pujaRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: center, zoom: 14.0),
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    markers: found ? {
                      Marker(
                        markerId: const MarkerId('center'),
                        position: center,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      )
                    } : {},
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildMenuItem(context, theme, Icons.route, 'My Puja Plans', isDark, onTap: () {
            context.push('/plan');
          }),
          _buildMenuItem(context, theme, Icons.confirmation_number_outlined, 'My Passes', isDark, onTap: () {
            context.push('/my-passes');
          }),
          _buildMenuItem(context, theme, Icons.privacy_tip_outlined, 'Privacy Policy', isDark, onTap: () {
            context.push('/privacy');
          }),
          _buildMenuItem(context, theme, Icons.gavel, 'Terms of Service', isDark, onTap: () {
            context.push('/terms');
          }),
          _buildMenuItem(context, theme, Icons.info_outline, 'About Us', isDark, onTap: () {
            context.push('/about-us');
          }),
          _buildMenuItem(context, theme, Icons.help_outline, 'Help & Support', isDark, onTap: () {
            _showSupportBottomSheet(context, theme, isDark);
          }),
        ],
      ),
    );
  }

  void _showSupportBottomSheet(BuildContext context, ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141414) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: AppColors.pujaRed.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.pujaRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent, color: AppColors.pujaRed, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Support',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: isDark ? AppColors.pureWhite : AppColors.deepMaroon,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We\'re here to help you 24/7',
                        style: TextStyle(color: isDark ? AppColors.antiqueGold : AppColors.pujaRed, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fade(duration: 400.ms).slideY(begin: 0.2),
            const SizedBox(height: 32),
            Text(
              'Need help with PUJA24? Reach out to the Naiyo24 team directly through any of the channels below.',
              style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 32),
            _buildSupportRow(Icons.language, 'Visit Our Website', 'naiyo24.com', isDark, () async {
              final url = Uri.parse('https://naiyo24.com');
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open website.')));
              }
            }).animate().fade(delay: 300.ms).slideX(begin: 0.1),
            const SizedBox(height: 12),
            _buildSupportRow(Icons.phone_outlined, 'Call Support', '+91 6289171798', isDark, () async {
              final url = Uri.parse('tel:+916289171798');
              try {
                await launchUrl(url);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open phone dialer.')));
              }
            }).animate().fade(delay: 400.ms).slideX(begin: 0.1),
            const SizedBox(height: 12),
            _buildSupportRow(Icons.email_outlined, 'Email Us', 'services.naiyo@gmail.com', isDark, () async {
              final url = Uri.parse('mailto:services.naiyo@gmail.com');
              try {
                await launchUrl(url);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email app.')));
              }
            }).animate().fade(delay: 500.ms).slideX(begin: 0.1),
            const SizedBox(height: 40),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSupportRow(IconData icon, String label, String value, bool isDark, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.antiqueGold, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: isDark ? AppColors.pureWhite : AppColors.deepMaroon,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: isDark ? Colors.white54 : Colors.black54,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, ThemeData theme, IconData icon, String title, bool isDark, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark) BoxShadow(color: AppColors.deepMaroon.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: isDark ? AppColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.antiqueGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.antiqueGold, size: 22),
        ),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.charcoal)),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
          icon: const Icon(Icons.logout, color: AppColors.errorRed),
          label: const Text(
            'Logout',
            style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.errorRed.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () {
            _showDeleteAccountDialog(context);
          },
          icon: const Icon(Icons.delete_forever, color: AppColors.errorRed),
          label: const Text(
            'Delete Account',
            style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.errorRed.withOpacity(0.3), width: 1),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to completely delete your account? This action cannot be undone and all your data will be permanently removed.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.go('/login'); // Navigate to login as if deleted
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
