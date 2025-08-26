import 'package:json_annotation/json_annotation.dart';

part 'disk_space_info.g.dart';

@JsonSerializable()
class DiskSpaceInfo {
  final String status;
  final String directory;
  final int totalSpace;
  final int usedSpace;
  final int freeSpace;
  final double totalGb;
  final double usedGb;
  final double freeGb;
  final double usagePercent;
  final String? error;

  const DiskSpaceInfo({
    required this.status,
    required this.directory,
    required this.totalSpace,
    required this.usedSpace,
    required this.freeSpace,
    required this.totalGb,
    required this.usedGb,
    required this.freeGb,
    required this.usagePercent,
    this.error,
  });

  factory DiskSpaceInfo.fromJson(Map<String, dynamic> json) =>
      _$DiskSpaceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DiskSpaceInfoToJson(this);
}
