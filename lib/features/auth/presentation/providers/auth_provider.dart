import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_config.dart';

// User Model
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? profileImageUrl;
  final String? phoneNumber;
  final int? age;
  final String? sex;
  final String? address;
  final List<String>? interestedPandals;
  
  UserModel({
    required this.id, required this.email, required this.fullName,
    this.profileImageUrl, this.phoneNumber, this.age, this.sex,
    this.address, this.interestedPandals
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      profileImageUrl: json['profile_image_url'],
      phoneNumber: json['phone_number'],
      age: json['age'],
      sex: json['sex'],
      address: json['address'],
      interestedPandals: json['interested_pandals'] != null ? List<String>.from(json['interested_pandals']) : null,
    );
  }
}

// Auth State
sealed class AuthState { const AuthState(); }
class AuthInitial extends AuthState { const AuthInitial(); }
class AuthLoading extends AuthState { const AuthLoading(); }
class Authenticated extends AuthState {
  final UserModel user;
  final String token;
  final bool isNewUser;
  const Authenticated(this.user, this.token, this.isNewUser);
}
class Unauthenticated extends AuthState { const Unauthenticated(); }
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthInitial()) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      // For now, assuming logged in if token exists. 
      // Ideally, fetch user profile from backend to verify.
      state = Authenticated(UserModel(id: '', email: '', fullName: 'User'), token, false);
    } else {
      state = const Unauthenticated();
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        serverClientId: '16874042850-a2cumknkn0ntcidh5arkae32gle5vni4.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) {
        state = const Unauthenticated();
        return;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Send token to backend
      if (googleAuth.idToken != null) {
        final dio = Dio();
        final response = await dio.post(
          '${ApiConfig.baseUrl}/auth/google',
          data: {'id_token': googleAuth.idToken},
        );
        
        final data = response.data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        
        state = Authenticated(
          UserModel.fromJson(data['user']),
          data['access_token'],
          data['is_new_user']
        );
      } else {
         state = const AuthError('Google Sign In Failed: No ID token');
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
  
  Future<void> updateProfile({
    required String fullName,
    required String phone, 
    required String address,
    required int age, 
    required String sex,
    required List<String> interestedPandals,
  }) async {
      if (state is! Authenticated) return;
      final authState = state as Authenticated;
      
      try {
        final dio = Dio();
        final response = await dio.post(
          '${ApiConfig.baseUrl}/auth/profile',
          data: {
            'full_name': fullName,
            'phone_number': phone,
            'address': address,
            'age': age,
            'sex': sex,
            'interested_pandals': interestedPandals
          },
          options: Options(headers: {'Authorization': 'Bearer ${authState.token}'})
        );
        
        state = Authenticated(UserModel.fromJson(response.data['user']), authState.token, false);
      } catch (e) {
         print("Error updating profile: $e");
      }
  }

  Future<void> logout() async {
    if (state is Authenticated) {
      final token = (state as Authenticated).token;
      try {
        final dio = Dio();
        await dio.post(
          '${ApiConfig.baseUrl}/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (e) {
        print("Backend logout failed: $e");
      }
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("FirebaseAuth signout failed: $e");
    }
    
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await googleSignIn.disconnect();
    } catch (e) {
      print("GoogleSignIn disconnect failed: $e");
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    state = const Unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
