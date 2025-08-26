import 'package:equatable/equatable.dart';
import 'package:mouser/file_transfer/data/models/directory_info.dart';
import 'package:mouser/file_transfer/data/models/disk_space_info.dart';
import 'dart:io';
import 'package:mouser/file_transfer/data/models/file_transfer_response.dart';
import 'package:mouser/file_transfer/data/models/transfer_status.dart';

enum FileTransferStatus {
  initial,
  loading,
  uploading,
  success,
  error,
}

enum DirectoryStatus {
  initial,
  loading,
  loaded,
  error,
}

class FileTransferState extends Equatable {
  final FileTransferStatus status;
  final DirectoryStatus directoryStatus;
  final List<File> selectedFiles;
  final List<DirectoryInfo> availableDirectories;
  final DirectoryInfo? selectedDirectory;
  final double uploadProgress;
  final String? errorMessage;
  final String? successMessage;
  final TransferStatus? transferStatus;
  final DiskSpaceInfo? diskSpaceInfo;
  final List<UploadedFile> lastUploadedFiles;
  final List<SkippedFile> lastSkippedFiles;
  final bool isConnected;

  const FileTransferState({
    this.status = FileTransferStatus.initial,
    this.directoryStatus = DirectoryStatus.initial,
    this.selectedFiles = const [],
    this.availableDirectories = const [],
    this.selectedDirectory,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.successMessage,
    this.transferStatus,
    this.diskSpaceInfo,
    this.lastUploadedFiles = const [],
    this.lastSkippedFiles = const [],
    this.isConnected = false,
  });

  FileTransferState copyWith({
    FileTransferStatus? status,
    DirectoryStatus? directoryStatus,
    List<File>? selectedFiles,
    List<DirectoryInfo>? availableDirectories,
    DirectoryInfo? selectedDirectory,
    double? uploadProgress,
    String? errorMessage,
    String? successMessage,
    TransferStatus? transferStatus,
    DiskSpaceInfo? diskSpaceInfo,
    List<UploadedFile>? lastUploadedFiles,
    List<SkippedFile>? lastSkippedFiles,
    bool? isConnected,
  }) {
    return FileTransferState(
      status: status ?? this.status,
      directoryStatus: directoryStatus ?? this.directoryStatus,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      availableDirectories: availableDirectories ?? this.availableDirectories,
      selectedDirectory: selectedDirectory ?? this.selectedDirectory,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage,
      successMessage: successMessage,
      transferStatus: transferStatus ?? this.transferStatus,
      diskSpaceInfo: diskSpaceInfo ?? this.diskSpaceInfo,
      lastUploadedFiles: lastUploadedFiles ?? this.lastUploadedFiles,
      lastSkippedFiles: lastSkippedFiles ?? this.lastSkippedFiles,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  bool get canUpload => 
      isConnected && 
      selectedFiles.isNotEmpty && 
      selectedDirectory != null && 
      status != FileTransferStatus.uploading;

  bool get hasFiles => selectedFiles.isNotEmpty;

  bool get isLoading => 
      status == FileTransferStatus.loading || 
      directoryStatus == DirectoryStatus.loading;

  bool get isUploading => status == FileTransferStatus.uploading;

  String get selectedFilesInfo {
    if (selectedFiles.isEmpty) return 'No files selected';
    
    final totalSize = selectedFiles.fold<int>(
      0, 
      (sum, file) {
        try {
          return sum + file.lengthSync();
        } catch (e) {
          return sum;
        }
      },
    );
    
    return '${selectedFiles.length} file${selectedFiles.length == 1 ? '' : 's'} (${_formatFileSize(totalSize)})';
  }

  String get selectedDirectoryInfo {
    if (selectedDirectory == null) return 'No directory selected';
    return selectedDirectory!.name;
  }

  String get diskSpaceInfoText {
    if (diskSpaceInfo == null) return 'Disk space: Unknown';
    return 'Free: ${diskSpaceInfo!.freeGb.toStringAsFixed(1)} GB / ${diskSpaceInfo!.totalGb.toStringAsFixed(1)} GB';
  }

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

  @override
  List<Object?> get props => [
        status,
        directoryStatus,
        selectedFiles,
        availableDirectories,
        selectedDirectory,
        uploadProgress,
        errorMessage,
        successMessage,
        transferStatus,
        diskSpaceInfo,
        lastUploadedFiles,
        lastSkippedFiles,
        isConnected,
      ];
}