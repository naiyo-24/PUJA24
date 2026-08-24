import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shell/app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final bool isKeyboardOpen = viewInsets.bottom > 0;
    
    // Calculate the absolute screen height (ignoring keyboard reduction) so the layout doesn't jump
    final double absoluteScreenHeight = MediaQuery.of(context).size.height + viewInsets.bottom;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.deepMaroon,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/login.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Dark overlay when keyboard is open to make text readable
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: isKeyboardOpen ? Colors.black.withOpacity(0.7) : Colors.transparent,
            ),
          ),
          
          // Form Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Animate the spacing to smoothly move the form slightly up
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              height: isKeyboardOpen ? absoluteScreenHeight * 0.18 : absoluteScreenHeight * 0.38,
                            ),
                            
                            // Logo always visible but shrinks slightly
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              height: isKeyboardOpen ? 55 : 90,
                              child: Image.asset(
                                'assets/logo.png',
                                errorBuilder: (context, error, stackTrace) => 
                                  Text('PUJA24', style: theme.textTheme.displayMedium?.copyWith(color: AppColors.antiqueGold)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            Text(
                              'Welcome Back!',
                              style: theme.textTheme.displaySmall?.copyWith(color: AppColors.ivory, fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue your spiritual journey',
                              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray, fontSize: 12),
                            ),
                            const SizedBox(height: 20),
                            
                            if (!isKeyboardOpen) ...[
                              // Google Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Navigate straight to profile creation for Google Login
                                    context.go('/create_profile', extra: {
                                      'loginMethod': 'google',
                                      'name': 'Sayar Paul', // Mock fetched name
                                      'photoUrl': 'https://ui-avatars.com/api/?name=Sayar+Paul&background=C62828&color=fff', // Mock Google photo
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.ivory,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset('assets/icons/social/google.png', height: 22, width: 22),
                                      const SizedBox(width: 12),
                                      const Text('Continue with Google', style: TextStyle(color: AppColors.charcoal, fontSize: 14, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: AppColors.antiqueGold.withOpacity(0.3))),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('or', style: TextStyle(color: AppColors.mutedGray, fontSize: 11)),
                                  ),
                                  Expanded(child: Divider(color: AppColors.antiqueGold.withOpacity(0.3))),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                            ],
                            
                            // Phone Number Input
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.antiqueGold.withOpacity(0.5)),
                                color: Colors.transparent,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone_android, color: AppColors.antiqueGold, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('+91', style: TextStyle(color: AppColors.ivory, fontSize: 14)),
                                  const Icon(Icons.keyboard_arrow_down, color: AppColors.ivory, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      style: const TextStyle(color: AppColors.ivory, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'Mobile Number',
                                        hintStyle: TextStyle(color: AppColors.mutedGray.withOpacity(0.8), fontSize: 14),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        fillColor: Colors.transparent,
                                        counterText: "",
                                      ),
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      maxLength: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Get OTP Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to OTP screen with phone number
                                  final phone = _phoneController.text.trim();
                                  if (phone.length == 10) {
                                    context.push('/otp', extra: {'phone': phone});
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a valid 10-digit number')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.pujaRed,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: BorderSide(color: AppColors.antiqueGold.withOpacity(0.5)),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Get OTP', style: TextStyle(color: AppColors.ivory, fontSize: 15, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.ivory),
                                  ],
                                ),
                              ),
                            ),
                            
                            const Spacer(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.antiqueGold.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
