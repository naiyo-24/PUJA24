import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class RedeemedPassScreen extends StatelessWidget {
  final String passId;

  const RedeemedPassScreen({
    super.key,
    required this.passId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.ivory,
      appBar: AppBar(
        title: const Text('Your VIP Pass', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepMaroon,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ticket Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top Gold Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: const BoxDecoration(
                          color: AppColors.antiqueGold,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.stars_rounded, size: 48, color: AppColors.deepMaroon),
                            const SizedBox(height: 8),
                            const Text(
                              'VIP PASS',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepMaroon,
                                letterSpacing: 4,
                              ),
                            ),
                            Text(
                              'PUJA 2026',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepMaroon.withOpacity(0.7),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Perforated Line Effect
                      Row(
                        children: [
                          _buildHole(isDark),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                    (constraints.constrainWidth() / 15).floor(),
                                    (index) => SizedBox(
                                      width: 8,
                                      height: 2,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4)),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          _buildHole(isDark),
                        ],
                      ),
                      
                      // QR Code Section
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.antiqueGold.withOpacity(0.3), width: 2),
                              ),
                              child: QrImageView(
                                data: passId,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: AppColors.deepMaroon,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'ID: ${passId.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Present this QR code at any VIP Counter for scanning.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.deepMaroon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.deepMaroon.withOpacity(0.2)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.deepMaroon),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This pass allows fast-track entry for up to 4 people. Keep this screen open when approaching the counter.',
                          style: TextStyle(color: AppColors.deepMaroon, fontWeight: FontWeight.w500, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHole(bool isDark) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : AppColors.ivory,
        shape: BoxShape.circle,
      ),
    );
  }
}
