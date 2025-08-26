// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferStatus _$TransferStatusFromJson(Map<String, dynamic> json) =>
    TransferStatus(
      status: json['status'] as String,
      version: json['version'] as String,
      features:
          (json['features'] as List<dynamic>).map((e) => e as String).toList(),
      allowedExtensions: (json['allowedExtensions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      defaultDirectory: json['defaultDirectory'] as String,
      maxFileSize: json['maxFileSize'] as String,
      supportedOperations: (json['supportedOperations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$TransferStatusToJson(TransferStatus instance) =>
    <String, dynamic>{
      'status': instance.status,
      'version': instance.version,
      'features': instance.features,
      'allowedExtensions': instance.allowedExtensions,
      'defaultDirectory': instance.defaultDirectory,
      'maxFileSize': instance.maxFileSize,
      'supportedOperations': instance.supportedOperations,
      'error': instance.error,
    };
