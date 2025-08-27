// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pc_file_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PCFileInfo _$PCFileInfoFromJson(Map<String, dynamic> json) => PCFileInfo(
      name: json['name'] as String,
      path: json['path'] as String,
      type: json['type'] as String,
      size: (json['size'] as num?)?.toInt(),
      sizeFormatted: json['sizeFormatted'] as String?,
      sizeMb: (json['sizeMb'] as num?)?.toDouble(),
      extension: json['extension'] as String?,
      downloadable: json['downloadable'] as bool?,
      skipReason: json['skipReason'] as String?,
      modified: json['modified'] as String,
      mimeType: json['mimeType'] as String?,
    );

Map<String, dynamic> _$PCFileInfoToJson(PCFileInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'type': instance.type,
      'size': instance.size,
      'sizeFormatted': instance.sizeFormatted,
      'sizeMb': instance.sizeMb,
      'extension': instance.extension,
      'downloadable': instance.downloadable,
      'skipReason': instance.skipReason,
      'modified': instance.modified,
      'mimeType': instance.mimeType,
    };

PCBrowseResponse _$PCBrowseResponseFromJson(Map<String, dynamic> json) =>
    PCBrowseResponse(
      status: json['status'] as String,
      currentPath: json['currentPath'] as String?,
      parentPath: json['parentPath'] as String?,
      directories: (json['directories'] as List<dynamic>)
          .map((e) => PCFileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      files: (json['files'] as List<dynamic>)
          .map((e) => PCFileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDirectories: (json['totalDirectories'] as num?)?.toInt() ?? 0,
      totalFiles: (json['totalFiles'] as num?)?.toInt() ?? 0,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PCBrowseResponseToJson(PCBrowseResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'currentPath': instance.currentPath,
      'parentPath': instance.parentPath,
      'directories': instance.directories,
      'files': instance.files,
      'totalDirectories': instance.totalDirectories,
      'totalFiles': instance.totalFiles,
      'error': instance.error,
    };

PCFileInfoResponse _$PCFileInfoResponseFromJson(Map<String, dynamic> json) =>
    PCFileInfoResponse(
      status: json['status'] as String,
      files: (json['files'] as List<dynamic>)
          .map((e) => PCFileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: FilesSummary.fromJson(json['summary'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PCFileInfoResponseToJson(PCFileInfoResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'files': instance.files,
      'summary': instance.summary,
      'error': instance.error,
    };

FilesSummary _$FilesSummaryFromJson(Map<String, dynamic> json) => FilesSummary(
      totalFiles: (json['totalFiles'] as num?)?.toInt() ?? 0,
      downloadableFiles: (json['downloadableFiles'] as num?)?.toInt() ?? 0,
      totalSize: (json['totalSize'] as num?)?.toInt() ?? 0,
      totalSizeFormatted: json['totalSizeFormatted'] as String? ?? '0 B',
      maxFileSizeMb: (json['maxFileSizeMb'] as num?)?.toInt() ?? 0,
      allowedExtensions: (json['allowedExtensions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$FilesSummaryToJson(FilesSummary instance) =>
    <String, dynamic>{
      'totalFiles': instance.totalFiles,
      'downloadableFiles': instance.downloadableFiles,
      'totalSize': instance.totalSize,
      'totalSizeFormatted': instance.totalSizeFormatted,
      'maxFileSizeMb': instance.maxFileSizeMb,
      'allowedExtensions': instance.allowedExtensions,
    };

PCDownloadInfo _$PCDownloadInfoFromJson(Map<String, dynamic> json) =>
    PCDownloadInfo(
      path: json['path'] as String,
      name: json['name'] as String?,
      status: json['status'] as String,
      downloadUrl: json['downloadUrl'] as String?,
      size: (json['size'] as num?)?.toInt(),
      sizeFormatted: json['sizeFormatted'] as String?,
      mimeType: json['mimeType'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PCDownloadInfoToJson(PCDownloadInfo instance) =>
    <String, dynamic>{
      'path': instance.path,
      'name': instance.name,
      'status': instance.status,
      'downloadUrl': instance.downloadUrl,
      'size': instance.size,
      'sizeFormatted': instance.sizeFormatted,
      'mimeType': instance.mimeType,
      'error': instance.error,
    };

PCDownloadResponse _$PCDownloadResponseFromJson(Map<String, dynamic> json) =>
    PCDownloadResponse(
      status: json['status'] as String,
      downloads: (json['downloads'] as List<dynamic>)
          .map((e) => PCDownloadInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary:
          DownloadSummary.fromJson(json['summary'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PCDownloadResponseToJson(PCDownloadResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'downloads': instance.downloads,
      'summary': instance.summary,
      'error': instance.error,
    };

DownloadSummary _$DownloadSummaryFromJson(Map<String, dynamic> json) =>
    DownloadSummary(
      totalRequested: (json['totalRequested'] as num?)?.toInt() ?? 0,
      readyForDownload: (json['readyForDownload'] as num?)?.toInt() ?? 0,
      errors: (json['errors'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DownloadSummaryToJson(DownloadSummary instance) =>
    <String, dynamic>{
      'totalRequested': instance.totalRequested,
      'readyForDownload': instance.readyForDownload,
      'errors': instance.errors,
    };

QuickAccessFolder _$QuickAccessFolderFromJson(Map<String, dynamic> json) =>
    QuickAccessFolder(
      name: json['name'] as String,
      path: json['path'] as String,
      fileCount: (json['fileCount'] as num?)?.toInt() ?? 0,
      dirCount: (json['dirCount'] as num?)?.toInt() ?? 0,
      accessible: json['accessible'] as bool? ?? false,
    );

Map<String, dynamic> _$QuickAccessFolderToJson(QuickAccessFolder instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'fileCount': instance.fileCount,
      'dirCount': instance.dirCount,
      'accessible': instance.accessible,
    };

QuickAccessResponse _$QuickAccessResponseFromJson(Map<String, dynamic> json) =>
    QuickAccessResponse(
      status: json['status'] as String,
      folders: (json['folders'] as List<dynamic>)
          .map((e) => QuickAccessFolder.fromJson(e as Map<String, dynamic>))
          .toList(),
      homePath: json['homePath'] as String,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$QuickAccessResponseToJson(
        QuickAccessResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'folders': instance.folders,
      'homePath': instance.homePath,
      'error': instance.error,
    };
