import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.charcoal : AppColors.ivory;
    final textColor = isDark ? AppColors.pureWhite : AppColors.deepMaroon;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Privacy Policy', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.privacy_tip_outlined, size: 64, color: AppColors.pujaRed),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 32),
            Text(
              'Your Privacy Matters',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut),
            const SizedBox(height: 8),
            Text(
              'Last updated: October 2026',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            
            _buildSection(
              theme,
              title: '1. Information We Collect',
              content: 'We collect personal information that you provide to us when you register for an account, such as your name, email address, and phone number. We also collect location data to provide you with nearby Puja pandal recommendations and accurate routing.',
              delayMs: 400,
              textColor: textColor,
            ),
            _buildSection(
              theme,
              title: '2. How We Use Your Information',
              content: 'Your information is used to personalize your experience, provide live crowd updates, and help you navigate the city efficiently during Durga Puja. We do not sell your personal data to third parties.',
              delayMs: 500,
              textColor: textColor,
            ),
            _buildSection(
              theme,
              title: '3. Data Security',
              content: 'We implement premium industry-standard security measures to ensure your data is safe. All location tracking is completely anonymous when shared for crowd density metrics.',
              delayMs: 600,
              textColor: textColor,
            ),
            _buildSection(
              theme,
              title: '4. Your Rights',
              content: 'You have the right to request deletion of your account and all associated data at any time through the Profile Settings. You may also disable location services at any time from your device settings.',
              delayMs: 700,
              textColor: textColor,
            ),
            const SizedBox(height: 40),
            
            Center(
              child: ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.check),
                label: const Text('I Understand'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pujaRed,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ).animate().fadeIn(delay: 800.ms).scale(curve: Curves.elasticOut),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, {required String title, required String content, required int delayMs, required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.antiqueGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: textColor.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ).animate().fadeIn(delay: delayMs.ms).slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
    );
  }
}
