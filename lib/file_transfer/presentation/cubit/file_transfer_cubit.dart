import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:mouser/file_transfer/data/models/directory_info.dart';
import 'package:mouser/file_transfer/data/models/file_transfer_response.dart';
import 'package:mouser/file_transfer/data/repo/file_transfer_repo.dart';
import 'package:mouser/file_transfer/presentation/cubit/file_transfer_state.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';

class FileTransferCubit extends Cubit<FileTransferState> {
  final ConnectionCubit _connectionCubit;
  FileTransferRepository? _repository;

  FileTransferCubit({required ConnectionCubit connectionCubit})
      : _connectionCubit = connectionCubit,
        super(const FileTransferState()) {
    _initializeRepository();
    _listenToConnectionChanges();
  }

  void _initializeRepository() {
    final serverIP = _connectionCubit.state.serverIP;
    final serverPort = _connectionCubit.state.serverPort;
    final baseUrl = 'http://$serverIP:$serverPort';

    debugPrint('🔧 Initializing FileTransferRepository with baseUrl: $baseUrl');
    _repository = FileTransferRepository(baseUrl: baseUrl);
  }

  void _listenToConnectionChanges() {
    _connectionCubit.stream.listen((connectionState) {
      debugPrint('🔗 Connection state changed: ${connectionState.isConnected}');
      emit(state.copyWith(isConnected: connectionState.isConnected));

      if (connectionState.isConnected) {
        _initializeRepository();
        _initializeAfterConnection();
      } else {
        // Clear data when disconnected
        emit(state.copyWith(
          transferStatus: null,
          availableDirectories: [],
          selectedDirectory: null,
          diskSpaceInfo: null,
        ));
      }
    });
  }

  Future<void> _initializeAfterConnection() async {
    try {
      await loadTransferStatus();
      await loadAvailableDirectories();
    } catch (e) {
      debugPrint('⚠️ Failed to initialize after connection: $e');
    }
  }

  // File selection methods
  void addFiles(List<File> files) {
    final updatedFiles = List<File>.from(state.selectedFiles)..addAll(files);
    emit(state.copyWith(selectedFiles: updatedFiles));
    debugPrint('📁 Added ${files.length} files. Total: ${updatedFiles.length}');
  }

  void removeFile(File file) {
    final updatedFiles = List<File>.from(state.selectedFiles)..remove(file);
    emit(state.copyWith(selectedFiles: updatedFiles));
    debugPrint('🗑️ Removed file. Remaining: ${updatedFiles.length}');
  }

  void clearFiles() {
    emit(state.copyWith(selectedFiles: []));
    debugPrint('🧹 Cleared all selected files');
  }

  void replaceFiles(List<File> files) {
    emit(state.copyWith(selectedFiles: files));
    debugPrint('🔄 Replaced files. New count: ${files.length}');
  }

  // Directory methods
  Future<void> loadAvailableDirectories() async {
    if (!state.isConnected || _repository == null) {
      debugPrint(
          '⚠️ Cannot load directories: not connected or repository null');
      return;
    }

    emit(state.copyWith(directoryStatus: DirectoryStatus.loading));

    try {
      debugPrint('📂 Loading available directories...');
      final response = await _repository!.getAvailableDirectories();

      if (response.status == 'success') {
        debugPrint(
            '✅ Successfully loaded ${response.directories.length} directories');
        emit(state.copyWith(
          directoryStatus: DirectoryStatus.loaded,
          availableDirectories: response.directories,
          errorMessage: null,
        ));

        // Auto-select default directory if available and none selected
        if (state.selectedDirectory == null) {
          _autoSelectDefaultDirectory(response.directories);
        }
      } else {
        final errorMsg = response.error ?? 'Failed to load directories';
        debugPrint('❌ Directory loading failed: $errorMsg');
        emit(state.copyWith(
          directoryStatus: DirectoryStatus.error,
          errorMessage: errorMsg,
        ));
      }
    } catch (e) {
      final errorMsg = _handleError(e, 'loading directories');
      debugPrint('❌ Error loading directories: $errorMsg');
      emit(state.copyWith(
        directoryStatus: DirectoryStatus.error,
        errorMessage: errorMsg,
      ));
    }
  }

  void _autoSelectDefaultDirectory(List<DirectoryInfo> directories) {
    if (directories.isEmpty) return;

    // Try to find preferred directories
    DirectoryInfo? defaultDir;

    // Look for common transfer directories
    for (final pattern in [
      'Phone Transfer',
      'Downloads',
      'Transfer',
      'Files'
    ]) {
      defaultDir = directories.cast<DirectoryInfo?>().firstWhere(
            (dir) =>
                dir?.name.toLowerCase().contains(pattern.toLowerCase()) == true,
            orElse: () => null,
          );
      if (defaultDir != null) break;
    }

    // Fallback to first writable directory
    defaultDir ??= directories.cast<DirectoryInfo?>().firstWhere(
          (dir) => dir?.writable == true && dir?.exists == true,
          orElse: () => directories.isNotEmpty ? directories.first : null,
        );

    if (defaultDir != null) {
      debugPrint('🎯 Auto-selected directory: ${defaultDir.name}');
      selectDirectory(defaultDir);
    }
  }

  void selectDirectory(DirectoryInfo directory) {
    emit(state.copyWith(selectedDirectory: directory));
    loadDiskSpace(directory.path);
    debugPrint('✅ Selected directory: ${directory.name} (${directory.path})');
  }

  Future<void> createDirectory(String path) async {
    if (!state.isConnected || _repository == null) {
      debugPrint(
          '⚠️ Cannot create directory: not connected or repository null');
      return;
    }

    emit(state.copyWith(status: FileTransferStatus.loading));

    try {
      debugPrint('📁 Creating directory: $path');
      final response = await _repository!.createDirectory(path);

      if (response.status == 'success') {
        debugPrint('✅ Directory created successfully');
        emit(state.copyWith(
          status: FileTransferStatus.success,
          successMessage: 'Directory created successfully',
        ));
        // Reload directories to include the new one
        await loadAvailableDirectories();
      } else {
        final errorMsg = response.error ?? 'Failed to create directory';
        debugPrint('❌ Directory creation failed: $errorMsg');
        emit(state.copyWith(
          status: FileTransferStatus.error,
          errorMessage: errorMsg,
        ));
      }
    } catch (e) {
      final errorMsg = _handleError(e, 'creating directory');
      debugPrint('❌ Error creating directory: $errorMsg');
      emit(state.copyWith(
        status: FileTransferStatus.error,
        errorMessage: errorMsg,
      ));
    }
  }

  // Transfer status methods
  Future<void> loadTransferStatus() async {
    if (!state.isConnected || _repository == null) {
      debugPrint(
          '⚠️ Cannot load transfer status: not connected or repository null');
      return;
    }

    try {
      debugPrint('ℹ️ Loading transfer status...');
      final response = await _repository!.getTransferStatus();
      debugPrint('✅ Transfer status loaded: ${response.version}');
      emit(state.copyWith(transferStatus: response));
    } catch (e) {
      final errorMsg = _handleError(e, 'loading transfer status');
      debugPrint('❌ Error loading transfer status: $errorMsg');
      // Don't emit error for transfer status as it's not critical
    }
  }

  // Disk space methods
  Future<void> loadDiskSpace(String? directory) async {
    if (!state.isConnected || _repository == null) {
      debugPrint('⚠️ Cannot load disk space: not connected or repository null');
      return;
    }

    try {
      debugPrint('💾 Loading disk space for: ${directory ?? 'default'}');
      final response = await _repository!.getDiskSpace(directory);
      debugPrint('✅ Disk space loaded: ${response.freeGb} GB free');
      emit(state.copyWith(diskSpaceInfo: response));
    } catch (e) {
      final errorMsg = _handleError(e, 'loading disk space');
      debugPrint('❌ Error loading disk space: $errorMsg');
      // Don't emit error for disk space as it's not critical
    }
  }

  // Upload methods
  Future<void> uploadFiles() async {
    if (!state.canUpload || _repository == null) {
      final reason = _getUploadBlockReason();
      debugPrint('❌ Cannot upload: $reason');
      emit(state.copyWith(
        status: FileTransferStatus.error,
        errorMessage: reason,
      ));
      return;
    }

    emit(state.copyWith(
      status: FileTransferStatus.uploading,
      uploadProgress: 0.0,
      errorMessage: null,
      successMessage: null,
    ));

    try {
      debugPrint('🚀 Starting file upload...');

      // Validate files if transfer status is available
      List<File> filesToUpload = state.selectedFiles;

      if (state.transferStatus != null) {
        final validation = await _repository!.validateFiles(
          state.selectedFiles,
          state.transferStatus!.allowedExtensions,
          1024 * 1024 * 1024, // 1GB max
        );

        final validFiles = validation['validFiles'] as List<File>;
        final invalidFiles =
            validation['invalidFiles'] as List<Map<String, String>>;

        if (validFiles.isEmpty) {
          final errorMsg =
              'No valid files to upload. ${invalidFiles.map((f) => '${f['file']}: ${f['reason']}').join(', ')}';
          debugPrint('❌ Upload validation failed: $errorMsg');
          emit(state.copyWith(
            status: FileTransferStatus.error,
            errorMessage: errorMsg,
          ));
          return;
        }

        if (invalidFiles.isNotEmpty) {
          debugPrint('⚠️ Some files will be skipped: ${invalidFiles.length}');
        }

        filesToUpload = validFiles;
      }

      debugPrint('📤 Uploading ${filesToUpload.length} files...');
      final response = await _repository!.uploadFiles(
        files: filesToUpload,
        targetDirectory: state.selectedDirectory?.path,
        onProgress: (sent, total) {
          final progress = sent / total;
          emit(state.copyWith(uploadProgress: progress));
          debugPrint('📊 Upload progress: ${(progress * 100).toInt()}%');
        },
      );

      if (response.status == 'success' || response.status == 'partial') {
        final successMsg = _buildSuccessMessage(response);
        debugPrint('✅ Upload completed: $successMsg');

        emit(state.copyWith(
          status: FileTransferStatus.success,
          uploadProgress: 1.0,
          successMessage: successMsg,
          lastUploadedFiles: response.uploadedFiles ?? [],
          lastSkippedFiles: response.skippedFiles ?? [],
          selectedFiles: [], // Clear selected files after successful upload
        ));

        // Refresh disk space
        if (state.selectedDirectory != null) {
          loadDiskSpace(state.selectedDirectory!.path);
        }
      } else {
        final errorMsg = response.error ?? 'Upload failed';
        debugPrint('❌ Upload failed: $errorMsg');
        emit(state.copyWith(
          status: FileTransferStatus.error,
          errorMessage: errorMsg,
        ));
      }
    } catch (e) {
      final errorMsg = _handleError(e, 'uploading files');
      debugPrint('❌ Error during upload: $errorMsg');
      emit(state.copyWith(
        status: FileTransferStatus.error,
        uploadProgress: 0.0,
        errorMessage: errorMsg,
      ));
    }
  }

  String _buildSuccessMessage(FileTransferResponse response) {
    final uploaded = response.totalUploaded ?? 0;
    final skipped = response.totalSkipped ?? 0;

    if (uploaded > 0 && skipped == 0) {
      return 'Successfully uploaded $uploaded file${uploaded == 1 ? '' : 's'}';
    } else if (uploaded > 0 && skipped > 0) {
      return 'Uploaded $uploaded file${uploaded == 1 ? '' : 's'}, skipped $skipped';
    } else {
      return 'Upload completed with warnings';
    }
  }

  String _getUploadBlockReason() {
    if (!state.isConnected) return 'Not connected to server';
    if (_repository == null) return 'Repository not initialized';
    if (state.selectedFiles.isEmpty) return 'No files selected';
    if (state.selectedDirectory == null) return 'No directory selected';
    if (state.status == FileTransferStatus.uploading) {
      return 'Upload in progress';
    }
    return 'Unknown reason';
  }

  String _handleError(dynamic error, String operation) {
    debugPrint('🔍 Handling error for $operation: $error');

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Connection timeout while $operation. Please check your network.';

        case DioExceptionType.connectionError:
          return 'Cannot connect to server while $operation. Please check server status and network.';

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          switch (statusCode) {
            case 404:
              return 'File transfer service not found. Make sure the server supports file transfers.';
            case 403:
              return 'Access denied while $operation. Check server permissions.';
            case 413:
              return 'File too large while $operation. Try smaller files.';
            case 500:
              return 'Server error while $operation. Check server logs.';
            default:
              return 'Server error ($statusCode) while $operation.';
          }

        case DioExceptionType.cancel:
          return 'Operation cancelled while $operation.';

        default:
          return 'Network error while $operation: ${error.message}';
      }
    }

    if (error is SocketException) {
      return 'Network connection failed while $operation. Check your connection.';
    }

    return 'Error while $operation: ${error.toString()}';
  }

  // UI state methods
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  void clearSuccess() {
    emit(state.copyWith(successMessage: null));
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }

  void resetUploadProgress() {
    emit(state.copyWith(uploadProgress: 0.0));
  }

  // Test connection method for UI
  Future<bool> testConnection() async {
    if (_repository == null) {
      debugPrint('⚠️ Cannot test connection: repository null');
      return false;
    }

    try {
      debugPrint('🔄 Testing connection...');
      final result = await _repository!.testConnection();
      debugPrint(
          result ? '✅ Connection test successful' : '❌ Connection test failed');
      return result;
    } catch (e) {
      debugPrint('❌ Connection test error: $e');
      return false;
    }
  }

  Future<void> debugConnection() async {
    debugPrint('=== DEBUG CONNECTION ===');
    debugPrint('Base URL: ${_repository?.baseUrl}');
    debugPrint('Connection State: ${state.isConnected}');

    try {
      final response = await http.get(
        Uri.parse(
            '${_connectionCubit.state.serverIP}:${_connectionCubit.state.serverPort}/file-transfer/status'),
      );
      debugPrint('Direct HTTP Status: ${response.statusCode}');
      debugPrint('Direct HTTP Body: ${response.body}');
    } catch (e) {
      debugPrint('Direct HTTP Error: $e');
    }
  }

  Future<void> debugReleaseMode() async {
    debugPrint('=== RELEASE MODE DEBUG ===');
    debugPrint('Connection State: ${state.isConnected}');
    debugPrint('Repository: ${_repository != null ? 'Initialized' : 'Null'}');
    debugPrint(
        'Base URL: ${_connectionCubit.state.serverIP}:${_connectionCubit.state.serverPort}');
    debugPrint('Available Directories: ${state.availableDirectories.length}');
    debugPrint('Selected Directory: ${state.selectedDirectory?.name ?? 'None'}');
    debugPrint('Transfer Status: ${state.transferStatus?.status ?? 'None'}');

    // Test direct connection
    try {
      final response = await http.get(
        Uri.parse(
            'http://${_connectionCubit.state.serverIP}:${_connectionCubit.state.serverPort}/file-transfer/status'),
        headers: {'Accept': 'application/json'},
      );
      debugPrint('Direct HTTP Response: ${response.statusCode}');
      debugPrint('Direct HTTP Body: ${response.body}');
    } catch (e) {
      debugPrint('Direct HTTP Error: $e');
    }
  }
}
