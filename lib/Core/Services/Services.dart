import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import '../Widgets/CustomSnakBar.dart';

class ApiService {
  final Dio _dio = Dio();

  // Base URL for API
  final String baseUrl = Urls.baseUrl;

  ApiService() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    );

    // Enable Logging Interceptor for better debugging
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
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

      // Show generic error
      CustomSnackbar.showSnackbar(
        context,
        "Something went wrong! Please try again.",
        duration: Duration(seconds: 2),
      );
    }
  }

  // GET Request
  Future<Response> get(String endpoint, BuildContext context, {Map<String, dynamic>? queryParameters}) async {
    try {
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
    final response = await _dio.post(endpoint, data: data);
    return response;
  } on DioException catch (e) {
    _handleDioError(e, context);
    rethrow;
  }
}

  // POST with FormData
  Future<Response> postFormData(String endpoint, BuildContext context, FormData formData) async {
    try {
      final response = await _dio.post(endpoint, data: formData);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }

  // PUT Request
  Future<Response> put(String endpoint, BuildContext context, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }

  // DELETE Request
  Future<Response> delete(String endpoint, BuildContext context, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.delete(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }

  // File Upload
  Future<Response> uploadFile(String endpoint, BuildContext context, String filePath, {Map<String, dynamic>? data}) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(endpoint, data: formData);
      return response;
    } on DioException catch (e) {
      _handleDioError(e, context);
      rethrow;
    }
  }
}

// Future<Response> makeRequestWithRetry(
//     String url, {
//     required dynamic data,
//     int retries = 2,
//   }) async {
//   int attempt = 0;
//   while (attempt < retries) {
//     try {
//       final response = await Dio().post(url, data: data);
//       return response;
//     } on DioException catch (e) {
//       if (e.type == DioExceptionType.receiveTimeout && attempt < retries - 1) {
//         print("Retrying request... Attempt ${attempt + 1}");
//         attempt++;
//         await Future.delayed(const Duration(seconds: 2)); // Wait before retrying
//       } else {
//         rethrow;
//       }
//     }
//   }
//   throw Exception("Max retries reached");
// }
