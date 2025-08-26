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

  FileTransferRepository({required String baseUrl})
      : _service = FileTransferService(_createDio(baseUrl));

  static Dio _createDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30), // Longer timeout for file uploads
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor for debugging
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('FILE_TRANSFER DIO: $obj'),
    ));

    // Add progress interceptor for upload tracking
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('Uploading to: ${options.uri}');
          if (options.data is FormData) {
            final formData = options.data as FormData;
            debugPrint('Form data fields: ${formData.fields.length}');
            debugPrint('Form data files: ${formData.files.length}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('Upload response status: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('Upload error: ${error.message}');
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  Future<FileTransferResponse> uploadFiles({
    required List<File> files,
    String? targetDirectory,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      debugPrint('Starting upload of ${files.length} files');
      debugPrint('Target directory: $targetDirectory');

      final multipartFiles = <MultipartFile>[];
      
      for (final file in files) {
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          final multipartFile = await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          );
          multipartFiles.add(multipartFile);
          debugPrint('Added file: $fileName (${await file.length()} bytes)');
        } else {
          debugPrint('File does not exist: ${file.path}');
        }
      }

      if (multipartFiles.isEmpty) {
        throw Exception('No valid files to upload');
      }

      final response = await _service.uploadFiles(targetDirectory, multipartFiles);
      debugPrint('Upload completed: ${response.status}');
      debugPrint('Uploaded files: ${response.totalUploaded}');
      debugPrint('Skipped files: ${response.totalSkipped}');
      
      return response;
    } catch (e) {
      debugPrint('Error in uploadFiles: $e');
      rethrow;
    }
  }

  Future<DirectoriesResponse> getAvailableDirectories() async {
    try {
      debugPrint('Fetching available directories');
      final response = await _service.getDirectories();
      debugPrint('Found ${response.directories.length} directories');
      return response;
    } catch (e) {
      debugPrint('Error fetching directories: $e');
      rethrow;
    }
  }

  Future<FileTransferResponse> createDirectory(String path) async {
    try {
      debugPrint('Creating directory: $path');
      final request = FileTransferRequest(
        action: 'create_directory',
        data: FileTransferData(path: path),
      );
      final response = await _service.createDirectory(request);
      debugPrint('Directory creation result: ${response.status}');
      return response;
    } catch (e) {
      debugPrint('Error creating directory: $e');
      rethrow;
    }
  }

  Future<TransferStatus> getTransferStatus() async {
    try {
      debugPrint('Fetching transfer status');
      final response = await _service.getTransferStatus();
      debugPrint('Transfer status: ${response.status}');
      debugPrint('Supported features: ${response.features}');
      return response;
    } catch (e) {
      debugPrint('Error fetching transfer status: $e');
      rethrow;
    }
  }

  Future<DiskSpaceInfo> getDiskSpace(String? directory) async {
    try {
      debugPrint('Fetching disk space for: ${directory ?? 'default'}');
      final response = await _service.getDiskSpace(directory);
      debugPrint('Free space: ${response.freeGb} GB / ${response.totalGb} GB');
      return response;
    } catch (e) {
      debugPrint('Error fetching disk space: $e');
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
      
      debugPrint('Total file size: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB');
      debugPrint('Max allowed size: ${(maxSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB');
      
      return totalSize <= maxSizeBytes;
    } catch (e) {
      debugPrint('Error checking file size: $e');
      return false;
    }
  }

  // Helper method to format file sizes
  static String formatFileSize(int bytes) {
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
  static bool isFileTypeAllowed(String filePath, List<String> allowedExtensions) {
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
            'reason': 'File too large (${formatFileSize(size)})'
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
      'totalSizeFormatted': formatFileSize(totalSize),
    };
  }
}