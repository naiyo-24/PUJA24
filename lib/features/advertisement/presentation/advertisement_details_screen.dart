import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class AdvertisementDetailsScreen extends StatelessWidget {
  const AdvertisementDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.deepMaroon : AppColors.ivory,
      appBar: AppBar(
        title: const Text('Advertise With Us'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Image Placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.pujaRed, AppColors.saffron],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_rounded, size: 64, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Your Advertisement Here',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Reach Millions of Puja Hoppers',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'If you want to add an advertisement on the road for the Puja, or showcase your brand directly inside the PUJA24 application, you can partner with us!\n\nWe offer prime road-side banner placements as well as digital in-app promotions to give your brand maximum visibility during the festival season.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 32),
            
            // PDF Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Media Kit & Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Download our brochure for full details', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement PDF viewing/downloading here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF Viewer will open here')),
                      );
                    },
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text('View PDF Brochure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pujaRed,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Contact Details
            const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: AppColors.saffron, child: Icon(Icons.phone, color: Colors.white)),
              title: const Text('+91 98765 43210'),
              subtitle: const Text('Call us for bookings'),
              onTap: () {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: AppColors.saffron, child: Icon(Icons.email, color: Colors.white)),
              title: const Text('ads@puja24.com'),
              subtitle: const Text('Email us for inquiries'),
              onTap: () {},
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
