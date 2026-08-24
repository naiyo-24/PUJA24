import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:durga_puja_explorer/core/theme/app_colors.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  
  const OtpScreen({
    super.key,
    required this.phone,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  int _timerCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _timerCountdown = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerCountdown > 0) {
        setState(() {
          _timerCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final bool isKeyboardOpen = viewInsets.bottom > 0;
    
    // Calculate the absolute screen height (ignoring keyboard reduction) so the layout doesn't jump
    final double absoluteScreenHeight = MediaQuery.of(context).size.height + viewInsets.bottom;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.deepMaroon,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/login.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Dark overlay when keyboard is open to make text readable
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: isKeyboardOpen ? Colors.black.withOpacity(0.7) : Colors.transparent,
            ),
          ),
          
          // Form Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Animate the spacing to smoothly move the form slightly up
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              height: isKeyboardOpen ? absoluteScreenHeight * 0.18 : absoluteScreenHeight * 0.38,
                            ),
                            
                            // Logo always visible but shrinks slightly
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              height: isKeyboardOpen ? 55 : 90,
                              child: Image.asset(
                                'assets/logo.png',
                                errorBuilder: (context, error, stackTrace) => 
                                  Text('PUJA24', style: theme.textTheme.displayMedium?.copyWith(color: AppColors.antiqueGold)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            Text(
                              'Verification',
                              style: theme.textTheme.displaySmall?.copyWith(color: AppColors.ivory, fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code sent to +91 ${widget.phone}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray, fontSize: 13),
                            ),
                            const SizedBox(height: 32),
                            
                            // OTP Input Fields
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(4, (index) => _OtpInputBox()),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Verify Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to profile creation after successful OTP
                                  context.go('/create_profile', extra: {
                                    'loginMethod': 'phone',
                                    'phone': widget.phone, // Real passed phone
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.pujaRed,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: BorderSide(color: AppColors.antiqueGold.withOpacity(0.5)),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Verify & Continue', style: TextStyle(color: AppColors.ivory, fontSize: 15, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.ivory),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Didn't receive the code? ", style: TextStyle(color: AppColors.mutedGray, fontSize: 12)),
                                GestureDetector(
                                  onTap: _timerCountdown == 0 ? _startTimer : null,
                                  child: Text(
                                    _timerCountdown > 0 ? 'Resend in ${_timerCountdown}s' : 'Resend',
                                    style: TextStyle(
                                      color: _timerCountdown > 0 ? AppColors.mutedGray : AppColors.antiqueGold,
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 12
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const Spacer(),
                            
                            // Back Button
                            if (!isKeyboardOpen)
                              TextButton.icon(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/login');
                                  }
                                },
                                icon: const Icon(Icons.arrow_back, color: AppColors.antiqueGold, size: 16),
                                label: const Text('Back to Login', style: TextStyle(color: AppColors.antiqueGold, fontSize: 12)),
                              ),
                            
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpInputBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.antiqueGold.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.antiqueGold.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: AppColors.ivory, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
        keyboardType: TextInputType.number,
        maxLength: 1,
        cursorColor: AppColors.antiqueGold,
        cursorHeight: 28,
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            FocusScope.of(context).nextFocus();
          } else {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }
}
