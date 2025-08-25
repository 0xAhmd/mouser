import 'package:json_annotation/json_annotation.dart';

part 'keyboard_request.g.dart';

@JsonSerializable()
class KeyboardRequest {
  final String action;
  final KeyboardData? data;

  const KeyboardRequest({
    required this.action,
    this.data,
  });

  factory KeyboardRequest.fromJson(Map<String, dynamic> json) =>
      _$KeyboardRequestFromJson(json);

  Map<String, dynamic> toJson() => _$KeyboardRequestToJson(this);
}

@JsonSerializable()
class KeyboardData {
  final String? text;
  final String? key;
  final bool? shift;
  final bool? ctrl;
  final bool? alt;

  const KeyboardData({
    this.text,
    this.key,
    this.shift,
    this.ctrl,
    this.alt,
  });

  factory KeyboardData.fromJson(Map<String, dynamic> json) =>
      _$KeyboardDataFromJson(json);

  Map<String, dynamic> toJson() => _$KeyboardDataToJson(this);
}

