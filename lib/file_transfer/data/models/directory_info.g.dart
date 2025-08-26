// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DirectoryInfo _$DirectoryInfoFromJson(Map<String, dynamic> json) =>
    DirectoryInfo(
      name: json['name'] as String,
      path: json['path'] as String,
      exists: json['exists'] as bool,
      writable: json['writable'] as bool,
    );

Map<String, dynamic> _$DirectoryInfoToJson(DirectoryInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'exists': instance.exists,
      'writable': instance.writable,
    };

DirectoriesResponse _$DirectoriesResponseFromJson(Map<String, dynamic> json) =>
    DirectoriesResponse(
      status: json['status'] as String,
      directories: (json['directories'] as List<dynamic>)
          .map((e) => DirectoryInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      homeDirectory: json['homeDirectory'] as String,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$DirectoriesResponseToJson(
        DirectoriesResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'directories': instance.directories,
      'homeDirectory': instance.homeDirectory,
      'error': instance.error,
    };
