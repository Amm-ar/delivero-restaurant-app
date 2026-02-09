class ApiConstants {
  // Production URL - Update this for production deployment
  static const String baseUrl = 'https://api.delivero.com';
  static const String apiVersion = '/api';
  
  // API Endpoints
  static const String auth = '$apiVersion/auth';
  static const String restaurants = '$apiVersion/restaurants';
  static const String menu = '$apiVersion/menu';
  static const String orders = '$apiVersion/orders';
  static const String delivery = '$apiVersion/delivery';
  static const String payments = '$apiVersion/payments';
  
  // Socket.io
  static const String socketUrl = baseUrl;
  
  // Authentication Endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String me = '$auth/me';
  static const String updateProfile = '$auth/updatedetails';
  static const String updatePassword = '$auth/updatepassword';
  static const String updateFcmToken = '$auth/fcm-token';
  static const String logout = '$auth/logout';
  
  // Google Maps API Key - Use environment variable in production
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY'
  );
  
  // Stripe Publishable Key - Use environment variable in production
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'YOUR_STRIPE_PUBLISHABLE_KEY'
  );
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Helper to construct image URL safely
  static String getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) return imagePath;
    String path = imagePath;
    if (path.startsWith('/')) path = path.substring(1);
    if (!path.startsWith('uploads/')) path = 'uploads/$path';
    return '$baseUrl/$path';
  }
}
