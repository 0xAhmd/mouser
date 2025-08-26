// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_transfer_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileTransferResponse _$FileTransferResponseFromJson(
        Map<String, dynamic> json) =>
    FileTransferResponse(
      status: json['status'] as String,
      message: json['message'] as String?,
      error: json['error'] as String?,
      uploadedFiles: (json['uploadedFiles'] as List<dynamic>?)
          ?.map((e) => UploadedFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      skippedFiles: (json['skippedFiles'] as List<dynamic>?)
          ?.map((e) => SkippedFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      targetDirectory: json['targetDirectory'] as String?,
      totalUploaded: (json['totalUploaded'] as num?)?.toInt(),
      totalSkipped: (json['totalSkipped'] as num?)?.toInt(),
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$FileTransferResponseToJson(
        FileTransferResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'error': instance.error,
      'uploadedFiles': instance.uploadedFiles,
      'skippedFiles': instance.skippedFiles,
      'targetDirectory': instance.targetDirectory,
      'totalUploaded': instance.totalUploaded,
      'totalSkipped': instance.totalSkipped,
      'errors': instance.errors,
    };

UploadedFile _$UploadedFileFromJson(Map<String, dynamic> json) => UploadedFile(
      originalName: json['originalName'] as String,
      savedName: json['savedName'] as String,
      path: json['path'] as String,
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$UploadedFileToJson(UploadedFile instance) =>
    <String, dynamic>{
      'originalName': instance.originalName,
      'savedName': instance.savedName,
      'path': instance.path,
      'size': instance.size,
    };

SkippedFile _$SkippedFileFromJson(Map<String, dynamic> json) => SkippedFile(
      filename: json['filename'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$SkippedFileToJson(SkippedFile instance) =>
    <String, dynamic>{
      'filename': instance.filename,
      'reason': instance.reason,
    };
