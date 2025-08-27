import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mouser/file_transfer/data/models/pc_file_info.dart';
import 'package:mouser/file_transfer/data/service/pc_transfer_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class PCTransferRepository {
  final PCTransferService _service;
  final String baseUrl;
  final Dio _downloadDio;

  PCTransferRepository({required this.baseUrl})
      : _service = PCTransferService(_createDio(baseUrl)),
        _downloadDio = _createDownloadDio(baseUrl);

  static Dio _createDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
      // Add validateStatus to handle HTTP errors more gracefully
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('PC_TRANSFER DIO: $obj'),
    ));

    // Add error handling interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          // Sanitize response data to handle null numeric values
          if (response.data is Map<String, dynamic>) {
            response.data = _sanitizeJsonData(response.data);
          }
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ PC_TRANSFER ERROR: ${error.type} - ${error.message}');
          debugPrint(
              '🔍 ERROR DETAILS: ${error.response?.statusCode} ${error.response?.statusMessage}');
          debugPrint('🔍 ERROR DATA: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static Dio _createDownloadDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout:
          const Duration(minutes: 10), // Longer timeout for downloads
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => debugPrint('DOWNLOAD DIO: $obj'),
    ));

    return dio;
  }

  // Helper method to sanitize JSON data and replace null numeric values with defaults
  static Map<String, dynamic> _sanitizeJsonData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (value == null) {
        // Set appropriate defaults for known numeric fields
        if (_isNumericField(key)) {
          sanitized[key] = 0;
        } else if (_isBooleanField(key)) {
          sanitized[key] = false;
        } else if (_isStringField(key)) {
          sanitized[key] = '';
        } else if (_isListField(key)) {
          sanitized[key] = <dynamic>[];
        } else {
          sanitized[key] = value; // Keep null for other fields
        }
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeJsonData(value);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _sanitizeJsonData(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  static bool _isNumericField(String key) {
    const numericFields = [
      'totalFiles',
      'totalDirectories',
      'fileCount',
      'dirCount',
      'downloadableFiles',
      'totalSize',
      'maxFileSizeMb',
      'totalRequested',
      'readyForDownload',
      'errors',
      'size',
      'sizeMb'
    ];
    return numericFields.contains(key);
  }

  static bool _isBooleanField(String key) {
    const booleanFields = ['accessible', 'downloadable', 'exists', 'writable'];
    return booleanFields.contains(key);
  }

  static bool _isStringField(String key) {
    const stringFields = [
      'totalSizeFormatted',
      'sizeFormatted',
      'name',
      'path',
      'type',
      'extension',
      'mimeType',
      'skipReason',
      'modified',
      'status',
      'currentPath',
      'parentPath',
      'homePath',
      'error',
      'downloadUrl'
    ];
    return stringFields.contains(key);
  }

  static bool _isListField(String key) {
    const listFields = [
      'allowedExtensions',
      'directories',
      'files',
      'folders',
      'downloads'
    ];
    return listFields.contains(key);
  }

  Future<PCBrowseResponse> browsePath(String? path) async {
    try {
      debugPrint('🔍 Browsing path: ${path ?? 'default'}');
      final response = await _service.browsePath(path);
      debugPrint(
          '✅ Found ${response.files.length} files, ${response.directories.length} directories');
      return response;
    } catch (e) {
      debugPrint('❌ Error browsing path: $e');
      // Return a safe empty response on error
      return const PCBrowseResponse(
        status: 'error',
        directories: [],
        files: [],
        totalDirectories: 0,
        totalFiles: 0,
        error: 'Failed to browse path',
      );
    }
  }

  Future<PCFileInfoResponse> getFileInfo(List<String> filePaths) async {
    try {
      debugPrint('📋 Getting info for ${filePaths.length} files');
      final request = {'paths': filePaths};
      final response = await _service.getFileInfo(request);
      debugPrint('✅ Retrieved info for ${response.files.length} files');
      return response;
    } catch (e) {
      debugPrint('❌ Error getting file info: $e');
      // Return a safe empty response on error
      return const PCFileInfoResponse(
        status: 'error',
        files: [],
        summary: FilesSummary(
          totalFiles: 0,
          downloadableFiles: 0,
          totalSize: 0,
          totalSizeFormatted: '0 B',
          maxFileSizeMb: 0,
          allowedExtensions: [],
        ),
        error: 'Failed to get file info',
      );
    }
  }

  Future<PCDownloadResponse> prepareDownload(List<String> filePaths) async {
    try {
      debugPrint('🚀 Preparing download for ${filePaths.length} files');
      final request = {'paths': filePaths};
      final response = await _service.prepareDownload(request);
      debugPrint(
          '✅ ${response.summary.readyForDownload} files ready for download');
      return response;
    } catch (e) {
      debugPrint('❌ Error preparing download: $e');
      // Return a safe empty response on error
      return const PCDownloadResponse(
        status: 'error',
        downloads: [],
        summary: DownloadSummary(
          totalRequested: 0,
          readyForDownload: 0,
          errors: 0,
        ),
        error: 'Failed to prepare download',
      );
    }
  }

  Future<QuickAccessResponse> getQuickAccessFolders() async {
    try {
      debugPrint('📂 Getting quick access folders');
      final response = await _service.getQuickAccessFolders();
      debugPrint('✅ Found ${response.folders.length} quick access folders');
      return response;
    } catch (e) {
      debugPrint('❌ Error getting quick access folders: $e');
      // Return a safe empty response on error
      return const QuickAccessResponse(
        status: 'error',
        folders: [],
        homePath: '',
        error: 'Failed to get quick access folders',
      );
    }
  }

  Future<String?> _getDownloadDirectory() async {
    try {
      // Check storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Get downloads directory
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('Could not find downloads directory');
      }

      return downloadsDir.path;
    } catch (e) {
      debugPrint('❌ Error getting download directory: $e');
      return null;
    }
  }

  Future<DownloadResult> downloadFile(
    PCDownloadInfo downloadInfo, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      if (!downloadInfo.canDownload) {
        throw Exception('File cannot be downloaded: ${downloadInfo.error}');
      }

      final downloadDir = await _getDownloadDirectory();
      if (downloadDir == null) {
        throw Exception('Cannot access downloads directory');
      }

      final fileName = downloadInfo.name ?? 'downloaded_file';
      final filePath = '$downloadDir/$fileName';

      // Handle duplicate files
      String finalFilePath = filePath;
      int counter = 1;
      while (File(finalFilePath).existsSync()) {
        final baseName = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;
        final extension = fileName.contains('.')
            ? fileName.substring(fileName.lastIndexOf('.'))
            : '';
        finalFilePath = '$downloadDir/${baseName}_$counter$extension';
        counter++;
      }

      debugPrint('📥 Downloading to: $finalFilePath');

      final response = await _downloadDio.download(
        downloadInfo.downloadUrl!,
        finalFilePath,
        onReceiveProgress: onProgress,
      );

      if (response.statusCode == 200) {
        final file = File(finalFilePath);
        if (file.existsSync()) {
          debugPrint('✅ Download completed: ${file.lengthSync()} bytes');
          return DownloadResult.success(
            filePath: finalFilePath,
            fileName: finalFilePath.split('/').last,
            fileSize: file.lengthSync(),
          );
        }
      }

      throw Exception('Download failed with status: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error downloading file: $e');
      return DownloadResult.error(error: e.toString());
    }
  }

  Future<List<DownloadResult>> downloadMultipleFiles(
    List<PCDownloadInfo> downloadInfos, {
    void Function(int current, int total)? onOverallProgress,
    void Function(int received, int total, String fileName)? onFileProgress,
  }) async {
    final results = <DownloadResult>[];

    for (int i = 0; i < downloadInfos.length; i++) {
      final downloadInfo = downloadInfos[i];

      onOverallProgress?.call(i, downloadInfos.length);

      try {
        final result = await downloadFile(
          downloadInfo,
          onProgress: (received, total) {
            onFileProgress?.call(
                received, total, downloadInfo.name ?? 'Unknown');
          },
        );
        results.add(result);

        // Small delay between downloads
        if (i < downloadInfos.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        results.add(DownloadResult.error(error: e.toString()));
      }
    }

    onOverallProgress?.call(downloadInfos.length, downloadInfos.length);
    return results;
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
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final String? error;

  const DownloadResult._({
    required this.success,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.error,
  });

  factory DownloadResult.success({
    required String filePath,
    required String fileName,
    required int fileSize,
  }) {
    return DownloadResult._(
      success: true,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
    );
  }

  factory DownloadResult.error({required String error}) {
    return DownloadResult._(
      success: false,
      error: error,
    );
  }

  String get formattedSize =>
      fileSize != null ? PCTransferRepository.formatFileSize(fileSize!) : '0 B';
}
