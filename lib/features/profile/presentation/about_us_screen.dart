import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = const Color(0xFFD4A24C);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090909) : AppColors.ivory,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: isDark ? const Color(0xFF090909).withOpacity(0.9) : AppColors.ivory.withOpacity(0.9),
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'About Us',
              style: TextStyle(
                color: goldColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Info Section
                  Center(
                    child: Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'assets/logo.png',
                        width: 140,
                        fit: BoxFit.contain,
                      ).animate().fade(duration: 600.ms).scale(curve: Curves.easeOutBack),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: goldColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: goldColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Your Ultimate Durga Puja Companion',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: goldColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                  ),
                  const SizedBox(height: 40),
                  
                  _buildSectionTitle('About PUJA24', isDark).animate().fade(delay: 300.ms),
                  const SizedBox(height: 16),
                  Text(
                    'PUJA24 is the complete solution for experiencing Kolkata Durga Puja seamlessly. With curated pandal routes, exclusive VIP passes, and smart digital navigation, we bring the best of the festival directly to your fingertips.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ).animate().fade(delay: 400.ms),
                  
                  const SizedBox(height: 40),
                  Divider(color: goldColor.withOpacity(0.2), thickness: 1).animate().fade(delay: 500.ms),
                  const SizedBox(height: 40),

                  // Developer Info Section
                  _buildSectionTitle('Developed By', isDark).animate().fade(delay: 500.ms),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141414) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pujaRed.withOpacity(isDark ? 0.05 : 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/naiyo24_logo.jpeg',
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'NAIYO24 PVT LTD',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.pujaRed,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We build premium websites, mobile apps, AI products, cloud solutions, branding, and marketing for startups and enterprises.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? Colors.white60 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 600.ms).slideY(begin: 0.1, curve: Curves.easeOut),
                  
                  const SizedBox(height: 32),

                  // Contact Info Cards
                  _buildContactCard(
                    context,
                    icon: Icons.person_outline,
                    title: 'CEO & Founder',
                    value: 'Debasish Baidya',
                    isDark: isDark,
                  ).animate().fade(delay: 700.ms).slideX(begin: 0.1),
                  
                  const SizedBox(height: 12),
                  
                  _buildContactCard(
                    context,
                    icon: Icons.phone_outlined,
                    title: 'Phone Support',
                    value: '+91 6289171798',
                    isDark: isDark,
                    onTap: () => _launchUrl(context, 'tel:+916289171798'),
                  ).animate().fade(delay: 800.ms).slideX(begin: 0.1),
                  
                  const SizedBox(height: 12),
                  
                  _buildContactCard(
                    context,
                    icon: Icons.email_outlined,
                    title: 'Business Inquiries',
                    value: 'services.naiyo@gmail.com',
                    isDark: isDark,
                    onTap: () => _launchUrl(context, 'mailto:services.naiyo@gmail.com'),
                  ).animate().fade(delay: 900.ms).slideX(begin: 0.1),
                  
                  const SizedBox(height: 12),
                  
                  _buildContactCard(
                    context,
                    icon: Icons.language,
                    title: 'Our Website',
                    value: 'https://naiyo24.com',
                    isDark: isDark,
                    onTap: () => _launchUrl(context, 'https://naiyo24.com'),
                  ).animate().fade(delay: 1000.ms).slideX(begin: 0.1),
                  
                  const SizedBox(height: 48),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite, color: AppColors.pujaRed, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'Made with love in Kolkata',
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 1200.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.antiqueGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    VoidCallback? onTap,
  }) {
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
                      title,
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
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
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
}
