// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyboard_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyboardRequest _$KeyboardRequestFromJson(Map<String, dynamic> json) =>
    KeyboardRequest(
      action: json['action'] as String,
      data: json['data'] == null
          ? null
          : KeyboardData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$KeyboardRequestToJson(KeyboardRequest instance) =>
    <String, dynamic>{
      'action': instance.action,
      'data': instance.data,
    };

KeyboardData _$KeyboardDataFromJson(Map<String, dynamic> json) => KeyboardData(
      text: json['text'] as String?,
      key: json['key'] as String?,
      shift: json['shift'] as bool?,
      ctrl: json['ctrl'] as bool?,
      alt: json['alt'] as bool?,
    );

Map<String, dynamic> _$KeyboardDataToJson(KeyboardData instance) =>
    <String, dynamic>{
      'text': instance.text,
      'key': instance.key,
      'shift': instance.shift,
      'ctrl': instance.ctrl,
      'alt': instance.alt,
    };
