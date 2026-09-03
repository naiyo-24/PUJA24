class ApiConfig {
  /// The base URL for the backend API.
  /// Change this single value to switch between environments (e.g., local, staging, production).
  ///
  /// For local FastAPI development (Android Emulator): 'http://10.0.2.2:8000'
  /// For local FastAPI development (iOS Simulator): 'http://127.0.0.1:8000'
  /// For production: 'https://api.yourdomain.com'
  
  //static const String baseUrl = 'http://127.0.0.1:8000'; // Change this line
  static const String baseUrl = 'http://192.168.0.159:8000';
  //static const String baseUrl = 'http://192.168.0.78:8000';
  // Add specific endpoint paths below
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String verifyOtpEndpoint = '$baseUrl/auth/verify-otp';
  
  // GraphQL endpoint for fetching Places (Pandals, etc.)
  static const String graphqlEndpoint = '$baseUrl/graphql';

  // Google Maps API Key for Navigation
  static const String googleMapsApiKey = 'AIzaSyBmc97dQWHVQCx6obwgI3Quw2_BCJTeAIg';
}
