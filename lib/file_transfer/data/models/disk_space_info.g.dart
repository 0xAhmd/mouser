// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disk_space_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiskSpaceInfo _$DiskSpaceInfoFromJson(Map<String, dynamic> json) =>
    DiskSpaceInfo(
      status: json['status'] as String,
      directory: json['directory'] as String,
      totalSpace: (json['totalSpace'] as num).toInt(),
      usedSpace: (json['usedSpace'] as num).toInt(),
      freeSpace: (json['freeSpace'] as num).toInt(),
      totalGb: (json['totalGb'] as num).toDouble(),
      usedGb: (json['usedGb'] as num).toDouble(),
      freeGb: (json['freeGb'] as num).toDouble(),
      usagePercent: (json['usagePercent'] as num).toDouble(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$DiskSpaceInfoToJson(DiskSpaceInfo instance) =>
    <String, dynamic>{
      'status': instance.status,
      'directory': instance.directory,
      'totalSpace': instance.totalSpace,
      'usedSpace': instance.usedSpace,
      'freeSpace': instance.freeSpace,
      'totalGb': instance.totalGb,
      'usedGb': instance.usedGb,
      'freeGb': instance.freeGb,
      'usagePercent': instance.usagePercent,
      'error': instance.error,
    };
