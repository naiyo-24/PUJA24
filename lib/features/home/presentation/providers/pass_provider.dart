import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/pass_repository.dart';
import '../../domain/models/pass_package_model.dart';
import '../../domain/models/user_voucher_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final availablePassesProvider = FutureProvider<List<PassPackageModel>>((ref) async {
  final repository = ref.watch(passRepositoryProvider);
  return repository.getAvailablePackages();
});

final myVouchersProvider = FutureProvider<List<UserVoucherModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final repository = ref.watch(passRepositoryProvider);
  
  if (authState is Authenticated) {
    return repository.getMyVouchers(authState.token);
  }
  return [];
});
