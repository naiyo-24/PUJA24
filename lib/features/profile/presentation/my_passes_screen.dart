import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/presentation/providers/pass_provider.dart';

class MyPassesScreen extends ConsumerWidget {
  const MyPassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bgColor = Color(0xFF090909);
    const goldColor = Color(0xFFD4A24C);
    
    final vouchersState = ref.watch(myVouchersProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            itemCount: vouchers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
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
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
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
                              onPressed: () => _showPassDetailsSheet(context, goldColor, voucher.voucherCode, voucher.paymentReference),
                              icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                              label: const Text(
                                'View Pass & QR Code',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: goldColor,
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
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Collection Venue: PUJA24 HQ, Park Street, Kolkata. Show this screen at the counter.',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
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
          );
        },
      ),
    );
  }

  void _showPassDetailsSheet(BuildContext context, Color goldColor, String voucherCode, String paymentReference) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
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
                  _buildDetailRow('Pass Holder', 'Primary User', goldColor),
                  const SizedBox(height: 16),
                  _buildDetailRow('Admit', '3 Persons', goldColor),
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
