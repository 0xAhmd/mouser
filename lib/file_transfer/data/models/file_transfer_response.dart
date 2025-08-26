import 'package:json_annotation/json_annotation.dart';
part 'file_transfer_response.g.dart';
@JsonSerializable()
class FileTransferResponse {
  final String status;
  final String? message;
  final String? error;
  final List<UploadedFile>? uploadedFiles;
  final List<SkippedFile>? skippedFiles;
  final String? targetDirectory;
  final int? totalUploaded;
  final int? totalSkipped;
  final List<String>? errors;

  const FileTransferResponse({
    required this.status,
    this.message,
    this.error,
    this.uploadedFiles,
    this.skippedFiles,
    this.targetDirectory,
    this.totalUploaded,
    this.totalSkipped,
    this.errors,
  });

  factory FileTransferResponse.fromJson(Map<String, dynamic> json) =>
      _$FileTransferResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FileTransferResponseToJson(this);
}

@JsonSerializable()
class UploadedFile {
  final String originalName;
  final String savedName;
  final String path;
  final int size;

  const UploadedFile({
    required this.originalName,
    required this.savedName,
    required this.path,
    required this.size,
  });

  factory UploadedFile.fromJson(Map<String, dynamic> json) =>
      _$UploadedFileFromJson(json);

  Map<String, dynamic> toJson() => _$UploadedFileToJson(this);
}

@JsonSerializable()
class SkippedFile {
  final String filename;
  final String reason;

  const SkippedFile({
    required this.filename,
    required this.reason,
  });

  factory SkippedFile.fromJson(Map<String, dynamic> json) =>
      _$SkippedFileFromJson(json);

  Map<String, dynamic> toJson() => _$SkippedFileToJson(this);
}
