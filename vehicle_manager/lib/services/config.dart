class ApiConfig {
  // For production deployment on EC2 with Nginx:
  // Use relative path '/api' when app is served from same domain
  // Nginx will proxy /api requests to the backend on port 3000
  static const String baseUrl = '/api';
  
  // Alternative: Use full URL if needed
  // Replace YOUR_EC2_IP with your actual EC2 public IP
  // Example: 'http://54.123.45.67/api'
  // static const String baseUrl = 'http://YOUR_EC2_IP/api';
  
  // For local development (if testing locally):
  // static const String baseUrl = 'http://localhost:3000/api';
  
  static String getBaseUrl() {
    return baseUrl;
  }
}
