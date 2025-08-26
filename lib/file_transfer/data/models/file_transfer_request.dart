import 'package:json_annotation/json_annotation.dart';

part 'file_transfer_request.g.dart';

@JsonSerializable()
class FileTransferRequest {
  final String action;
  final FileTransferData? data;

  const FileTransferRequest({
    required this.action,
    this.data,
  });

  factory FileTransferRequest.fromJson(Map<String, dynamic> json) =>
      _$FileTransferRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FileTransferRequestToJson(this);
}

@JsonSerializable()
class FileTransferData {
  final String? targetDirectory;
  final String? path;

  const FileTransferData({
    this.targetDirectory,
    this.path,
  });

  factory FileTransferData.fromJson(Map<String, dynamic> json) =>
      _$FileTransferDataFromJson(json);

  Map<String, dynamic> toJson() => _$FileTransferDataToJson(this);
}