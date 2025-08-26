import 'package:json_annotation/json_annotation.dart';

part 'directory_info.g.dart';

@JsonSerializable()
class DirectoryInfo {
  final String name;
  final String path;
  final bool exists;
  final bool writable;

  const DirectoryInfo({
    required this.name,
    required this.path,
    required this.exists,
    required this.writable,
  });

  factory DirectoryInfo.fromJson(Map<String, dynamic> json) =>
      _$DirectoryInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DirectoryInfoToJson(this);
}

@JsonSerializable()
class DirectoriesResponse {
  final String status;
  final List<DirectoryInfo> directories;
  final String homeDirectory;
  final String? error;

  const DirectoriesResponse({
    required this.status,
    required this.directories,
    required this.homeDirectory,
    this.error,
  });

  factory DirectoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$DirectoriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DirectoriesResponseToJson(this);
}