import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:durga_puja_explorer/core/theme/app_colors.dart';

class ProfileCreationScreen extends StatefulWidget {
  final String loginMethod; // 'phone' or 'google'
  final String? prefilledPhone;
  final String? prefilledName;
  final String? prefilledPhotoUrl;

  const ProfileCreationScreen({
    super.key,
    this.loginMethod = 'phone',
    this.prefilledPhone,
    this.prefilledName,
    this.prefilledPhotoUrl,
  });

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _ageController;
  
  // State
  String? _selectedSex;
  final Set<String> _selectedPandals = {};
  File? _profileImage;
  bool _pandalsError = false;
  bool _isFetchingLocation = false;

  // Animation
  late AnimationController _animController;

  final List<String> _pandalOptions = [
    'North Kolkata',
    'South Kolkata',
    'Salt Lake',
    'Traditional',
    'Theme-based',
    'Lighting-focused',
    'Award-winning',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefilledName);
    _phoneController = TextEditingController(text: widget.prefilledPhone);
    _addressController = TextEditingController();
    _ageController = TextEditingController();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Location Methods
  Future<void> _showLocationDisclosure() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _fetchLocation();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse || permission == LocationPermission.deniedForever) {
      _fetchLocation();
      return;
    }

    final bool? accept = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.pujaRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location, color: AppColors.pujaRed, size: 40),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Use your location',
                    style: TextStyle(color: AppColors.charcoal, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PUJA24 requires your location to automatically fetch your address, recommend nearby pandals, and help you navigate safely during the festivities.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Not now', style: TextStyle(color: AppColors.mutedGray, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.pujaRed,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Allow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );

    if (accept == true) {
      _fetchLocation();
    }
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      } 

      // Permission granted, navigate to map picker and await result
      final selectedLocation = await context.push<LatLng>('/map_picker');
      
      if (selectedLocation != null) {
        setState(() {
          _isFetchingLocation = true; // Show loading while geocoding
        });
        
        List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(selectedLocation.latitude, selectedLocation.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
          // Clean up leading commas if any fields were empty
          address = address.replaceAll(RegExp(r'^,\s*'), '').replaceAll(RegExp(r',\s*,'), ',');
          
          setState(() {
            _addressController.text = address;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.pujaRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  void _submitProfile() {
    setState(() {
      _pandalsError = _selectedPandals.isEmpty;
    });

    if (_formKey.currentState!.validate() && !_pandalsError) {
      // Navigate to home on success
      context.go('/explore');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please fill all required fields', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppColors.pujaRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final double start = (index * 0.1).clamp(0.0, 1.0);
    final double end = (start + 0.4).clamp(0.0, 1.0);
    
    final animation = CurvedAnimation(
      parent: _animController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.antiqueGold, AppColors.pujaRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pujaRed.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
            Container(
              width: 124,
              height: 124,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: ClipOval(
                  child: Container(
                    color: Colors.grey.shade100,
                    child: _profileImage != null
                        ? Image.file(_profileImage!, fit: BoxFit.cover)
                        : widget.prefilledPhotoUrl != null
                            ? Image.network(
                                widget.prefilledPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: Colors.grey),
                              )
                            : Icon(Icons.person, size: 60, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.pujaRed, AppColors.deepMaroon],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhoneLogin = widget.loginMethod == 'phone';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.charcoal, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedItem(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set up your Profile',
                        style: theme.textTheme.displayMedium?.copyWith(color: AppColors.charcoal, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Personalize your Puja24 experience.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                  0,
                ),
                const SizedBox(height: 40),
                
                _buildAnimatedItem(_buildProfileImage(), 1),
                const SizedBox(height: 40),
                
                // Full Name
                _buildAnimatedItem(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Full Name'),
                      _buildPremiumTextField(
                        controller: _nameController,
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                  2,
                ),
                const SizedBox(height: 24),
                
                // Phone Number
                _buildAnimatedItem(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Phone Number'),
                      _buildPremiumTextField(
                        controller: _phoneController,
                        hint: '10-digit mobile number',
                        icon: Icons.phone_android,
                        readOnly: isPhoneLogin,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 10,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length != 10) return 'Must be 10 digits';
                          return null;
                        },
                      ),
                    ],
                  ),
                  3,
                ),
                const SizedBox(height: 24),

                // Address
                _buildAnimatedItem(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Address'),
                      _buildPremiumTextField(
                        controller: _addressController,
                        hint: 'Enter your address',
                        icon: Icons.location_on_outlined,
                        suffixIcon: _isFetchingLocation 
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pujaRed),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.my_location, color: AppColors.pujaRed),
                                onPressed: _showLocationDisclosure,
                              ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                  4,
                ),
                const SizedBox(height: 24),

                // Age & Sex Row
                _buildAnimatedItem(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Age'),
                            _buildPremiumTextField(
                              controller: _ageController,
                              hint: 'Age',
                              icon: null,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Sex'),
                            DropdownButtonFormField<String>(
                              value: _selectedSex,
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 4,
                              validator: (value) => value == null ? 'Required' : null,
                              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.pujaRed),
                              decoration: InputDecoration(
                                hintText: 'Select',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.pujaRed, width: 1.5)),
                                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade300, width: 1)),
                              ),
                              items: ['Male', 'Female', 'Other', 'Prefer not to say']
                                  .map((sex) => DropdownMenuItem(value: sex, child: Text(sex, style: const TextStyle(color: AppColors.charcoal, fontSize: 15))))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSex = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  5,
                ),
                const SizedBox(height: 32),

                // Interested Pandals (Chips)
                _buildAnimatedItem(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Interested Pandals (Select at least 1)'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: _pandalOptions.map((option) {
                          final isSelected = _selectedPandals.contains(option);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              gradient: isSelected ? const LinearGradient(colors: [AppColors.pujaRed, AppColors.deepMaroon]) : null,
                              color: isSelected ? null : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: AppColors.pujaRed.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                                  : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                              border: isSelected ? null : Border.all(color: Colors.grey.shade200, width: 1),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedPandals.remove(option);
                                  } else {
                                    _selectedPandals.add(option);
                                  }
                                  _pandalsError = _selectedPandals.isEmpty;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.charcoal,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_pandalsError)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0, left: 4.0),
                          child: Text('Please select at least one interest', style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  6,
                ),
                const SizedBox(height: 48),
                
                // Submit Button
                _buildAnimatedItem(
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [AppColors.pujaRed, AppColors.deepMaroon],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pujaRed.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: const Text('Complete Profile', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                  7,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.charcoal,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    Widget? suffixIcon,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        validator: validator,
        style: TextStyle(color: readOnly ? Colors.grey.shade600 : AppColors.charcoal, fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
          prefixIcon: icon != null ? Icon(icon, color: readOnly ? Colors.grey.shade400 : AppColors.pujaRed, size: 22) : null,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          counterText: "",
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.pujaRed, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade300, width: 1)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade300, width: 1.5)),
        ),
      ),
    );
  }
}
