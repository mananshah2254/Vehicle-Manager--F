class ApiConfig {
  // Update this with your EC2 server URL
  // For local development: 'http://localhost:3000/api'
  // For EC2: 'http://YOUR_EC2_IP:3000/api' or 'http://YOUR_DOMAIN/api'
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Helper method to update base URL at runtime if needed
  static String getBaseUrl() {
    // You can add environment-based URL selection here
    return baseUrl;
  }
}

