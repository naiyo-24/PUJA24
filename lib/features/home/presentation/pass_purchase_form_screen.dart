import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/pass_provider.dart';
import '../data/pass_repository.dart';

class PassPurchaseFormScreen extends ConsumerStatefulWidget {
  final String packageId;
  const PassPurchaseFormScreen({super.key, required this.packageId});

  @override
  ConsumerState<PassPurchaseFormScreen> createState() => _PassPurchaseFormScreenState();
}

class _PassPurchaseFormScreenState extends ConsumerState<PassPurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    // Auto-fill user details
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      _nameController.text = authState.user.fullName;
      _emailController.text = authState.user.email;
      _phoneController.text = authState.user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final authState = ref.read(authProvider);
    final token = (authState is Authenticated) ? authState.token : null;
    
    if (token != null && response.paymentId != null && response.orderId != null && response.signature != null) {
      final passRepo = ref.read(passRepositoryProvider);
      final verified = await passRepo.verifyPayment(response.paymentId!, response.orderId!, response.signature!, token);
      
      setState(() => _isProcessing = false);
      if (verified) {
        context.go('/payment-success', extra: response.orderId ?? response.paymentId ?? 'TXN_SUCCESS');
      } else {
        _showResultDialog('Verification Failed', 'Payment was successful but could not be verified on the server. Please contact support.', false);
      }
    } else {
      setState(() => _isProcessing = false);
      context.go('/payment-success', extra: response.orderId ?? response.paymentId ?? 'TXN_SUCCESS');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    _showResultDialog('Payment Failed', response.message ?? 'Something went wrong. Please try again.', false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    _showResultDialog('External Wallet Selected', 'Proceeding with ${response.walletName}', true);
  }

  void _showResultDialog(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (isSuccess) {
                context.go('/explore');
              }
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFD4A24C))),
          )
        ],
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);
      
      final authState = ref.read(authProvider);
      final token = (authState is Authenticated) ? authState.token : null;

      if (token == null) {
        setState(() => _isProcessing = false);
        _showResultDialog('Error', 'You must be logged in to purchase a pass.', false);
        return;
      }

      try {
        final passRepo = ref.read(passRepositoryProvider);
        final orderDetails = await passRepo.createOrder(widget.packageId, token);

        var options = {
          'key': orderDetails['key_id'],
          'amount': orderDetails['amount'],
          'order_id': orderDetails['gateway_order_id'],
          'name': 'PUJA24 VIP Pass',
          'description': 'Exclusive VIP Access',
          'prefill': {
            'contact': _phoneController.text.trim(),
            'email': _emailController.text.trim()
          }
        };

        _razorpay.open(options);
      } catch (e) {
        setState(() => _isProcessing = false);
        _showResultDialog('Error', 'Failed to create order on server: $e', false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF090909);
    const goldColor = Color(0xFFD4A24C);
    
    final passesState = ref.watch(availablePassesProvider);
    double price = 500;
    int capacity = 3;
    
    if (passesState.hasValue) {
      final pass = passesState.value?.firstWhere((p) => p.id == widget.packageId, orElse: () => passesState.value!.first);
      if (pass != null) {
        price = pass.price;
        capacity = pass.personCapacity;
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Purchase Pass', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete your order',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'PlayfairDisplay'),
              ),
              const SizedBox(height: 8),
              Text(
                'Provide your details to receive your digital VIP pass. The pass costs ₹${price.toStringAsFixed(0)} and grants $capacity people entry.',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.length < 10 ? 'Enter a valid 10-digit number' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
              ),
              
              const SizedBox(height: 48),
              
              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 24),
                          const SizedBox(width: 8),
                          Text('Pay ₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: const Color(0xFFD4A24C)),
        filled: true,
        fillColor: const Color(0xFF141414),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4A24C)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
