import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mouser/file_transfer/data/models/pc_file_info.dart';
import 'package:mouser/file_transfer/data/repo/pc_transfer_info_repo.dart';
import 'package:mouser/file_transfer/presentation/cubit/pc_transfer_state.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';

class PCTransferCubit extends Cubit<PCTransferState> {
  final ConnectionCubit _connectionCubit;
  PCTransferRepository? _repository;

  PCTransferCubit({required ConnectionCubit connectionCubit})
      : _connectionCubit = connectionCubit,
        super(const PCTransferState()) {
    _initializeRepository();
    _listenToConnectionChanges();
  }

  void _initializeRepository() {
    final serverIP = _connectionCubit.state.serverIP;
    final serverPort = _connectionCubit.state.serverPort;
    final baseUrl = 'http://$serverIP:$serverPort';

    debugPrint('🔧 Initializing PCTransferRepository with baseUrl: $baseUrl');
    _repository = PCTransferRepository(baseUrl: baseUrl);
  }

  void _listenToConnectionChanges() {
    _connectionCubit.stream.listen((connectionState) {
      if (connectionState.isConnected) {
        _initializeRepository();
        loadQuickAccessFolders();
      } else {
        emit(const PCTransferState());
      }
    });
  }

  Future<void> browsePath(String? path) async {
    if (_repository == null) return;

    emit(state.copyWith(status: PCTransferStatus.browsing));

    try {
      debugPrint('🔍 Browsing path: ${path ?? 'default'}');
      final response = await _repository!.browsePath(path);

      if (response.status == 'success') {
        emit(state.copyWith(
          status: PCTransferStatus.initial,
          currentPath: response.currentPath,
          parentPath: response.parentPath,
          directories: response.directories,
          files: response.files,
          selectedFiles: [], // Clear selection when navigating
          errorMessage: null,
        ));
        debugPrint(
            '✅ Browse completed: ${response.files.length} files, ${response.directories.length} dirs');
        
        // Debug: Print file details
        for (final file in response.files) {
          debugPrint('📄 File: ${file.name}, downloadable: ${file.canDownload}, size: ${file.size}');
        }
      } else {
        emit(state.copyWith(
          status: PCTransferStatus.error,
          errorMessage: response.error ?? 'Failed to browse path',
        ));
      }
    } catch (e) {
      debugPrint('❌ Error browsing path: $e');
      emit(state.copyWith(
        status: PCTransferStatus.error,
        errorMessage: 'Error browsing path: $e',
      ));
    }
  }

  Future<void> loadQuickAccessFolders() async {
    if (_repository == null) return;

    try {
      debugPrint('📂 Loading quick access folders');
      final response = await _repository!.getQuickAccessFolders();

      if (response.status == 'success') {
        emit(state.copyWith(quickAccessFolders: response.folders));
        debugPrint('✅ Loaded ${response.folders.length} quick access folders');
      }
    } catch (e) {
      debugPrint('❌ Error loading quick access folders: $e');
    }
  }

  void selectFile(PCFileInfo file) {
    if (!file.isFile) return;

    final updatedSelection = List<PCFileInfo>.from(state.selectedFiles);

    if (updatedSelection.contains(file)) {
      updatedSelection.remove(file);
      debugPrint('➖ Deselected file: ${file.name}');
    } else {
      updatedSelection.add(file);
      debugPrint('➕ Selected file: ${file.name}, downloadable: ${file.canDownload}');
    }

    emit(state.copyWith(selectedFiles: updatedSelection));
    
    // Debug: Print selection summary
    final downloadableCount = updatedSelection.where((f) => f.canDownload).length;
    debugPrint('📊 Selection: ${updatedSelection.length} total, $downloadableCount downloadable');
  }

  void selectMultipleFiles(List<PCFileInfo> files) {
    final validFiles = files.where((f) => f.isFile).toList();
    emit(state.copyWith(selectedFiles: validFiles));
    debugPrint('📁 Selected ${validFiles.length} files');
    
    // Debug: Print selection details
    final downloadableCount = validFiles.where((f) => f.canDownload).length;
    debugPrint('📊 Multi-select: ${validFiles.length} total, $downloadableCount downloadable');
  }

  void clearSelection() {
    emit(state.copyWith(selectedFiles: []));
    debugPrint('🧹 Cleared file selection');
  }

  void selectAllDownloadableFiles() {
    final downloadableFiles = state.files.where((f) => f.canDownload).toList();
    emit(state.copyWith(selectedFiles: downloadableFiles));
    debugPrint('📁 Selected all ${downloadableFiles.length} downloadable files');
  }

  Future<void> downloadSelectedFiles() async {
    if (!state.canDownload || _repository == null) {
      debugPrint('❌ Cannot download: canDownload=${state.canDownload}, repository=${_repository != null}');
      return;
    }

    final downloadableFiles = state.selectedFiles.where((f) => f.canDownload).toList();
    debugPrint('🚀 Starting download process for ${downloadableFiles.length} downloadable files');
    
    if (downloadableFiles.isEmpty) {
      final nonDownloadableReasons = state.selectedFiles.map((f) => '${f.name}: ${f.skipReason ?? 'not downloadable'}').join(', ');
      debugPrint('❌ No downloadable files. Reasons: $nonDownloadableReasons');
      emit(state.copyWith(
        status: PCTransferStatus.error,
        errorMessage: 'No downloadable files selected. Reasons: $nonDownloadableReasons',
      ));
      return;
    }

    emit(state.copyWith(
      status: PCTransferStatus.downloading,
      downloadProgress: 0.0,
      currentDownloadIndex: 0,
      totalDownloads: downloadableFiles.length,
      downloadResults: [],
      errorMessage: null,
    ));

    try {
      // First, prepare downloads
      debugPrint('📋 Preparing download for ${downloadableFiles.length} files');
      final filePaths = downloadableFiles.map((f) => f.path).toList();
      debugPrint('📂 File paths: $filePaths');
      
      final downloadResponse = await _repository!.prepareDownload(filePaths);
      debugPrint('📥 Download prepare response: ${downloadResponse.status}');
      debugPrint('📊 Summary - Total: ${downloadResponse.summary.totalRequested}, Ready: ${downloadResponse.summary.readyForDownload}, Errors: ${downloadResponse.summary.errors}');

      // Debug: Print each download info
      for (int i = 0; i < downloadResponse.downloads.length; i++) {
        final download = downloadResponse.downloads[i];
        debugPrint('📄 Download $i: ${download.name}, status: ${download.status}, canDownload: ${download.canDownload}, url: ${download.downloadUrl != null ? 'present' : 'missing'}');
        if (download.error != null) {
          debugPrint('❌ Download $i error: ${download.error}');
        }
      }

      if (downloadResponse.status != 'success' && downloadResponse.status != 'partial') {
        debugPrint('❌ Download preparation failed: ${downloadResponse.error}');
        emit(state.copyWith(
          status: PCTransferStatus.error,
          errorMessage: downloadResponse.error ?? 'Failed to prepare downloads',
        ));
        return;
      }

      final readyDownloads = downloadResponse.downloads.where((d) => d.canDownload).toList();
      debugPrint('✅ ${readyDownloads.length} files ready for download');

      if (readyDownloads.isEmpty) {
        final errorDetails = downloadResponse.downloads.map((d) => '${d.name}: ${d.error ?? 'not ready'}').join(', ');
        debugPrint('❌ No files ready for download. Details: $errorDetails');
        emit(state.copyWith(
          status: PCTransferStatus.error,
          errorMessage: 'No files are ready for download. Details: $errorDetails',
        ));
        return;
      }

      // Start downloading
      debugPrint('📥 Starting download of ${readyDownloads.length} files');

      final results = await _repository!.downloadMultipleFiles(
        readyDownloads,
        onOverallProgress: (current, total) {
          debugPrint('📊 Overall progress: $current/$total');
          emit(state.copyWith(
            currentDownloadIndex: current,
            totalDownloads: total,
            downloadProgress: current / total,
          ));
        },
        onFileProgress: (received, total, fileName) {
          if (total > 0) {
            final fileProgress = received / total;
            final overallProgress = (state.currentDownloadIndex + fileProgress) / state.totalDownloads;
            debugPrint('📄 File progress: $fileName ${(fileProgress * 100).toInt()}%');
            emit(state.copyWith(
              downloadProgress: overallProgress,
              currentDownloadFile: fileName,
            ));
          }
        },
      );

      final successfulDownloads = results.where((r) => r.success).length;
      final failedDownloads = results.where((r) => !r.success).length;

      debugPrint('✅ Download completed: $successfulDownloads successful, $failedDownloads failed');
      
      // Debug: Print each result
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        if (result.success) {
          debugPrint('✅ Download $i success: ${result.fileName} (${result.formattedSize})');
        } else {
          debugPrint('❌ Download $i failed: ${result.error}');
        }
      }

      emit(state.copyWith(
        status: PCTransferStatus.success,
        downloadProgress: 1.0,
        downloadResults: results,
        currentDownloadFile: null,
        successMessage: 'Download completed: $successfulDownloads successful, $failedDownloads failed',
      ));
    } catch (e) {
      debugPrint('❌ Error downloading files: $e');
      emit(state.copyWith(
        status: PCTransferStatus.error,
        errorMessage: 'Download failed: $e',
      ));
    }
  }

  void goToParent() {
    if (state.hasParent) {
      debugPrint('⬆️ Navigating to parent: ${state.parentPath}');
      browsePath(state.parentPath);
    }
  }

  void goToPath(String path) {
    debugPrint('📂 Navigating to path: $path');
    browsePath(path);
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  void clearSuccess() {
    emit(state.copyWith(successMessage: null));
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }

  // Debug method to check file selection
  void debugSelection() {
    debugPrint('=== DEBUG SELECTION ===');
    debugPrint('Selected files count: ${state.selectedFiles.length}');
    debugPrint('Can download: ${state.canDownload}');
    
    for (int i = 0; i < state.selectedFiles.length; i++) {
      final file = state.selectedFiles[i];
      debugPrint('File $i: ${file.name}');
      debugPrint('  - Type: ${file.type}');
      debugPrint('  - Downloadable: ${file.downloadable}');
      debugPrint('  - Can download: ${file.canDownload}');
      debugPrint('  - Skip reason: ${file.skipReason}');
      debugPrint('  - Size: ${file.size}');
      debugPrint('  - MIME: ${file.mimeType}');
    }
    
    final downloadableCount = state.selectedFiles.where((f) => f.canDownload).length;
    debugPrint('Downloadable files: $downloadableCount/${state.selectedFiles.length}');
  }
}