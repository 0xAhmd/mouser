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
    } else {
      updatedSelection.add(file);
    }

    emit(state.copyWith(selectedFiles: updatedSelection));
    debugPrint(
        '📁 File ${file.canDownload ? 'selected' : 'deselected'}: ${file.name}');
  }

  void selectMultipleFiles(List<PCFileInfo> files) {
    final validFiles = files.where((f) => f.isFile).toList();
    emit(state.copyWith(selectedFiles: validFiles));
    debugPrint('📁 Selected ${validFiles.length} files');
  }

  void clearSelection() {
    emit(state.copyWith(selectedFiles: []));
    debugPrint('🧹 Cleared file selection');
  }

  void selectAllDownloadableFiles() {
    final downloadableFiles = state.files.where((f) => f.canDownload).toList();
    emit(state.copyWith(selectedFiles: downloadableFiles));
    debugPrint(
        '📁 Selected all ${downloadableFiles.length} downloadable files');
  }

  Future<void> downloadSelectedFiles() async {
    if (!state.canDownload || _repository == null) return;

    final downloadableFiles =
        state.selectedFiles.where((f) => f.canDownload).toList();
    if (downloadableFiles.isEmpty) {
      emit(state.copyWith(
        status: PCTransferStatus.error,
        errorMessage: 'No downloadable files selected',
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
      debugPrint('🚀 Preparing download for ${downloadableFiles.length} files');
      final filePaths = downloadableFiles.map((f) => f.path).toList();
      final downloadResponse = await _repository!.prepareDownload(filePaths);

      if (downloadResponse.status != 'success' &&
          downloadResponse.status != 'partial') {
        emit(state.copyWith(
          status: PCTransferStatus.error,
          errorMessage: downloadResponse.error ?? 'Failed to prepare downloads',
        ));
        return;
      }

      final readyDownloads =
          downloadResponse.downloads.where((d) => d.canDownload).toList();

      if (readyDownloads.isEmpty) {
        emit(state.copyWith(
          status: PCTransferStatus.error,
          errorMessage: 'No files are ready for download',
        ));
        return;
      }

      // Start downloading
      debugPrint('📥 Starting download of ${readyDownloads.length} files');

      final results = await _repository!.downloadMultipleFiles(
        readyDownloads,
        onOverallProgress: (current, total) {
          emit(state.copyWith(
            currentDownloadIndex: current,
            totalDownloads: total,
            downloadProgress: current / total,
          ));
        },
        onFileProgress: (received, total, fileName) {
          if (total > 0) {
            final fileProgress = received / total;
            final overallProgress =
                (state.currentDownloadIndex + fileProgress) /
                    state.totalDownloads;
            emit(state.copyWith(
              downloadProgress: overallProgress,
              currentDownloadFile: fileName,
            ));
          }
        },
      );

      final successfulDownloads = results.where((r) => r.success).length;
      final failedDownloads = results.where((r) => !r.success).length;

      emit(state.copyWith(
        status: PCTransferStatus.success,
        downloadProgress: 1.0,
        downloadResults: results,
        currentDownloadFile: null,
        successMessage:
            'Download completed: $successfulDownloads successful, $failedDownloads failed',
      ));

      debugPrint(
          '✅ Download completed: $successfulDownloads successful, $failedDownloads failed');
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
      browsePath(state.parentPath);
    }
  }

  void goToPath(String path) {
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
}
