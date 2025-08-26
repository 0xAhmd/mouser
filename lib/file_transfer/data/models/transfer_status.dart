import 'package:json_annotation/json_annotation.dart';

part 'transfer_status.g.dart';

@JsonSerializable()
class TransferStatus {
  final String status;
  final String version;
  final List<String> features;
  final List<String> allowedExtensions;
  final String defaultDirectory;
  final String maxFileSize;
  final List<String> supportedOperations;
  final String? error;

  const TransferStatus({
    required this.status,
    required this.version,
    required this.features,
    required this.allowedExtensions,
    required this.defaultDirectory,
    required this.maxFileSize,
    required this.supportedOperations,
    this.error,
  });

  factory TransferStatus.fromJson(Map<String, dynamic> json) =>
      _$TransferStatusFromJson(json);

  Map<String, dynamic> toJson() => _$TransferStatusToJson(this);
}
