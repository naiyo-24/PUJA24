import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_config.dart';

final groupsApiServiceProvider = Provider<GroupsApiService>((ref) {
  return GroupsApiService();
});

// Provider to fetch my groups
final myGroupsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(groupsApiServiceProvider);
  return apiService.fetchMyGroups();
});

class GroupsApiService {
  final Dio _dio = Dio();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<Map<String, dynamic>>> fetchMyGroups() async {
    final token = await _getToken();
    if (token == null) {
      print('fetchMyGroups: token is null');
      return [];
    }

    try {
      print('fetchMyGroups: fetching from ${ApiConfig.baseUrl}/api/groups/my-groups');
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/groups/my-groups',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('fetchMyGroups: status code: ${response.statusCode}');
      print('fetchMyGroups: response body: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data is List) {
          final groups = List<Map<String, dynamic>>.from(data);
          // Fetch actual member count for each group
          for (var i = 0; i < groups.length; i++) {
            try {
              final members = await fetchGroupMembers(groups[i]['id']);
              groups[i]['member_count'] = members.length;
            } catch (_) {
              groups[i]['member_count'] = 1; // Fallback
            }
          }
          return groups;
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error fetching groups: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> uploadChatFile(String filePath) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/uploads/chat_file',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data is String ? jsonDecode(response.data) : response.data;
      } else {
        print('Upload failed: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error uploading chat file: $e');
    }
    return null;
  }

  Future<bool> createGroup({required String name, String? emoji, String? colorHex, dynamic image}) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      String? encodedPictureUrl;
      if (emoji != null && colorHex != null) {
        encodedPictureUrl = jsonEncode({
          'emoji': emoji,
          'colorHex': colorHex,
        });
      }

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/groups/create',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: {
          'name': name,
          'picture_url': encodedPictureUrl,
        },
      );
      print('Create group response: ${response.statusCode} - ${response.data}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating group: $e');
      return false;
    }
  }

  Future<bool> joinGroup(String inviteCode) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/groups/join',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: {'join_code': inviteCode},
      );
      print('Join group response: ${response.statusCode} - ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error joining group: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchGroupDetails(String groupId) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/groups/$groupId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200) {
        return response.data is String ? jsonDecode(response.data) : response.data;
      }
    } catch (e) {
      print('Error fetching group details: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/groups/$groupId/members',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data is List) return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      print('Error fetching group members: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchGroupMessages(String groupId) async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/groups/$groupId/messages',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data is List) return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      print('Error fetching group messages: $e');
    }
    return [];
  }

  Future<bool> removeMember(String groupId, String userId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await _dio.delete(
        '${ApiConfig.baseUrl}/api/groups/$groupId/members/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Error removing member. Status: ${response.statusCode}, Body: ${response.data}');
        return false;
      }
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }

  Future<bool> exitGroup(String groupId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/groups/$groupId/leave',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error exiting group: $e');
      return false;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await _dio.delete(
        '${ApiConfig.baseUrl}/api/groups/$groupId/leave',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error leaving group: $e');
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await _dio.delete(
        '${ApiConfig.baseUrl}/api/groups/$groupId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting group: $e');
      return false;
    }
  }

  Future<bool> editGroup(String groupId, {String? name, String? emoji, String? colorHex}) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      String? encodedPictureUrl;
      if (emoji != null || colorHex != null) {
        encodedPictureUrl = jsonEncode({
          if (emoji != null) 'emoji': emoji,
          if (colorHex != null) 'colorHex': colorHex,
        });
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (encodedPictureUrl != null) body['picture_url'] = encodedPictureUrl;
      
      if (body.isEmpty) return true; // Nothing to update

      final response = await _dio.patch(
        '${ApiConfig.baseUrl}/api/groups/$groupId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error editing group: $e');
      return false;
    }
  }
}
