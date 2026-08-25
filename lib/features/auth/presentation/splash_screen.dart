import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepMaroon,
      body: Stack(
        children: [
          // Full-screen background image with a glowing/shimmering effect
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash.png',
              fit: BoxFit.cover,
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .shimmer(duration: 2500.ms, color: Colors.white24, angle: 1.0) // A beautiful sweeping glass shine
            .fade(duration: 1000.ms, curve: Curves.easeIn), // Smooth fade in
          ),
          
          // Wave Animation and Loading Text at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Column(
              children: [
                // Stagger Wave Animation (vertical bars)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => Container(
                    width: 4,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: AppColors.pujaRed,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pujaRed.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  )).animate(interval: 150.ms, onPlay: (controller) => controller.repeat())
                  .scaleY(
                    begin: 0.3, 
                    end: 1.5, 
                    duration: 500.ms, 
                    curve: Curves.easeInOutSine,
                  )
                  .then(delay: 0.ms)
                  .scaleY(
                    begin: 1.5,
                    end: 0.3,
                    duration: 500.ms,
                    curve: Curves.easeInOutSine,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Loading Text
                Text(
                  'LOADING...',
                  style: const TextStyle(
                    color: AppColors.pujaRed,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .fade(begin: 0.3, end: 1.0, duration: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
