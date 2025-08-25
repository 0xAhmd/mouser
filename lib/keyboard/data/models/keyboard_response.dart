import 'package:json_annotation/json_annotation.dart';

part 'keyboard_response.g.dart';

@JsonSerializable()
class KeyboardResponse {
  final String status;
  final String? message;
  final String? error;

  const KeyboardResponse({
    required this.status,
    this.message,
    this.error,
  });

  factory KeyboardResponse.fromJson(Map<String, dynamic> json) =>
      _$KeyboardResponseFromJson(json);

  Map<String, dynamic> toJson() => _$KeyboardResponseToJson(this);
}