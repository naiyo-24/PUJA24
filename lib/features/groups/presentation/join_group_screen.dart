import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../data/groups_api_service.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  final String? inviteLink;
  const JoinGroupScreen({super.key, this.inviteLink});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final TextEditingController _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isLoading = false;
  bool _isScannerActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.inviteLink != null && widget.inviteLink!.isNotEmpty) {
      _codeController.text = widget.inviteLink!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _joinWithCode(String code) async {
    if (code.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code'), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group?'),
        content: Text('Are you sure you want to join the group with invite code $code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pujaRed),
            child: const Text('Join', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    final success = await ref.read(groupsApiServiceProvider).joinGroup(code);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ref.invalidate(myGroupsProvider);
        try { await ref.read(myGroupsProvider.future); } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined Group Successfully!'), backgroundColor: AppColors.successGreen),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join group. Check the code and try again.'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.ivory,
      appBar: AppBar(
        title: const Text('Join Group', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.charcoal : AppColors.ivory,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner_rounded, size: 80, color: AppColors.pujaRed),
            const SizedBox(height: 16),
            const Text(
              'Join your friends',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit invite code or scan the group QR code to hop in!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 48),

            // Text Input for Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invite Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: 'e.g. A1B2C3',
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _joinWithCode(_codeController.text.toUpperCase()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pujaRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Join Group', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('OR SCAN QR', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
            const SizedBox(height: 32),

            // QR Scanner Area
            if (_isScannerActive)
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.pujaRed, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          _scannerController.stop();
                          setState(() => _isScannerActive = false);
                          _joinWithCode(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  setState(() => _isScannerActive = true);
                  _scannerController.start();
                },
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.grey[500]),
                      const SizedBox(height: 8),
                      Text('Tap to open camera', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
