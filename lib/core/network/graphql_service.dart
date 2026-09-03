import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class GraphQLService {
  final Dio _dio;

  GraphQLService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    // Add interceptors for logging if in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  /// Sends a GraphQL POST request to the server.
  /// 
  /// [query] is the GraphQL query string.
  /// [variables] are the optional variables for the query.
  Future<Map<String, dynamic>> query(String query, {Map<String, dynamic>? variables}) async {
    try {
      final response = await _dio.post(
        ApiConfig.graphqlEndpoint,
        data: {
          'query': query,
          if (variables != null) 'variables': variables,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('errors')) {
            throw Exception('GraphQL Errors: ${data['errors']}');
          }
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to execute GraphQL query: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error during GraphQL query: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error during GraphQL query: $e');
    }
  }
}
