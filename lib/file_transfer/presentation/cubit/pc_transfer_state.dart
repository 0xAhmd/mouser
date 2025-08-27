import 'package:equatable/equatable.dart';
import 'package:mouser/file_transfer/data/models/pc_file_info.dart';
import 'package:mouser/file_transfer/data/repo/pc_transfer_info_repo.dart';

enum PCTransferStatus {
  initial,
  browsing,
  downloading,
  success,
  error,
}

class PCTransferState extends Equatable {
  final PCTransferStatus status;
  final String? currentPath;
  final String? parentPath;
  final List<PCFileInfo> directories;
  final List<PCFileInfo> files;
  final List<PCFileInfo> selectedFiles;
  final List<QuickAccessFolder> quickAccessFolders;
  final String? errorMessage;
  final String? successMessage;
  
  // Download progress
  final double downloadProgress;
  final int currentDownloadIndex;
  final int totalDownloads;
  final String? currentDownloadFile;
  final List<DownloadResult> downloadResults;

  const PCTransferState({
    this.status = PCTransferStatus.initial,
    this.currentPath,
    this.parentPath,
    this.directories = const [],
    this.files = const [],
    this.selectedFiles = const [],
    this.quickAccessFolders = const [],
    this.errorMessage,
    this.successMessage,
    this.downloadProgress = 0.0,
    this.currentDownloadIndex = 0,
    this.totalDownloads = 0,
    this.currentDownloadFile,
    this.downloadResults = const [],
  });

  PCTransferState copyWith({
    PCTransferStatus? status,
    String? currentPath,
    String? parentPath,
    List<PCFileInfo>? directories,
    List<PCFileInfo>? files,
    List<PCFileInfo>? selectedFiles,
    List<QuickAccessFolder>? quickAccessFolders,
    String? errorMessage,
    String? successMessage,
    double? downloadProgress,
    int? currentDownloadIndex,
    int? totalDownloads,
    String? currentDownloadFile,
    List<DownloadResult>? downloadResults,
  }) {
    return PCTransferState(
      status: status ?? this.status,
      currentPath: currentPath ?? this.currentPath,
      parentPath: parentPath ?? this.parentPath,
      directories: directories ?? this.directories,
      files: files ?? this.files,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      quickAccessFolders: quickAccessFolders ?? this.quickAccessFolders,
      errorMessage: errorMessage,
      successMessage: successMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      currentDownloadIndex: currentDownloadIndex ?? this.currentDownloadIndex,
      totalDownloads: totalDownloads ?? this.totalDownloads,
      currentDownloadFile: currentDownloadFile ?? this.currentDownloadFile,
      downloadResults: downloadResults ?? this.downloadResults,
    );
  }

  bool get canDownload => 
      selectedFiles.isNotEmpty && 
      selectedFiles.any((file) => file.canDownload) &&
      status != PCTransferStatus.downloading;

  bool get isLoading => 
      status == PCTransferStatus.browsing || 
      status == PCTransferStatus.downloading;

  bool get hasParent => parentPath != null && parentPath != currentPath;

  String get selectedFilesInfo {
    if (selectedFiles.isEmpty) return 'No files selected';
    
    final downloadable = selectedFiles.where((f) => f.canDownload).length;
    final totalSize = selectedFiles
        .where((f) => f.size != null)
        .fold<int>(0, (sum, file) => sum + file.size!);
    
    return '$downloadable of ${selectedFiles.length} files (${_formatFileSize(totalSize)})';
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
        currentPath,
        parentPath,
        directories,
        files,
        selectedFiles,
        quickAccessFolders,
        errorMessage,
        successMessage,
        downloadProgress,
        currentDownloadIndex,
        totalDownloads,
        currentDownloadFile,
        downloadResults,
      ];
}

