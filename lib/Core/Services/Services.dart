import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:tailorapp/Core/Services/Urls.dart';
import '../Widgets/CustomSnakBar.dart';

class ApiService {
  final Dio _dio = Dio();

  // Dynamic baseUrl - detects environment automatically
  final String baseUrl = Urls.baseUrl;

  ApiService() {
    // Production-ready: Only log in debug mode
    if (kDebugMode) {
      print('API Service initialized with base URL: $baseUrl');
    }
    
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    );

    // Enable Logging Interceptor only in debug mode
    if (kDebugMode) {
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
    }
  }

  // Update headers dynamically (for tokens, etc.)
  void updateHeaders(Map<String, String> headers) {
    _dio.options.headers.addAll(headers);
  }

  // Common error handling
  void _handleDioError(DioException e, BuildContext context) {
    if (e.response != null) {
      if (kDebugMode) {
        print("Error Status: ${e.response!.statusCode}");
        print("Error Data: ${e.response!.data['error']}");
        print("Request URL: ${e.requestOptions.uri}");
      }

      // Show error in Snackbar or Toast
      CustomSnackbar.showSnackbar(
        context,
        e.response!.data['error'].toString(),
        duration: Duration(seconds: 2),
      );
    } else {
      if (kDebugMode) {
        print("Request URL: ${e.requestOptions.uri}");
        print("Error Message: ${e.message}");
      }

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
      if (kDebugMode) {
        print('GET: $baseUrl$endpoint');
      }
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
      if (kDebugMode) {
        print('POST: $baseUrl$endpoint');
      }
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
      if (kDebugMode) {
        print('PATCH: $baseUrl$endpoint');
      }
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
      if (kDebugMode) {
        print('DELETE: $baseUrl$endpoint');
      }
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
      if (kDebugMode) {
        print('PUT: $baseUrl$endpoint');
      }
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
      if (kDebugMode) {
        print('UPLOAD: $baseUrl$endpoint');
      }
      
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
      if (kDebugMode) {
        print('POST FORMDATA: $baseUrl$endpoint');
      }
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
      if (kDebugMode) {
        print('UPLOAD MEDIA: $baseUrl$endpoint');
        print('📁 File path: ${file.path}');
      }
      
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }
      
      // Get file size
      final fileSize = await file.length();
      if (kDebugMode) {
        print('📊 File size: ${fileSize} bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
      }
      
      final formData = FormData();
      
      // Determine MIME type from file extension
      String? mimeType;
      final fileName = file.path.split('/').last.toLowerCase();
      
      // Image MIME types - comprehensive list
      if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (fileName.endsWith('.heic') || fileName.endsWith('.heif')) {
        mimeType = 'image/heic';
      } else if (fileName.endsWith('.bmp')) {
        mimeType = 'image/bmp';
      } else if (fileName.endsWith('.tiff') || fileName.endsWith('.tif')) {
        mimeType = 'image/tiff';
      } else if (fileName.endsWith('.ico')) {
        mimeType = 'image/x-icon';
      } else if (fileName.endsWith('.svg')) {
        mimeType = 'image/svg+xml';
      }
      // Audio MIME types
      else if (fileName.endsWith('.m4a')) {
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
      
      if (kDebugMode) {
        print('📄 Detected MIME type: ${mimeType ?? 'unknown'}');
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
      
      if (kDebugMode) {
        print('📤 Uploading file with ${formData.fields.length} fields and ${formData.files.length} files');
      }
      
      final response = await _dio.post(
        endpoint, 
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60), // Increase timeout for large files
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      
      if (kDebugMode) {
        print('✅ Upload successful: ${response.statusCode}');
      }
      
      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException during upload: ${e.message}');
        print('❌ Error type: ${e.type}');
        print('❌ Response: ${e.response?.data}');
      }
      _handleDioError(e, context);
      rethrow;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ General error during upload: $e');
        print('❌ Stack trace: $stackTrace');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }
}
