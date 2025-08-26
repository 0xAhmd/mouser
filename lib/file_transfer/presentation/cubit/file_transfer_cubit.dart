import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
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
    _repository = FileTransferRepository(
      baseUrl: 'http://$serverIP:$serverPort',
    );
  }

  void _listenToConnectionChanges() {
    _connectionCubit.stream.listen((connectionState) {
      emit(state.copyWith(isConnected: connectionState.isConnected));
      if (connectionState.isConnected) {
        _initializeRepository();
        loadTransferStatus();
        loadAvailableDirectories();
      }
    });
  }

  // File selection methods
  void addFiles(List<File> files) {
    final updatedFiles = List<File>.from(state.selectedFiles)..addAll(files);
    emit(state.copyWith(selectedFiles: updatedFiles));
    debugPrint('Added ${files.length} files. Total: ${updatedFiles.length}');
  }

  void removeFile(File file) {
    final updatedFiles = List<File>.from(state.selectedFiles)..remove(file);
    emit(state.copyWith(selectedFiles: updatedFiles));
    debugPrint('Removed file. Remaining: ${updatedFiles.length}');
  }

  void clearFiles() {
    emit(state.copyWith(selectedFiles: []));
    debugPrint('Cleared all selected files');
  }

  void replaceFiles(List<File> files) {
    emit(state.copyWith(selectedFiles: files));
    debugPrint('Replaced files. New count: ${files.length}');
  }

  // Directory methods
  Future<void> loadAvailableDirectories() async {
    if (!state.isConnected) return;

    emit(state.copyWith(directoryStatus: DirectoryStatus.loading));
    
    try {
      _initializeRepository();
      final response = await _repository!.getAvailableDirectories();
      
      if (response.status == 'success') {
        emit(state.copyWith(
          directoryStatus: DirectoryStatus.loaded,
          availableDirectories: response.directories,
          errorMessage: null,
        ));

        // Auto-select default directory if available
        final defaultDir = response.directories.firstWhere(
          (dir) => dir.name.contains('Phone Transfer') || dir.name.contains('Downloads'),
          orElse: () => response.directories.isNotEmpty ? response.directories.first : const DirectoryInfo(name: '', path: '', exists: false, writable: false),
        );

        if (defaultDir.name.isNotEmpty) {
          selectDirectory(defaultDir);
        }
      } else {
        emit(state.copyWith(
          directoryStatus: DirectoryStatus.error,
          errorMessage: response.error ?? 'Failed to load directories',
        ));
      }
    } catch (e) {
      debugPrint('Error loading directories: $e');
      emit(state.copyWith(
        directoryStatus: DirectoryStatus.error,
        errorMessage: 'Failed to load directories: $e',
      ));
    }
  }

  void selectDirectory(DirectoryInfo directory) {
    emit(state.copyWith(selectedDirectory: directory));
    loadDiskSpace(directory.path);
    debugPrint('Selected directory: ${directory.name} (${directory.path})');
  }

  Future<void> createDirectory(String path) async {
    if (!state.isConnected) return;

    emit(state.copyWith(status: FileTransferStatus.loading));

    try {
      _initializeRepository();
      final response = await _repository!.createDirectory(path);
      
      if (response.status == 'success') {
        emit(state.copyWith(
          status: FileTransferStatus.success,
          successMessage: 'Directory created successfully',
        ));
        // Reload directories to include the new one
        await loadAvailableDirectories();
      } else {
        emit(state.copyWith(
          status: FileTransferStatus.error,
          errorMessage: response.error ?? 'Failed to create directory',
        ));
      }
    } catch (e) {
      debugPrint('Error creating directory: $e');
      emit(state.copyWith(
        status: FileTransferStatus.error,
        errorMessage: 'Failed to create directory: $e',
      ));
    }
  }

  // Transfer status methods
  Future<void> loadTransferStatus() async {
    if (!state.isConnected) return;

    try {
      _initializeRepository();
      final response = await _repository!.getTransferStatus();
      emit(state.copyWith(transferStatus: response));
      debugPrint('Transfer status loaded: ${response.version}');
    } catch (e) {
      debugPrint('Error loading transfer status: $e');
    }
  }

  // Disk space methods
  Future<void> loadDiskSpace(String? directory) async {
    if (!state.isConnected) return;

    try {
      _initializeRepository();
      final response = await _repository!.getDiskSpace(directory);
      emit(state.copyWith(diskSpaceInfo: response));
      debugPrint('Disk space loaded: ${response.freeGb} GB free');
    } catch (e) {
      debugPrint('Error loading disk space: $e');
    }
  }

  // Upload methods
  Future<void> uploadFiles() async {
    if (!state.canUpload) {
      debugPrint('Cannot upload: ${_getUploadBlockReason()}');
      return;
    }

    emit(state.copyWith(
      status: FileTransferStatus.uploading,
      uploadProgress: 0.0,
      errorMessage: null,
      successMessage: null,
    ));

    try {
      _initializeRepository();

      // Validate files if transfer status is available
      if (state.transferStatus != null) {
        final validation = await _repository!.validateFiles(
          state.selectedFiles,
          state.transferStatus!.allowedExtensions,
          100 * 1024 * 1024, // 100MB max
        );

        final validFiles = validation['validFiles'] as List<File>;
        final invalidFiles = validation['invalidFiles'] as List<Map<String, String>>;

        if (validFiles.isEmpty) {
          emit(state.copyWith(
            status: FileTransferStatus.error,
            errorMessage: 'No valid files to upload. ${invalidFiles.map((f) => '${f['file']}: ${f['reason']}').join(', ')}',
          ));
          return;
        }

        if (invalidFiles.isNotEmpty) {
          debugPrint('Some files will be skipped: ${invalidFiles.length}');
        }

        // Use only valid files for upload
        final response = await _repository!.uploadFiles(
          files: validFiles,
          targetDirectory: state.selectedDirectory?.path,
          onProgress: (sent, total) {
            final progress = sent / total;
            emit(state.copyWith(uploadProgress: progress));
          },
        );

        if (response.status == 'success' || response.status == 'partial') {
          emit(state.copyWith(
            status: FileTransferStatus.success,
            uploadProgress: 1.0,
            successMessage: _buildSuccessMessage(response),
            lastUploadedFiles: response.uploadedFiles ?? [],
            lastSkippedFiles: response.skippedFiles ?? [],
            selectedFiles: [], // Clear selected files after successful upload
          ));

          // Refresh disk space
          if (state.selectedDirectory != null) {
            loadDiskSpace(state.selectedDirectory!.path);
          }
        } else {
          emit(state.copyWith(
            status: FileTransferStatus.error,
            errorMessage: response.error ?? 'Upload failed',
          ));
        }
      } else {
        // Fallback if no transfer status available
        final response = await _repository!.uploadFiles(
          files: state.selectedFiles,
          targetDirectory: state.selectedDirectory?.path,
          onProgress: (sent, total) {
            final progress = sent / total;
            emit(state.copyWith(uploadProgress: progress));
          },
        );

        if (response.status == 'success') {
          emit(state.copyWith(
            status: FileTransferStatus.success,
            uploadProgress: 1.0,
            successMessage: _buildSuccessMessage(response),
            lastUploadedFiles: response.uploadedFiles ?? [],
            selectedFiles: [],
          ));
        } else {
          emit(state.copyWith(
            status: FileTransferStatus.error,
            errorMessage: response.error ?? 'Upload failed',
          ));
        }
      }
    } catch (e) {
      debugPrint('Error during upload: $e');
      emit(state.copyWith(
        status: FileTransferStatus.error,
        uploadProgress: 0.0,
        errorMessage: 'Upload failed: $e',
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
    if (state.selectedFiles.isEmpty) return 'No files selected';
    if (state.selectedDirectory == null) return 'No directory selected';
    if (state.status == FileTransferStatus.uploading) return 'Upload in progress';
    return 'Unknown reason';
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
}