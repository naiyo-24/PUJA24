import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/presentation/providers/pass_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/widgets/native_ad_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MyPassesScreen extends ConsumerWidget {
  const MyPassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bgColor = Color(0xFF090909);
    const goldColor = Color(0xFFD4A24C);
    
    final vouchersState = ref.watch(myVouchersProvider);
    final packagesState = ref.watch(availablePassesProvider);
    final authState = ref.watch(authProvider);
    final userName = authState is Authenticated ? authState.user.fullName : 'Guest';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Passes', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: vouchersState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
        error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
        data: (vouchers) {
          if (vouchers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.airplane_ticket_outlined, color: Colors.white.withOpacity(0.5), size: 64),
                  const SizedBox(height: 16),
                  const Text('No Passes Found', style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('You haven\'t purchased any passes yet.', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  const SizedBox(height: 48),
                  NativeAdWidget(height: 320, adUnitId: Platform.isAndroid ? dotenv.env['ADMOB_NATIVE_MYPASSES_ANDROID'] : dotenv.env['ADMOB_NATIVE_MYPASSES_IOS']),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: goldColor,
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(myVouchersProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(24.0),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: vouchers.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                if (index == vouchers.length) {
                  return NativeAdWidget(height: 320, adUnitId: Platform.isAndroid ? dotenv.env['ADMOB_NATIVE_MYPASSES_ANDROID'] : dotenv.env['ADMOB_NATIVE_MYPASSES_IOS']);
                }
                final voucher = vouchers[index];
                final isRedeemed = voucher.status.toLowerCase() == 'redeemed';
                
                final packages = packagesState.valueOrNull ?? [];
                final package = packages.where((p) => p.id == voucher.packageId).firstOrNull;
                final collectionVenue = package?.collectionVenue ?? 'PUJO24 HQ, Park Street, Kolkata';

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: goldColor.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        child: Image.asset(
                          'assets/images/banner.png',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'VIP Puja Pass',
                                  style: TextStyle(
                                    color: goldColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isRedeemed ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isRedeemed ? Colors.red : Colors.green),
                                  ),
                                  child: Text(
                                    isRedeemed ? 'REDEEMED' : 'ACTIVE',
                                    style: TextStyle(
                                      color: isRedeemed ? Colors.red : Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Purchased: ${DateFormat('MMM d, yyyy').format(voucher.createdAt)}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Order ID: ${voucher.paymentReference}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                            const SizedBox(height: 24),
                            
                            // Open Details Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isRedeemed ? null : () => _showPassDetailsSheet(context, goldColor, voucher.voucherCode, voucher.paymentReference, userName),
                                icon: Icon(isRedeemed ? Icons.check_circle : Icons.qr_code_scanner, color: isRedeemed ? Colors.white54 : Colors.black),
                                label: Text(
                                  isRedeemed ? 'Pass Redeemed' : 'View Pass & QR Code',
                                  style: TextStyle(color: isRedeemed ? Colors.white54 : Colors.black, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isRedeemed ? Colors.grey[800] : goldColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (package != null) ...[
                                      const Text(
                                        'Collection Venues (Show this screen at the counter):',
                                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      if (package.collectionVenue.isNotEmpty) ...[
                                        Text(
                                          '1. ${package.collectionVenue}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                        ),
                                        if (package.collectionVenueMapUrl != null && package.collectionVenueMapUrl!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () async {
                                              final url = Uri.parse(package.collectionVenueMapUrl!);
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url);
                                              }
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.map, size: 16, color: goldColor),
                                                const SizedBox(width: 6),
                                                Text('View on Map', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                      if (package.collectionVenue2 != null && package.collectionVenue2!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          '2. ${package.collectionVenue2}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                        ),
                                        if (package.collectionVenueMapUrl2 != null && package.collectionVenueMapUrl2!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () async {
                                              final url = Uri.parse(package.collectionVenueMapUrl2!);
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url);
                                              }
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.map, size: 16, color: goldColor),
                                                const SizedBox(width: 6),
                                                Text('View on Map', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                      if (package.collectionInfoNote != null && package.collectionInfoNote!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          package.collectionInfoNote!,
                                          style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ] else ...[
                                      const Text(
                                        'Collection Venue: PUJO24 HQ, Park Street, Kolkata. Show this screen at the counter.',
                                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          );
        },
      ),
    );
  }

  void _showPassDetailsSheet(BuildContext context, Color goldColor, String voucherCode, String paymentReference, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 32),
            const Text('VIP DIGITAL PASS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Scan this QR code at the collection counter', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 40),
            
            // White QR Code Box
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: goldColor.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: QrImageView(
                data: voucherCode,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Pass Info Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildDetailRow('Pass Holder', userName, goldColor),
                  const SizedBox(height: 16),
                  _buildDetailRow('Admit', '4 Persons', goldColor),
                  const SizedBox(height: 16),
                  _buildDetailRow('Pass ID', voucherCode.substring(0, 8).toUpperCase(), goldColor),
                  const SizedBox(height: 16),
                  _buildDetailRow('Status', 'NOT REDEEMED', Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 16)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
