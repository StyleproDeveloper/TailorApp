// Web-specific implementation
import 'dart:html' as html;

String getWebHostname() {
  return html.window.location.hostname ?? 'localhost';
}

