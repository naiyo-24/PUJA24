import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.charcoal : AppColors.ivory;
    final textColor = isDark ? AppColors.pureWhite : AppColors.deepMaroon;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Terms of Service', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
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
                child: const Icon(Icons.gavel, size: 64, color: AppColors.pujaRed),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 32),
            Text(
              'Terms & Conditions',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut),
            const SizedBox(height: 8),
            Text(
              'Effective Date: October 2026',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            
            _buildSection(
              theme,
              title: '1. Acceptance of Terms',
              content: 'By accessing and using the PUJA24 application, you accept and agree to be bound by the terms and provisions of this agreement. If you do not agree to abide by these terms, please do not use this application.',
              delayMs: 400,
              textColor: textColor,
            ),
            _buildSection(
              theme,
              title: '2. User Conduct',
              content: 'You agree not to use the application for any unlawful purpose. You may not post reviews or photos that are offensive, discriminatory, or violate the rights of any third party. We reserve the right to remove any content at our discretion.',
              delayMs: 500,
              textColor: textColor,
            ),
            _buildSection(
              theme,
              title: '3. Intellectual Property',
              content: 'All original content, features, and functionality of this app (including but not limited to text, graphics, logos, and software) are owned by PUJA24 and are protected by international copyright and intellectual property laws.',
              delayMs: 600,
              textColor: textColor,
            ),
            _buildSection(
              theme,
              title: '4. Limitation of Liability',
              content: 'PUJA24 serves as a guide for navigating Durga Puja in Kolkata. We are not liable for any changes to pandal schedules, crowd density inaccuracies, or physical injuries incurred while navigating the city.',
              delayMs: 700,
              textColor: textColor,
            ),
            const SizedBox(height: 40),
            
            Center(
              child: ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.handshake),
                label: const Text('I Agree to the Terms'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.antiqueGold,
                  foregroundColor: Colors.black,
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
