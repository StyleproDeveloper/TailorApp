import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tailorapp/Core/Services/Urls.dart';
import '../Widgets/CustomSnakBar.dart';

class ApiService {
  final Dio _dio = Dio();

  // HARDCODED LOCAL BACKEND - NO EXCEPTIONS
  final String baseUrl = 'http://localhost:5500';

  ApiService() {
    // CRITICAL LOGS
    print('🚨🚨🚨 API SERVICE INITIALIZED 🚨🚨🚨');
    print('🚨🚨🚨 BASE URL HARDCODED: $baseUrl 🚨🚨🚨');
    print('🚨🚨🚨 If you see Vercel URL, browser is using OLD CACHED CODE 🚨🚨🚨');
    
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    );

    // Enable Logging Interceptor for better debugging
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: true,
      ),
    );
    
    print('🚨🚨🚨 DIO CONFIGURED WITH BASE URL: ${_dio.options.baseUrl} 🚨🚨🚨');
  }

  // Update headers dynamically (for tokens, etc.)
  void updateHeaders(Map<String, String> headers) {
    _dio.options.headers.addAll(headers);
  }

  // Common error handling
  void _handleDioError(DioException e, BuildContext context) {
    if (e.response != null) {
      print("⚠️ Status Code: ${e.response!.statusCode}");
      print("🔹 Response Data: ${e.response!.data['error']}");
      print("🌐 Request URL: ${e.requestOptions.uri}");

      // Show error in Snackbar or Toast
      CustomSnackbar.showSnackbar(
        context,
        e.response!.data['error'].toString(),
        duration: Duration(seconds: 2),
      );
    } else {
      print("🌐 Request URL: ${e.requestOptions.uri}");
      print("🛑 Error Message: ${e.message}");

      // Check if it's a CORS issue
      if (e.type == DioExceptionType.connectionError || 
          e.message?.contains('CORS') == true ||
          e.message?.contains('Access-Control') == true) {
        CustomSnackbar.showSnackbar(
          context,
          "CORS Error: Backend at $baseUrl needs to allow localhost requests. Check backend CORS configuration.",
          duration: Duration(seconds: 5),
        );
      } else {
        // Show generic error
        CustomSnackbar.showSnackbar(
          context,
          "Something went wrong! Please try again.",
          duration: Duration(seconds: 2),
        );
      }
    }
  }

  // GET Request
  Future<Response> get(String endpoint, BuildContext context, {Map<String, dynamic>? queryParameters}) async {
    try {
      print('🌐🌐🌐 GET REQUEST TO: $baseUrl$endpoint 🌐🌐🌐');
      final response = await _dio.get(endpoint, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }

  // POST Request
  Future<Response> post(String endpoint, BuildContext context, {dynamic data}) async {
    try {
      print('🌐🌐🌐 POST REQUEST TO: $baseUrl$endpoint 🌐🌐🌐');
      final response = await _dio.post(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }

  // PATCH Request
  Future<Response> patch(String endpoint, BuildContext context, {dynamic data}) async {
    try {
      print('🌐🌐🌐 PATCH REQUEST TO: $baseUrl$endpoint 🌐🌐🌐');
      final response = await _dio.patch(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }

  // DELETE Request
  Future<Response> delete(String endpoint, BuildContext context) async {
    try {
      print('🌐🌐🌐 DELETE REQUEST TO: $baseUrl$endpoint 🌐🌐🌐');
      final response = await _dio.delete(endpoint);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }

  // PUT Request
  Future<Response> put(String endpoint, BuildContext context, {dynamic data}) async {
    try {
      print('🌐🌐🌐 PUT REQUEST TO: $baseUrl$endpoint 🌐🌐🌐');
      final response = await _dio.put(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }

  // Upload file
  Future<Response> uploadFile(
    String endpoint,
    BuildContext context, {
    required String filePath,
    String? fieldName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('🌐🌐🌐 UPLOAD REQUEST TO: $baseUrl$endpoint 🌐🌐🌐');
      
      final formData = FormData();
      
      if (kIsWeb) {
        // Web file handling
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          formData.files.add(MapEntry(
            fieldName ?? 'file',
            MultipartFile.fromBytes(bytes, filename: filePath.split('/').last),
          ));
        }
      } else {
        // Mobile file handling
        final multipartFile = await MultipartFile.fromFile(filePath, filename: filePath.split('/').last);
        formData.files.add(MapEntry(fieldName ?? 'file', multipartFile));
      }
      
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }
      
      final response = await _dio.post(endpoint, data: formData);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }

  // Post FormData directly (for web)
  Future<Response> postFormData(
    String endpoint,
    BuildContext context,
    FormData formData,
  ) async {
    try {
      print('🌐🌐🌐 POST FORMDATA REQUEST TO: $baseUrl$endpoint 🌐🌐🌐');
      final response = await _dio.post(endpoint, data: formData);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }

  // Upload media file (for mobile with File object)
  Future<Response> uploadMediaFile(
    String endpoint,
    BuildContext context, {
    required File file,
    Map<String, dynamic>? fields,
  }) async {
    try {
      print('🌐🌐🌐 UPLOAD MEDIA FILE REQUEST TO: $baseUrl$endpoint 🌐🌐🌐');
      
      final formData = FormData();
      
      // Determine MIME type from file extension
      String? mimeType;
      final fileName = file.path.split('/').last.toLowerCase();
      if (fileName.endsWith('.m4a')) {
        mimeType = 'audio/mp4';
      } else if (fileName.endsWith('.mp3')) {
        mimeType = 'audio/mpeg';
      } else if (fileName.endsWith('.wav')) {
        mimeType = 'audio/wav';
      } else if (fileName.endsWith('.ogg')) {
        mimeType = 'audio/ogg';
      } else if (fileName.endsWith('.aac')) {
        mimeType = 'audio/aac';
      }
      
      // Add file with proper MIME type if detected
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
        contentType: mimeType != null ? DioMediaType.parse(mimeType) : null,
      );
      formData.files.add(MapEntry('file', multipartFile));
      
      // Add additional fields
      if (fields != null) {
        fields.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }
      
      final response = await _dio.post(endpoint, data: formData);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }
}
