import 'package:dio/dio.dart';
import '../../../../core/network/api_config.dart';
import '../domain/models/pass_package_model.dart';
import '../domain/models/user_voucher_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final passRepositoryProvider = Provider<PassRepository>((ref) {
  return PassRepository();
});

class PassRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  PassRepository();

  Future<List<PassPackageModel>> getAvailablePackages() async {
    try {
      final response = await _dio.get('/passes/packages');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PassPackageModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load passes: $e');
    }
  }

  Future<PassPackageModel> getPackageDetails(String packageId) async {
    try {
      final response = await _dio.get('/passes/packages/$packageId');
      if (response.statusCode == 200) {
        return PassPackageModel.fromJson(response.data);
      }
      throw Exception('Pass not found');
    } catch (e) {
      throw Exception('Failed to load pass details: $e');
    }
  }

  Future<List<UserVoucherModel>> getMyVouchers(String token) async {
    try {
      final response = await _dio.get(
        '/passes/my-vouchers',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserVoucherModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load your passes: $e');
    }
  }

  Future<Map<String, dynamic>> createOrder(String packageId, String token) async {
    try {
      final response = await _dio.post(
        '/payments/create-order',
        data: {'package_id': packageId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create order');
    } catch (e) {
      throw Exception('Payment error: $e');
    }
  }
}
