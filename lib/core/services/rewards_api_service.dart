import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_config.dart';

final rewardsApiServiceProvider = Provider<RewardsApiService>((ref) {
  return RewardsApiService();
});

class RewardsApiService {
  final Dio _dio = Dio();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<Map<String, dynamic>> watchAd() async {
    final token = await _getToken();
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/rewards/watch-ad',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to process reward: $e');
    }
  }

  Future<Map<String, dynamic>> redeemPass() async {
    final token = await _getToken();
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/rewards/redeem-pass',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to redeem pass');
      }
      throw Exception('Failed to redeem pass: $e');
    }
  }

  Future<Map<String, dynamic>> getMyPasses() async {
    final token = await _getToken();
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/rewards/my-passes',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch passes: $e');
    }
  }
}
