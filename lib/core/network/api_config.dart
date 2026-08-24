class ApiConfig {
  /// The base URL for the backend API.
  /// Change this single value to switch between environments (e.g., local, staging, production).
  ///
  /// For local FastAPI development (Android Emulator): 'http://10.0.2.2:8000'
  /// For local FastAPI development (iOS Simulator): 'http://127.0.0.1:8000'
  /// For production: 'https://api.yourdomain.com'
  
  static const String baseUrl = 'http://127.0.0.1:8000'; // Change this line

  // Add specific endpoint paths below
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String verifyOtpEndpoint = '$baseUrl/auth/verify-otp';
  
  // Future endpoints can be added here
  // static const String pandalsEndpoint = '$baseUrl/pandals';
}
