import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'profile_creation_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is Authenticated) {
        if (next.isNewUser) {
           context.go('/create_profile');
        } else {
           context.go('/explore');
        }
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

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
                              height: absoluteScreenHeight * 0.55,
                            ),
                            
                            // Logo always visible but shrinks slightly
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              height: 90,
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
                            
                            // Google Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: authState is AuthLoading 
                                ? const Center(child: CircularProgressIndicator(color: AppColors.ivory))
                                : ElevatedButton(
                                  onPressed: () {
                                    ref.read(authProvider.notifier).signInWithGoogle();
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
