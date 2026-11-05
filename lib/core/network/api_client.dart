import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../storage/auth_storage.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio _dio;
  final AuthStorage authStorage;
  void Function()? onUnauthorized;

  ApiClient({
    required this.authStorage,
    Dio? dio,
    this.onUnauthorized,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiUrl,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 25),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void updateBaseUrl() {
    _dio.options.baseUrl = AppConfig.apiUrl;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await authStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          return handler.next(e);
        },
      ),
    );
  }

  ApiException _handleDioError(DioException e) {
    if (kDebugMode) {
      debugPrint('[ApiClient FAILED] ${e.requestOptions.method} ${e.requestOptions.path} | Status: ${e.response?.statusCode} | Response: ${e.response?.data}');
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        message: 'Connection timed out. Please check your internet connection.',
        code: 'CONNECTION_TIMEOUT',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Could not connect to the server (185.196.20.220:5050). Please verify the server is running.',
        code: 'NETWORK_ERROR',
      );
    }

    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['error'] is Map) {
          final errObj = data['error'] as Map;
          return ApiException(
            message: errObj['message']?.toString() ?? 'An error occurred.',
            code: errObj['code']?.toString(),
            statusCode: e.response?.statusCode,
          );
        } else if (data['message'] != null) {
          return ApiException(
            message: data['message'].toString(),
            code: data['code']?.toString(),
            statusCode: e.response?.statusCode,
          );
        }
      }
      return ApiException(
        message: 'Server error: ${e.response?.statusCode}',
        statusCode: e.response?.statusCode,
      );
    }

    return ApiException(
      message: e.message ?? 'Network error occurred.',
      code: 'NETWORK_ERROR',
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    updateBaseUrl();
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    updateBaseUrl();
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> postMultipart(
    String path, {
    required FormData formData,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    updateBaseUrl();
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    updateBaseUrl();
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    updateBaseUrl();
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<File> downloadFile(
    String urlPath,
    String savePath, {
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      final token = await authStorage.getToken();
      await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      return File(savePath);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
