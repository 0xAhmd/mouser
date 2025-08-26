// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_transfer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileTransferRequest _$FileTransferRequestFromJson(Map<String, dynamic> json) =>
    FileTransferRequest(
      action: json['action'] as String,
      data: json['data'] == null
          ? null
          : FileTransferData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FileTransferRequestToJson(
        FileTransferRequest instance) =>
    <String, dynamic>{
      'action': instance.action,
      'data': instance.data,
    };

FileTransferData _$FileTransferDataFromJson(Map<String, dynamic> json) =>
    FileTransferData(
      targetDirectory: json['targetDirectory'] as String?,
      path: json['path'] as String?,
    );

Map<String, dynamic> _$FileTransferDataToJson(FileTransferData instance) =>
    <String, dynamic>{
      'targetDirectory': instance.targetDirectory,
      'path': instance.path,
    };
