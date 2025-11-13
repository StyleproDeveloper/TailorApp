// Stub implementation for non-web platforms (mobile)
// This file is used when dart:html is not available

String getWebUrl() {
  // On mobile, always return production URL
  // This function should never be called on mobile, but provides a fallback
  return 'https://tailor-app-backend-1bfc2dnm3-stylepros-projects.vercel.app';
}

