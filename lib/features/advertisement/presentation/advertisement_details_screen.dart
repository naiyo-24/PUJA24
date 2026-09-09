import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/theme/app_colors.dart';

class AdvertisementDetailsScreen extends StatefulWidget {
  const AdvertisementDetailsScreen({super.key});

  @override
  State<AdvertisementDetailsScreen> createState() => _AdvertisementDetailsScreenState();
}

class _AdvertisementDetailsScreenState extends State<AdvertisementDetailsScreen> {
  bool _isOpeningPdf = false;

  Future<void> _openPdf() async {
    if (_isOpeningPdf) return;
    setState(() => _isOpeningPdf = true);

    try {
      // Load PDF from assets
      final byteData = await rootBundle.load('assets/LED BRANDING PROPOSAL 2026 NEW.pdf');
      
      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/LED_BRANDING_PROPOSAL_2026.pdf');
      
      // Write to file
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      
      // Open file
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningPdf = false);
    }
  }

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
            // Poster Image
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/LED.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              '20 Days Brand Visibility',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Your brand deserves the spotlight. Get exclusive LED Screen Branding across 9 popular locations in Kolkata during the festive season.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 24),
            
            // Campaign Details
            _buildBenefitItem(context, Icons.calendar_month, 'Campaign Period', '3 Oct 2026 to 22 Oct 2026 (Total 20 Days)'),
            const SizedBox(height: 12),
            _buildBenefitItem(context, Icons.access_time, 'Display Timing', '3 Oct - 12 Oct: 8 AM to 12 Midnight (16 Hours)\n13 Oct - 22 Oct: 11 AM to 5 AM (18 Hours)'),
            const SizedBox(height: 12),
            _buildBenefitItem(context, Icons.repeat, 'Branding Details', 'Loop Duration: 6 Minutes\nAd Duration: 10 Seconds\nValue: Rs. 8,50,000/- + GST'),
            const SizedBox(height: 24),

            Text(
              '9 Popular Locations',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLocationItem(context, '1. Dhakuria Bridge (Opp. Dakshinapan)'),
            _buildLocationItem(context, '2. Opposite Lake Mall'),
            _buildLocationItem(context, '3. Hindusthan Park, Gariahat'),
            _buildLocationItem(context, '4. Acropolis Mall, Kasba'),
            _buildLocationItem(context, '5. Behala 14 No Bus Stand'),
            _buildLocationItem(context, '6. Khanna More'),
            _buildLocationItem(context, '7. Sovabazar Crossing'),
            _buildLocationItem(context, '8. Shyambazar 5 Points Crossing'),
            _buildLocationItem(context, '9. Sealdah Station, Prachi Cinema'),
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
                  _isOpeningPdf 
                    ? const CircularProgressIndicator(color: AppColors.pujaRed)
                    : ElevatedButton.icon(
                        onPressed: _openPdf,
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

  Widget _buildBenefitItem(BuildContext context, IconData icon, String title, String description) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.pujaRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.pujaRed, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationItem(BuildContext context, String locationName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: AppColors.pujaRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              locationName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
