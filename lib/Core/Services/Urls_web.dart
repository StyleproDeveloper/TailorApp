// Web-specific implementation using dart:html
import 'dart:html' as html;

String getWebUrl() {
  try {
    final hostname = html.window.location.hostname;
    final protocol = html.window.location.protocol;
    
    print('🌐 Detected hostname: $hostname');
    print('🌐 Detected protocol: $protocol');
    
    // If running on localhost or 127.0.0.1, use local backend
    if (hostname == 'localhost' || hostname == '127.0.0.1') {
      final url = 'http://localhost:5500';
      print('✅ Using LOCAL backend: $url');
      return url;
    }
    
    // Otherwise, use production backend
    final url = 'https://tailor-app-backend-1bfc2dnm3-stylepros-projects.vercel.app';
    print('✅ Using PRODUCTION backend: $url');
    return url;
  } catch (e) {
    print('⚠️ Error detecting hostname: $e');
    // Fallback to production
    return 'https://tailor-app-backend-1bfc2dnm3-stylepros-projects.vercel.app';
  }
}
