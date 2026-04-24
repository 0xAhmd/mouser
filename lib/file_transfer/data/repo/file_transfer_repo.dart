import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mouser/file_transfer/data/models/directory_info.dart';
import 'package:mouser/file_transfer/data/models/disk_space_info.dart';
import 'package:mouser/file_transfer/data/models/file_transfer_request.dart';
import 'package:mouser/file_transfer/data/models/file_transfer_response.dart';
import 'package:mouser/file_transfer/data/models/transfer_status.dart';
import 'package:mouser/file_transfer/data/service/file_transfer_service.dart';

class FileTransferRepository {
  final FileTransferService _service;
  final String baseUrl;

  FileTransferRepository({required this.baseUrl})
      : _service = FileTransferService(_createDio(baseUrl));

  static Dio _createDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
      // Add validateStatus to handle HTTP errors more gracefully
      validateStatus: (status) {
        // Accept all status codes for custom error handling
        return status != null && status < 500;
      },
    ));

    // Enhanced logging interceptor
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('FILE_TRANSFER DIO: $obj'),
      error: true,
      requestHeader: true,
      responseHeader: false,
    ));

    // Enhanced error handling interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('🚀 REQUEST: ${options.method} ${options.uri}');
          if (options.data is FormData) {
            final formData = options.data as FormData;
            debugPrint('📁 Form data fields: ${formData.fields.length}');
            debugPrint('📄 Form data files: ${formData.files.length}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
              '✅ RESPONSE: ${response.statusCode} - ${response.statusMessage}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ ERROR: ${error.type} - ${error.message}');
          debugPrint(
              '🔍 ERROR DETAILS: ${error.response?.statusCode} ${error.response?.statusMessage}');
          debugPrint('🔍 ERROR DATA: ${error.response?.data}');

          // Create custom error with more context
          final customError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: _createUserFriendlyError(error),
            message: _createUserFriendlyErrorMessage(error),
          );

          handler.next(customError);
        },
      ),
    );

    return dio;
  }

  static const int maxUploadSize = 1024 * 1024 * 1024; // 1GB

  static String _createUserFriendlyError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Check your network and server status.';
      case DioExceptionType.sendTimeout:
        return 'Upload timeout. Files may be too large or connection is slow.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Server is taking too long to respond.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 404:
            return 'Server endpoint not found. Make sure the file transfer server is running correctly.';
          case 403:
            return 'Access forbidden. Check server permissions.';
          case 413:
            return 'File too large. Maximum upload size is 1GB.';
          case 500:
            return 'Server error. Check server logs for details.';
          case 503:
            return 'Server temporarily unavailable. Try again later.';
          default:
            return 'Server error ($statusCode). ${error.response?.data?.toString() ?? ''}';
        }
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Check network connection and server IP/port.';
      case DioExceptionType.badCertificate:
        return 'Invalid server certificate. Check server security settings.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }

  static String _createUserFriendlyErrorMessage(DioException error) {
    return _createUserFriendlyError(error);
  }

  // Add connection test method
  Future<bool> testConnection() async {
    try {
      debugPrint('🔄 Testing connection to $baseUrl');
      await _service.getTransferStatus();
      debugPrint('✅ Connection test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }

  Future<FileTransferResponse> uploadFiles({
    required List<File> files,
    String? targetDirectory,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      debugPrint('🚀 Starting upload of ${files.length} files');
      debugPrint('📁 Target directory: $targetDirectory');
      debugPrint('🔗 Base URL: $baseUrl');

      // Test connection first
      final isConnected = await testConnection();
      if (!isConnected) {
        throw Exception(
            'Cannot connect to file transfer server. Please check server status and network connection.');
      }

      final multipartFiles = <MultipartFile>[];

      for (final file in files) {
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          final fileSize = await file.length();
          final multipartFile = await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          );
          multipartFiles.add(multipartFile);
          debugPrint('📄 Added file: $fileName (${_formatFileSize(fileSize)})');
        } else {
          debugPrint('⚠️ File does not exist: ${file.path}');
        }
      }

      if (multipartFiles.isEmpty) {
        throw Exception('No valid files to upload');
      }

      debugPrint('📤 Uploading ${multipartFiles.length} files...');
      final response =
          await _service.uploadFiles(targetDirectory, multipartFiles);

      debugPrint('✅ Upload completed: ${response.status}');
      debugPrint('📈 Uploaded files: ${response.totalUploaded}');
      debugPrint('⏭️ Skipped files: ${response.totalSkipped}');

      return response;
    } catch (e) {
      debugPrint('❌ Error in uploadFiles: $e');
      if (e is DioException) {
        debugPrint('🔍 DioException type: ${e.type}');
        debugPrint('🔍 DioException message: ${e.message}');
        debugPrint('🔍 Response status: ${e.response?.statusCode}');
        debugPrint('🔍 Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<DirectoriesResponse> getAvailableDirectories() async {
    try {
      debugPrint('📂 Fetching available directories from $baseUrl');

      // Test connection first
      final isConnected = await testConnection();
      if (!isConnected) {
        throw Exception(
            'Cannot connect to file transfer server to fetch directories.');
      }

      final response = await _service.getDirectories();
      debugPrint('✅ Found ${response.directories.length} directories');
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching directories: $e');
      rethrow;
    }
  }

  Future<FileTransferResponse> createDirectory(String path) async {
    try {
      debugPrint('📁 Creating directory: $path');
      final request = FileTransferRequest(
        action: 'create_directory',
        data: FileTransferData(path: path),
      );
      final response = await _service.createDirectory(request);
      debugPrint('✅ Directory creation result: ${response.status}');
      return response;
    } catch (e) {
      debugPrint('❌ Error creating directory: $e');
      rethrow;
    }
  }

  Future<TransferStatus> getTransferStatus() async {
    try {
      debugPrint('ℹ️ Fetching transfer status from $baseUrl');
      final response = await _service.getTransferStatus();
      debugPrint('✅ Transfer status: ${response.status}');
      debugPrint('🔧 Supported features: ${response.features}');
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching transfer status: $e');
      rethrow;
    }
  }

  Future<DiskSpaceInfo> getDiskSpace(String? directory) async {
    try {
      debugPrint('💾 Fetching disk space for: ${directory ?? 'default'}');
      final response = await _service.getDiskSpace(directory);
      debugPrint(
          '✅ Free space: ${response.freeGb} GB / ${response.totalGb} GB');
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching disk space: $e');
      rethrow;
    }
  }

  // Helper method to check file size before upload
  Future<bool> checkFileSize(List<File> files, int maxSizeBytes) async {
    try {
      int totalSize = 0;
      for (final file in files) {
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }

      debugPrint('📊 Total file size: ${_formatFileSize(totalSize)}');
      debugPrint('📏 Max allowed size: ${_formatFileSize(maxSizeBytes)}');

      return totalSize <= maxSizeBytes;
    } catch (e) {
      debugPrint('❌ Error checking file size: $e');
      return false;
    }
  }

  // Helper method to format file sizes
  static String _formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }

  // Helper method to get file extension
  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  // Helper method to check if file type is allowed
  static bool isFileTypeAllowed(
      String filePath, List<String> allowedExtensions) {
    final extension = getFileExtension(filePath);
    return allowedExtensions.contains(extension);
  }

  // Helper method to validate files before upload
  Future<Map<String, dynamic>> validateFiles(
    List<File> files,
    List<String> allowedExtensions,
    int maxSizeBytes,
  ) async {
    final validFiles = <File>[];
    final invalidFiles = <Map<String, String>>[];
    int totalSize = 0;

    for (final file in files) {
      try {
        if (!await file.exists()) {
          invalidFiles.add({
            'file': file.path.split('/').last,
            'reason': 'File does not exist'
          });
          continue;
        }

        final size = await file.length();
        final extension = getFileExtension(file.path);

        if (!allowedExtensions.contains(extension)) {
          invalidFiles.add({
            'file': file.path.split('/').last,
            'reason': 'File type not allowed (.$extension)'
          });
          continue;
        }

        if (size > maxSizeBytes) {
          invalidFiles.add({
            'file': file.path.split('/').last,
            'reason': 'File too large (${_formatFileSize(size)})'
          });
          continue;
        }

        validFiles.add(file);
        totalSize += size;
      } catch (e) {
        invalidFiles.add({
          'file': file.path.split('/').last,
          'reason': 'Error reading file: $e'
        });
      }
    }

    return {
      'validFiles': validFiles,
      'invalidFiles': invalidFiles,
      'totalSize': totalSize,
      'totalSizeFormatted': _formatFileSize(totalSize),
    };
  }
}
