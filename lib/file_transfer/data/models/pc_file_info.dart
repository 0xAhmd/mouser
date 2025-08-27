import 'package:json_annotation/json_annotation.dart';

part 'pc_file_info.g.dart';

@JsonSerializable()
class PCFileInfo {
  final String name;
  final String path;
  final String type; // 'file' or 'directory'
  final int? size;
  final String? sizeFormatted;
  final double? sizeMb;
  final String? extension;
  final bool? downloadable;
  final String? skipReason;
  final String modified;
  final String? mimeType;

  const PCFileInfo({
    required this.name,
    required this.path,
    required this.type,
    this.size,
    this.sizeFormatted,
    this.sizeMb,
    this.extension,
    this.downloadable,
    this.skipReason,
    required this.modified,
    this.mimeType,
  });

  bool get isDirectory => type == 'directory';
  bool get isFile => type == 'file';
  bool get canDownload => downloadable == true;

  factory PCFileInfo.fromJson(Map<String, dynamic> json) =>
      _$PCFileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PCFileInfoToJson(this);
}

@JsonSerializable()
class PCBrowseResponse {
  final String status;
  final String? currentPath;
  final String? parentPath;
  final List<PCFileInfo> directories;
  final List<PCFileInfo> files;
  final int totalDirectories;
  final int totalFiles;
  final String? error;

  const PCBrowseResponse({
    required this.status,
    this.currentPath,
    this.parentPath,
    required this.directories,
    required this.files,
    required this.totalDirectories,
    required this.totalFiles,
    this.error,
  });

  factory PCBrowseResponse.fromJson(Map<String, dynamic> json) =>
      _$PCBrowseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PCBrowseResponseToJson(this);
}

@JsonSerializable()
class PCFileInfoResponse {
  final String status;
  final List<PCFileInfo> files;
  final FilesSummary summary;
  final String? error;

  const PCFileInfoResponse({
    required this.status,
    required this.files,
    required this.summary,
    this.error,
  });

  factory PCFileInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$PCFileInfoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PCFileInfoResponseToJson(this);
}

@JsonSerializable()
class FilesSummary {
  final int totalFiles;
  final int downloadableFiles;
  final int totalSize;
  final String totalSizeFormatted;
  final int maxFileSizeMb;
  final List<String> allowedExtensions;

  const FilesSummary({
    required this.totalFiles,
    required this.downloadableFiles,
    required this.totalSize,
    required this.totalSizeFormatted,
    required this.maxFileSizeMb,
    required this.allowedExtensions,
  });

  factory FilesSummary.fromJson(Map<String, dynamic> json) =>
      _$FilesSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$FilesSummaryToJson(this);
}

@JsonSerializable()
class PCDownloadInfo {
  final String path;
  final String? name;
  final String status;
  final String? downloadUrl;
  final int? size;
  final String? sizeFormatted;
  final String? mimeType;
  final String? error;

  const PCDownloadInfo({
    required this.path,
    this.name,
    required this.status,
    this.downloadUrl,
    this.size,
    this.sizeFormatted,
    this.mimeType,
    this.error,
  });

  bool get canDownload => status == 'ready' && downloadUrl != null;

  factory PCDownloadInfo.fromJson(Map<String, dynamic> json) =>
      _$PCDownloadInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PCDownloadInfoToJson(this);
}

@JsonSerializable()
class PCDownloadResponse {
  final String status;
  final List<PCDownloadInfo> downloads;
  final DownloadSummary summary;
  final String? error;

  const PCDownloadResponse({
    required this.status,
    required this.downloads,
    required this.summary,
    this.error,
  });

  factory PCDownloadResponse.fromJson(Map<String, dynamic> json) =>
      _$PCDownloadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PCDownloadResponseToJson(this);
}

@JsonSerializable()
class DownloadSummary {
  final int totalRequested;
  final int readyForDownload;
  final int errors;

  const DownloadSummary({
    required this.totalRequested,
    required this.readyForDownload,
    required this.errors,
  });

  factory DownloadSummary.fromJson(Map<String, dynamic> json) =>
      _$DownloadSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$DownloadSummaryToJson(this);
}

@JsonSerializable()
class QuickAccessFolder {
  final String name;
  final String path;
  final int fileCount;
  final int dirCount;
  final bool accessible;

  const QuickAccessFolder({
    required this.name,
    required this.path,
    required this.fileCount,
    required this.dirCount,
    required this.accessible,
  });

  factory QuickAccessFolder.fromJson(Map<String, dynamic> json) =>
      _$QuickAccessFolderFromJson(json);

  Map<String, dynamic> toJson() => _$QuickAccessFolderToJson(this);
}

@JsonSerializable()
class QuickAccessResponse {
  final String status;
  final List<QuickAccessFolder> folders;
  final String homePath;
  final String? error;

  const QuickAccessResponse({
    required this.status,
    required this.folders,
    required this.homePath,
    this.error,
  });

  factory QuickAccessResponse.fromJson(Map<String, dynamic> json) =>
      _$QuickAccessResponseFromJson(json);

  Map<String, dynamic> toJson() => _$QuickAccessResponseToJson(this);
}