import 'dart:convert';
import 'package:http/http.dart' as http;
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
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<Map<String, dynamic>>> fetchMyGroups() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/my-groups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/uploads/chat_file'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
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

      // JSON request (multipart not yet supported by backend schema)
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'picture_url': encodedPictureUrl,
        }),
      );
      print('Create group response: ${response.statusCode} - ${response.body}');
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'join_code': inviteCode}),
      );
      print('Join group response: ${response.statusCode} - ${response.body}');
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId/members/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Error removing member. Status: ${response.statusCode}, Body: ${response.body}');
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId/leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId/leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error editing group: $e');
      return false;
    }
  }
}
